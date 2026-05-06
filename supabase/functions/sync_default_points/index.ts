import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { corsHeaders, json } from "../_shared/cors.ts";

type SeedPoint = {
  external_id: string;
  name: string;
  region: string;
  city: string;
  description: string;
  latitude: number;
  longitude: number;
  seed_rating: number;
  seed_rating_count: number;
};

type WikiGeoSearchItem = {
  title: string;
  dist: number;
};

const FALLBACK_POINTS: SeedPoint[] = [
  {
    external_id: "vistaapp-no-trolltunga",
    name: "Trolltunga Viewpoint",
    region: "Vestland",
    city: "Ullensvang",
    description: "Scogliera iconica sulla valle norvegese.",
    latitude: 60.1241,
    longitude: 6.7403,
    seed_rating: 4.8,
    seed_rating_count: 1340,
  },
  {
    external_id: "vistaapp-es-sannicolas",
    name: "Mirador de San Nicolas",
    region: "Andalusia",
    city: "Granada",
    description: "Vista classica sull'Alhambra al tramonto.",
    latitude: 37.181,
    longitude: -3.5882,
    seed_rating: 4.7,
    seed_rating_count: 2120,
  },
  {
    external_id: "vistaapp-it-seceda",
    name: "Seceda Panorama",
    region: "Trentino-Alto Adige",
    city: "Ortisei",
    description: "Cresta dolomitica con vista 360 gradi.",
    latitude: 46.6068,
    longitude: 11.7545,
    seed_rating: 4.9,
    seed_rating_count: 960,
  },
];

function mapOverpassToSeed(data: unknown): SeedPoint[] {
  if (!data || typeof data !== "object") return [];
  const elements = (data as { elements?: unknown[] }).elements;
  if (!Array.isArray(elements)) return [];
  const out: SeedPoint[] = [];

  for (const el of elements) {
    if (!el || typeof el !== "object") continue;
    const row = el as Record<string, unknown>;
    const lat = Number(row.lat);
    const lon = Number(row.lon);
    if (!Number.isFinite(lat) || !Number.isFinite(lon)) continue;
    const tags = row.tags as Record<string, unknown> | undefined;
    const name = String(tags?.name ?? "").trim();
    if (!name) continue;
    const region = String(tags?.["addr:state"] ?? tags?.region ?? "Europe");
    const city = String(tags?.["addr:city"] ?? tags?.["is_in:city"] ?? "N/A");
    const extId = `overpass-${row.id}`;
    out.push({
      external_id: extId,
      name,
      region,
      city,
      description: "Punto panoramico importato da OpenStreetMap (Overpass).",
      latitude: lat,
      longitude: lon,
      seed_rating: 4.3,
      seed_rating_count: 120,
    });
    if (out.length >= 20) break;
  }
  return out;
}

async function fetchOverpassPointsFrom(endpoint: string): Promise<SeedPoint[]> {
  const query = `
[out:json][timeout:25];
node["tourism"="viewpoint"](35,-10,71,40);
out body 80;
`;
  const response = await fetch(endpoint, {
    method: "POST",
    body: query,
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
  });
  if (!response.ok) {
    throw new Error(`Overpass error ${response.status}`);
  }
  const data = await response.json();
  return mapOverpassToSeed(data);
}

async function fetchOverpassPoints(): Promise<{ points: SeedPoint[]; endpoint: string }> {
  const endpoints = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
  ];
  for (const endpoint of endpoints) {
    try {
      const points = await fetchOverpassPointsFrom(endpoint);
      if (points.length > 0) {
        return { points, endpoint };
      }
    } catch (_) {
      // Try next public endpoint.
    }
  }
  throw new Error("all-overpass-endpoints-failed");
}

async function fetchWikipediaGeoCandidate(
  lat: number,
  lon: number,
): Promise<WikiGeoSearchItem | null> {
  const url = new URL("https://en.wikipedia.org/w/api.php");
  url.searchParams.set("action", "query");
  url.searchParams.set("list", "geosearch");
  url.searchParams.set("gscoord", `${lat}|${lon}`);
  url.searchParams.set("gsradius", "10000");
  url.searchParams.set("gslimit", "1");
  url.searchParams.set("format", "json");
  url.searchParams.set("origin", "*");

  const response = await fetch(url);
  if (!response.ok) return null;
  const data = await response.json() as {
    query?: { geosearch?: Array<{ title?: string; dist?: number }> };
  };
  const first = data.query?.geosearch?.[0];
  if (!first?.title) return null;
  return { title: first.title, dist: Number(first.dist ?? 0) };
}

