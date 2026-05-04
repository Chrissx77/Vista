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

  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (userError || !user) {
    return json({ error: "Unauthorized" }, 401);
  }

  const { data: profile, error: profileError } = await supabase
    .from("profiles")
    .select("display_name, created_at")
    .eq("id", user.id)
    .maybeSingle();

  if (profileError) {
    return json({ error: profileError.message }, 500);
  }

  return json({
    data: {
      id: user.id,
      email: user.email ?? "",
      display_name: profile?.display_name ?? "",
      created_at: profile?.created_at ?? null,
    },
  });
});
