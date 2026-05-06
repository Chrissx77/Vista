#!/usr/bin/env python3
"""
Genera un dataset grande di punti panoramici/attrazioni geolocalizzate
con immagini reali da Wikipedia (thumbnail pageimages) usando GeoSearch.

Output:
- scripts/data/eu_viewpoints_seed.json
- scripts/data/eu_viewpoints_seed.sql
"""

from __future__ import annotations

import json
import os
import time
import urllib.parse
import urllib.request
import urllib.error
from dataclasses import dataclass
from typing import Dict, Iterable, List, Optional, Tuple

TARGET_TOTAL = 720
TARGET_ITALY = 260

ITALY_BBOX = (36.5, 6.5, 47.2, 18.8)  # south, west, north, east
EU_BBOX = (35.0, -10.8, 71.5, 40.5)

WIKI_LANGS = ["en"]
WIKI_API = "https://{lang}.wikipedia.org/w/api.php"

OUT_DIR = "scripts/data"
JSON_OUT = os.path.join(OUT_DIR, "eu_viewpoints_seed.json")
SQL_OUT = os.path.join(OUT_DIR, "eu_viewpoints_seed.sql")


@dataclass
class Viewpoint:
    name: str
    region: str
    city: str
    latitude: float
    longitude: float
    image_url: str
    description: str
    source: str = "seed_osm_wikidata_eu_v1"

    def dedupe_key(self) -> str:
        return f"{self.name.strip().lower()}|{round(self.latitude,4)}|{round(self.longitude,4)}"


