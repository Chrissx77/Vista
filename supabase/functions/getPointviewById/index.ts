import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "GET") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "Missing Authorization header" }, 401);
  }

  const url = new URL(req.url);
  const id = url.searchParams.get("id");
  if (!id) {
    return json({ error: "Parametro id mancante" }, 400);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data, error } = await supabase
    .from("point_view_metrics")
    .select(`
      *,
      profiles (
        display_name
      ),
      point_view_services(
        status,
        point_services_catalog(name, slug, icon)
      ),
      point_reviews(
        id,
        user_id,
        rating,
        review_text,
        created_at
      )
    `)
    .eq("id", id)
    .maybeSingle();

  if (error) {
    return json({ error: error.message }, 500);
  }
  if (!data) {
    return json({ error: "Punto non trovato" }, 404);
  }

  const row = data as Record<string, unknown> & {
    profiles?: { display_name?: string } | { display_name?: string }[] | null;
  };
  let creator: { display_name?: string } | null = null;
  const raw = row.profiles;
  if (Array.isArray(raw)) {
    creator = raw[0] ?? null;
  } else if (raw && typeof raw === "object") {
    creator = raw as { display_name?: string };
  }
  const { profiles: _profiles, ...point } = row;

  return json({
    data: {
      ...point,
      creator_display_name: creator?.display_name?.trim() || null,
    },
  });
});
