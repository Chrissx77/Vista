import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { corsHeaders, json } from "../_shared/cors.ts";

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "Missing Authorization header" }, 401);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (userError || !user) {
    return json({ error: "Unauthorized" }, 401);
  }

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const name = String(body["name"] ?? "").trim();
  const region = String(body["region"] ?? "").trim();
  const city = String(body["city"] ?? "").trim();
  if (!name || !region || !city) {
    return json({ error: "name, region e city sono obbligatori" }, 400);
  }

  const description = body["description"] != null
    ? String(body["description"])
    : null;
  const lat = body["latitude"];
  const lng = body["longitude"];

  const rawUrls = body["image_urls"];
  if (!Array.isArray(rawUrls)) {
    return json({ error: "image_urls deve essere un array di stringhe (URL)" }, 400);
  }
  const image_urls = rawUrls
    .map((u) => String(u).trim())
    .filter((u) => u.length > 0);
  if (image_urls.length < 1 || image_urls.length > 3) {
    return json({ error: "Servono tra 1 e 3 immagini (URL dopo upload su Storage)" }, 400);
  }

  const { error: insertError } = await supabase.from("point_views").insert({
    name,
    region,
    city,
    description,
    latitude: lat === null || lat === undefined || lat === ""
      ? null
      : Number(lat),
    longitude: lng === null || lng === undefined || lng === ""
      ? null
      : Number(lng),
    created_by: user.id,
    image_urls,
  });

  if (insertError) {
    return json({ error: insertError.message }, 500);
  }

  return json({ ok: true });
});
