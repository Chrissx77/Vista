import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";
import { corsHeaders, json } from "../_shared/cors.ts";

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

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data, error } = await supabase
    .from("point_views")
    .select("*")
    .order("created_at", { ascending: false });

  if (error) {
    return json({ error: error.message }, 500);
  }

  return json({ data: data ?? [] });
});
