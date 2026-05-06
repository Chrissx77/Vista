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

  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "Missing Authorization header" }, 401);
  }

  const userClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) {
    return json({ error: "Unauthorized" }, 401);
  }

  const adminClient = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    { auth: { autoRefreshToken: false, persistSession: false } },
  );

  const userId = user.id;

  const { error: pvError } = await adminClient
    .from("point_views")
    .delete()
    .eq("created_by", userId);
  if (pvError) {
    return json({ error: pvError.message }, 500);
  }

  const parallelDeletes = await Promise.all([
    adminClient.from("favorites").delete().eq("user_id", userId),
    adminClient.from("reports").delete().eq("reporter_id", userId),
    adminClient.from("blocks").delete().eq("blocker_id", userId),
    adminClient.from("blocks").delete().eq("blocked_id", userId),
  ]);
  for (const r of parallelDeletes) {
    if (r.error) {
      return json({ error: r.error.message }, 500);
    }
  }

  // Storage cleanup in background: non bloccare deleteUser (timeout client).
  const storageCleanup = (async () => {
    try {
      const { data: files } = await adminClient.storage
        .from("pointview-images")
        .list(userId, { limit: 1000 });
      if (files && files.length > 0) {
        const paths = files.map((f) => `${userId}/${f.name}`);
        await adminClient.storage.from("pointview-images").remove(paths);
      }
    } catch (_) {
      /* best-effort */
    }
  })();

  // https://supabase.com/docs/guides/functions/background-tasks
  // deno-lint-ignore no-explicit-any
  const edgeRuntime = (globalThis as any).EdgeRuntime as
    | { waitUntil?: (p: Promise<unknown>) => void }
    | undefined;
  if (edgeRuntime?.waitUntil) {
    edgeRuntime.waitUntil(storageCleanup);
  } else {
    await storageCleanup;
  }

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(
    userId,
  );
  if (deleteError) {
    return json({ error: deleteError.message }, 500);
  }

  return json({ ok: true });
});