async function fetchWikipediaMonthlyViews(title: string): Promise<number | null> {
  const article = encodeURIComponent(title.replaceAll(" ", "_"));
  const end = new Date();
  end.setDate(1);
  end.setHours(0, 0, 0, 0);
  const start = new Date(end);
  start.setMonth(start.getMonth() - 3);
  const format = (d: Date) =>
    `${d.getUTCFullYear()}${String(d.getUTCMonth() + 1).padStart(2, "0")}0100`;

  const url =
    `https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article/` +
    `en.wikipedia.org/all-access/user/${article}/monthly/${format(start)}/${format(end)}`;
  const response = await fetch(url);
  if (!response.ok) return null;

  const data = await response.json() as {
    items?: Array<{ views?: number }>;
  };
  const items = data.items ?? [];
  if (items.length === 0) return null;
  const total = items.reduce((sum, i) => sum + Number(i.views ?? 0), 0);
  return Math.round(total / items.length);
}

function normalizeRatingFromViews(monthlyViews: number): {
  seed_rating: number;
  seed_rating_count: number;
} {
  const votes = Math.max(50, Math.min(5000, monthlyViews));
  const log = Math.log10(Math.max(10, monthlyViews));
  const raw = 3.4 + (log - 2) * 0.7;
  const rating = Math.max(3.5, Math.min(4.9, raw));
  return {
    seed_rating: Number(rating.toFixed(1)),
    seed_rating_count: votes,
  };
}

async function enrichSeedRatings(points: SeedPoint[]): Promise<SeedPoint[]> {
  const out: SeedPoint[] = [];
  for (const point of points) {
    try {
      const nearbyArticle = await fetchWikipediaGeoCandidate(
        point.latitude,
        point.longitude,
      );
      if (!nearbyArticle || nearbyArticle.dist > 7000) {
        out.push(point);
        continue;
      }
      const monthlyViews = await fetchWikipediaMonthlyViews(nearbyArticle.title);
      if (!monthlyViews || monthlyViews < 10) {
        out.push(point);
        continue;
      }
      const normalized = normalizeRatingFromViews(monthlyViews);
      out.push({
        ...point,
        seed_rating: normalized.seed_rating,
        seed_rating_count: normalized.seed_rating_count,
      });
    } catch (_) {
      out.push(point);
    }
  }
  return out;
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) return json({ error: "Missing Authorization header" }, 401);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  // Solo utenti autenticati; per controllo admin si puo' estendere con app_metadata.
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError || !authData.user) return json({ error: "Unauthorized" }, 401);

  let points: SeedPoint[] = [];
  let sourceUsed = "overpass";
  let externalSource = "";
  try {
    const overpass = await fetchOverpassPoints();
    points = overpass.points;
    externalSource = overpass.endpoint;
    if (points.length === 0) throw new Error("empty-overpass");
    points = await enrichSeedRatings(points);
  } catch (_) {
    points = FALLBACK_POINTS;
    sourceUsed = "fallback";
  }

  const { error: deleteError } = await supabase
    .from("point_views")
    .delete()
    .eq("source", "vista_default");
  if (deleteError) return json({ error: deleteError.message }, 500);

  const payload = points.map((p) => ({
    name: p.name,
    region: p.region,
    city: p.city,
    description: p.description,
    latitude: p.latitude,
    longitude: p.longitude,
    source: "vista_default",
    external_id: p.external_id,
    seed_rating: p.seed_rating,
    seed_rating_count: p.seed_rating_count,
    created_by: null,
  }));

  const { error: insertError } = await supabase.from("point_views").insert(payload);
  if (insertError) return json({ error: insertError.message }, 500);

  return json({
    ok: true,
    imported_count: payload.length,
    source_used: sourceUsed,
    source_endpoint: externalSource || null,
  });
});