def http_json(url: str, method: str = "GET", data: Optional[str] = None, timeout: int = 60) -> dict:
    req = urllib.request.Request(url, method=method)
    req.add_header("User-Agent", "VistaSeedBot/1.0 (local-dev)")
    req.add_header("Accept", "application/json")
    if data is not None:
        encoded = data.encode("utf-8")
        req.add_header("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
    else:
        encoded = None

    last_exc: Optional[Exception] = None
    for attempt in range(6):
        try:
            with urllib.request.urlopen(req, data=encoded, timeout=timeout) as resp:
                body = resp.read().decode("utf-8", errors="replace")
            return json.loads(body)
        except urllib.error.HTTPError as e:
            last_exc = e
            if e.code in (429, 500, 502, 503, 504):
                time.sleep(1.5 * (attempt + 1))
                continue
            raise
        except Exception as e:
            last_exc = e
            time.sleep(1.0 * (attempt + 1))
            continue
    if last_exc:
        raise last_exc
    raise RuntimeError("http_json failed without exception")


def chunk_bbox(bbox: Tuple[float, float, float, float], rows: int, cols: int) -> Iterable[Tuple[float, float, float, float]]:
    s, w, n, e = bbox
    lat_step = (n - s) / rows
    lon_step = (e - w) / cols
    for r in range(rows):
        for c in range(cols):
            cs = s + (r * lat_step)
            cn = s + ((r + 1) * lat_step)
            cw = w + (c * lon_step)
            ce = w + ((c + 1) * lon_step)
            yield (cs, cw, cn, ce)


def bbox_centers(bbox: Tuple[float, float, float, float], rows: int, cols: int) -> Iterable[Tuple[float, float]]:
    s, w, n, e = bbox
    lat_step = (n - s) / rows
    lon_step = (e - w) / cols
    for r in range(rows):
        for c in range(cols):
            lat = s + (r + 0.5) * lat_step
            lon = w + (c + 0.5) * lon_step
            yield lat, lon


def bbox_centers_shifted(
    bbox: Tuple[float, float, float, float],
    rows: int,
    cols: int,
    lat_shift_ratio: float = 0.33,
    lon_shift_ratio: float = 0.33,
) -> Iterable[Tuple[float, float]]:
    s, w, n, e = bbox
    lat_step = (n - s) / rows
    lon_step = (e - w) / cols
    lat_shift = lat_step * lat_shift_ratio
    lon_shift = lon_step * lon_shift_ratio
    for r in range(rows):
        for c in range(cols):
            lat = s + (r + 0.5) * lat_step + lat_shift
            lon = w + (c + 0.5) * lon_step + lon_shift
            # clamp
            lat = max(s + 0.01, min(n - 0.01, lat))
            lon = max(w + 0.01, min(e - 0.01, lon))
            yield lat, lon


def wiki_geosearch(lang: str, lat: float, lon: float, limit: int = 50) -> List[dict]:
    params = {
        "action": "query",
        "format": "json",
        "list": "geosearch",
        "gscoord": f"{lat}|{lon}",
        "gsradius": "10000",
        "gslimit": str(limit),
    }
    url = WIKI_API.format(lang=lang) + "?" + urllib.parse.urlencode(params)
    try:
        data = http_json(url, timeout=40)
        return data.get("query", {}).get("geosearch", [])
    except Exception:
        return []


def wiki_pages_with_images(lang: str, pageids: List[int]) -> Dict[int, dict]:
    if not pageids:
        return {}
    params = {
        "action": "query",
        "format": "json",
        "pageids": "|".join(str(i) for i in pageids),
        "prop": "pageimages|description|coordinates",
        "piprop": "thumbnail|name",
        "pithumbsize": "1200",
    }
    url = WIKI_API.format(lang=lang) + "?" + urllib.parse.urlencode(params)
    try:
        data = http_json(url, timeout=40)
        raw = data.get("query", {}).get("pages", {})
        out = {}
        for k, v in raw.items():
            try:
                out[int(k)] = v
            except Exception:
                continue
        return out
    except Exception:
        return {}


def in_italy(lat: float, lon: float) -> bool:
    s, w, n, e = ITALY_BBOX
    return s <= lat <= n and w <= lon <= e


def to_viewpoint(lang: str, geo_row: dict, page_row: dict) -> Optional[Viewpoint]:
    title = str(geo_row.get("title") or "").strip()
    if not title:
        return None
    thumb = page_row.get("thumbnail", {}).get("source")
    if not thumb:
        return None
    lat = float(geo_row.get("lat"))
    lon = float(geo_row.get("lon"))
    desc = str(page_row.get("description") or "").strip()
    region = "Italia" if in_italy(lat, lon) else "Europa"
    city = title[:120]
    return Viewpoint(
        name=title[:180],
        region=region,
        city=city,
        latitude=lat,
        longitude=lon,
        image_url=str(thumb),
        description=(desc or "Punto panoramico / attrazione con immagine reale da Wikipedia")[:500],
        source=f"seed_wikipedia_{lang}_v1",
    )


def gather_points() -> List[Viewpoint]:
    by_key: Dict[str, Viewpoint] = {}
    by_page: Dict[int, Viewpoint] = {}
    italy_keys: List[str] = []
    eu_keys: List[str] = []

    def add_from_centers(
        centers: Iterable[Tuple[float, float]],
        bucket: List[str],
        label: str,
        langs: List[str],
        target: Optional[int] = None,
    ) -> None:
        centers = list(centers)
        for idx, (lat, lon) in enumerate(centers, start=1):
            for lang in langs:
                geo = wiki_geosearch(lang, lat, lon, limit=50)
                if not geo:
                    continue
                ids = []
                for g in geo:
                    pid = g.get("pageid")
                    if isinstance(pid, int):
                        ids.append(pid)
                pages = wiki_pages_with_images(lang, ids)
                for g in geo:
                    pid = g.get("pageid")
                    if not isinstance(pid, int):
                        continue
                    if pid in by_page:
                        continue
                    page = pages.get(pid)
                    if not page:
                        continue
                    vp = to_viewpoint(lang, g, page)
                    if not vp:
                        continue
                    key = vp.dedupe_key()
                    if key in by_key:
                        continue
                    by_key[key] = vp
                    by_page[pid] = vp
                    bucket.append(key)
                time.sleep(0.15)
            print(f"[{label} {idx}/{len(centers)}] points={len(bucket)}")
            if target is not None and len(bucket) >= target:
                break

    # Italia più densa, Europa più larga
    add_from_centers(
        bbox_centers(ITALY_BBOX, rows=5, cols=5),
        italy_keys,
        "IT",
        langs=["it", "en"],
        target=TARGET_ITALY * 2,
    )
    add_from_centers(
        bbox_centers(EU_BBOX, rows=6, cols=8),
        eu_keys,
        "EU",
        langs=WIKI_LANGS,
        target=(TARGET_TOTAL - TARGET_ITALY),
    )
    if len(eu_keys) < (TARGET_TOTAL - TARGET_ITALY):
        add_from_centers(
            bbox_centers_shifted(EU_BBOX, rows=8, cols=10),
            eu_keys,
            "EU2",
            langs=["fr", "de", "es", "en"],
            target=(TARGET_TOTAL - TARGET_ITALY),
        )

    italy_unique = [by_key[k] for k in italy_keys][:TARGET_ITALY]
    remaining = TARGET_TOTAL - len(italy_unique)
    eu_unique = []
    italy_set = {p.dedupe_key() for p in italy_unique}
    for k in eu_keys:
        if k in italy_set:
            continue
        eu_unique.append(by_key[k])
        if len(eu_unique) >= remaining:
            break

    merged = italy_unique + eu_unique
    return merged


def sql_escape(value: str) -> str:
    return value.replace("'", "''")


def to_sql(points: List[Viewpoint]) -> str:
    lines: List[str] = []
    lines.append("-- Seed generated automatically from Wikipedia GeoSearch + PageImages")
    lines.append("-- It inserts only rows not already present by (name, lat, lon).")
    lines.append("begin;")
    lines.append(
        "alter table public.point_views add column if not exists source text;"
    )
    lines.append("")
    chunk_size = 120
    for i in range(0, len(points), chunk_size):
        chunk = points[i : i + chunk_size]
        lines.append("insert into public.point_views")
        lines.append(
            "(name, region, city, description, latitude, longitude, image_urls, source)"
        )
        lines.append("select * from (values")
        value_rows = []
        for p in chunk:
            value_rows.append(
                "  ('{name}','{region}','{city}','{desc}',{lat},{lon},array['{img}']::text[],'{source}')".format(
                    name=sql_escape(p.name),
                    region=sql_escape(p.region),
                    city=sql_escape(p.city),
                    desc=sql_escape(p.description),
                    lat=("{:.6f}".format(p.latitude)),
                    lon=("{:.6f}".format(p.longitude)),
                    img=sql_escape(p.image_url),
                    source=sql_escape(p.source),
                )
            )
        lines.append(",\n".join(value_rows))
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
    points = gather_points()
    with open(JSON_OUT, "w", encoding="utf-8") as f:
        json.dump([p.__dict__ for p in points], f, ensure_ascii=False, indent=2)

    sql = to_sql(points)
    with open(SQL_OUT, "w", encoding="utf-8") as f:
        f.write(sql)

    italy_count = sum(1 for p in points if 36.5 <= p.latitude <= 47.2 and 6.5 <= p.longitude <= 18.8)
    print(f"Generated points: {len(points)}")
    print(f"Italy points: {italy_count}")
    print(f"JSON: {JSON_OUT}")
    print(f"SQL : {SQL_OUT}")


if __name__ == "__main__":
    main()
