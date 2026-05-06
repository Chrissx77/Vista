#!/usr/bin/env python3
"""
Seed 700+ punti geolocalizzati europei con immagini reali da Wikidata.
Priorita: Italia.
"""

from __future__ import annotations

import json
import os
import re
import urllib.parse
import urllib.request
from dataclasses import dataclass
from typing import List, Tuple

SPARQL_URL = "https://query.wikidata.org/sparql"
TARGET_TOTAL = 720
TARGET_ITALY = 260

OUT_DIR = "scripts/data"
JSON_OUT = os.path.join(OUT_DIR, "eu_viewpoints_wikidata_seed.json")
SQL_OUT = os.path.join(OUT_DIR, "eu_viewpoints_wikidata_seed.sql")


@dataclass
class SeedPoint:
    name: str
    region: str
    city: str
    latitude: float
    longitude: float
    image_url: str
    description: str
    source: str = "seed_wikidata_eu_v1"

    def key(self) -> str:
        return f"{self.name.lower()}|{round(self.latitude,4)}|{round(self.longitude,4)}"


def http_get_json(url: str) -> dict:
    req = urllib.request.Request(url)
    req.add_header("User-Agent", "VistaSeedBot/1.0 (local-dev)")
    req.add_header("Accept", "application/sparql-results+json")
    with urllib.request.urlopen(req, timeout=180) as resp:
        return json.loads(resp.read().decode("utf-8", errors="replace"))


def parse_wkt_point(wkt: str) -> Tuple[float, float]:
    # Point(long lat)
    m = re.search(r"Point\(([-0-9.]+)\s+([-0-9.]+)\)", wkt)
    if not m:
        raise ValueError(f"WKT invalid: {wkt}")
    lon = float(m.group(1))
    lat = float(m.group(2))
    return lat, lon


COUNTRIES = [
    ("Q38", "Italia"),
    ("Q142", "Francia"),
    ("Q183", "Germania"),
    ("Q29", "Spagna"),
    ("Q55", "Paesi Bassi"),
    ("Q40", "Austria"),
    ("Q39", "Svizzera"),
    ("Q31", "Belgio"),
    ("Q145", "Regno Unito"),
    ("Q213", "Repubblica Ceca"),
    ("Q36", "Polonia"),
    ("Q218", "Romania"),
    ("Q219", "Bulgaria"),
    ("Q41", "Grecia"),
    ("Q43", "Turchia"),
    ("Q34", "Svezia"),
    ("Q33", "Finlandia"),
    ("Q20", "Norvegia"),
    ("Q27", "Irlanda"),
    ("Q45", "Portogallo"),
]


def query_wikidata() -> List[dict]:
    all_rows: List[dict] = []
    for country_qid, country_name in COUNTRIES:
        sparql = f"""
SELECT ?item ?itemLabel ?coord ?image WHERE {{
  ?item wdt:P625 ?coord;
        wdt:P18 ?image;
        wdt:P17 wd:{country_qid}.
  SERVICE wikibase:label {{ bd:serviceParam wikibase:language "it,en". }}
}}
LIMIT 800
"""
        params = {"query": sparql, "format": "json"}
        url = SPARQL_URL + "?" + urllib.parse.urlencode(params)
        try:
            data = http_get_json(url)
            rows = data.get("results", {}).get("bindings", [])
            for r in rows:
                r["countryLabel"] = {"value": country_name}
            all_rows.extend(rows)
        except Exception:
            continue
    return all_rows


def to_seed(rows: List[dict]) -> List[SeedPoint]:
    out: List[SeedPoint] = []
    seen = set()
    for r in rows:
        try:
            name = r["itemLabel"]["value"].strip()
            coord = r["coord"]["value"]
            image = r["image"]["value"].strip()
            country = r.get("countryLabel", {}).get("value", "Europa").strip()
            lat, lon = parse_wkt_point(coord)
            if not name or not image:
                continue
            point = SeedPoint(
                name=name[:180],
                region=("Italia" if country.lower() == "italia" else country)[:120],
                city=name[:120],
                latitude=lat,
                longitude=lon,
                image_url=image,
                description=f"Punto panoramico/attrazione reale da Wikidata ({country})",
            )
            k = point.key()
            if k in seen:
                continue
            seen.add(k)
            out.append(point)
        except Exception:
            continue
    return out


def sql_escape(v: str) -> str:
    return v.replace("'", "''")


def to_sql(points: List[SeedPoint]) -> str:
    lines = []
    lines.append("-- Wikidata Europe seed")
    lines.append("begin;")
    lines.append("alter table public.point_views add column if not exists source text;")
    lines.append("")
    chunk = 120
    for i in range(0, len(points), chunk):
        part = points[i:i + chunk]
        lines.append("insert into public.point_views")
        lines.append("(name, region, city, description, latitude, longitude, image_urls, source)")
        lines.append("select * from (values")
        vals = []
        for p in part:
            vals.append(
                "  ('{n}','{r}','{c}','{d}',{lat},{lon},array['{img}']::text[],'{s}')".format(
                    n=sql_escape(p.name),
                    r=sql_escape(p.region),
                    c=sql_escape(p.city),
                    d=sql_escape(p.description),
                    lat=f"{p.latitude:.6f}",
                    lon=f"{p.longitude:.6f}",
                    img=sql_escape(p.image_url),
                    s=sql_escape(p.source),
                )
            )
        lines.append(",\n".join(vals))
        lines.append(") as v(name, region, city, description, latitude, longitude, image_urls, source)")
        lines.append("where not exists (")
        lines.append("  select 1 from public.point_views p")
        lines.append("  where lower(p.name)=lower(v.name)")
        lines.append("    and abs(coalesce(p.latitude, 0) - v.latitude) < 0.0001")
        lines.append("    and abs(coalesce(p.longitude, 0) - v.longitude) < 0.0001")
        lines.append(");")
        lines.append("")
    lines.append("commit;")
    return "\n".join(lines) + "\n"


def main() -> None:
    os.makedirs(OUT_DIR, exist_ok=True)
    rows = query_wikidata()
    pts = to_seed(rows)
    italy = [p for p in pts if p.region.lower() == "italia"]
    rest = [p for p in pts if p.region.lower() != "italia"]

    selected = italy[:TARGET_ITALY] + rest[: max(0, TARGET_TOTAL - min(len(italy), TARGET_ITALY))]
    if len(selected) < TARGET_TOTAL:
        # fallback: aggiunge il resto senza priorita' finche' possibile
        remaining = [p for p in pts if p not in selected]
        selected.extend(remaining[: TARGET_TOTAL - len(selected)])

    with open(JSON_OUT, "w", encoding="utf-8") as f:
        json.dump([p.__dict__ for p in selected], f, ensure_ascii=False, indent=2)
    with open(SQL_OUT, "w", encoding="utf-8") as f:
        f.write(to_sql(selected))

    italy_count = sum(1 for p in selected if p.region.lower() == "italia")
    print(f"Wikidata rows: {len(rows)}")
    print(f"Selected points: {len(selected)}")
    print(f"Italy points: {italy_count}")
    print(f"JSON: {JSON_OUT}")
    print(f"SQL : {SQL_OUT}")


if __name__ == "__main__":
    main()
