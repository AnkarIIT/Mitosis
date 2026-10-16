import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

// =============================================================================
//  delete-account — permanent account deletion
// =============================================================================
//  Deletes the caller's Supabase auth user. The service-role key is used ONLY
//  here, inside the function, and never ships in the client.
//
//  ## Authorization
//  The caller must present the JWT of the account being deleted. The function
//  derives the target id from `auth.getUser()` and never reads it from the
//  request body — otherwise any authenticated user could delete any other
//  account by passing someone else's id.
//
//  ## Why re-authentication is still the caller's job
//  Any live session can invoke this. That is why the app requires a
//  confirmation step before calling it, and why the UI should ask the user to
//  re-enter their password (or confirm with biometrics) first. The function
//  cannot verify intent — only possession of a valid session.
//
//  ## Cascade
//  Deleting the auth user relies on `ON DELETE CASCADE` from every
//  user-owned table's `user_id` foreign key to `auth.users(id)`. Verify that
//  each table in supabase/00_core_tables.sql declares that constraint, or the
//  rows will be orphaned.
//
//  Deploy:
//    supabase functions deploy delete-account
//    (JWT verification stays ON — that is what scopes deletion to the caller.)
// =============================================================================

const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",")
  .map((o) => o.trim())
  .filter((o) => o.length > 0);

/** True when [origin] is on the allowlist. */
function isOriginAllowed(origin: string): boolean {
  return ALLOWED_ORIGINS.includes(origin);
}

/** Minimum spacing between deletion calls from the same identity.
 *
 *  Deliberately weak and honestly so: this map lives in the isolate and is lost
 *  on restart or redeploy, so it raises the cost of a replay/retry storm rather
 *  than bounding it. Its real job is absorbing concurrent double-submits, which
 *  otherwise surface as a confusing 502 from the admin API.
 *
 *  What this endpoint really wants is re-authentication (the user re-entering
 *  their password) before `deleteUser` runs. That needs a coordinated client
 *  change as well, so it is not done unilaterally here. */
const DELETION_COOLDOWN_MS = 60_000;
const recentDeletions = new Map<string, number>();

function inDeletionCooldown(userId: string): boolean {
  const now = Date.now();
  for (const [id, at] of recentDeletions) {
    if (now - at > DELETION_COOLDOWN_MS) recentDeletions.delete(id);
  }
  const last = recentDeletions.get(userId);
  return last !== undefined && now - last < DELETION_COOLDOWN_MS;
}

function json(
  data: unknown,
  status = 200,
  origin: string | null = null,
): Response {
  // Mirrors gemini-proxy: reflect the origin only when allowlisted. Absence of
  // the header when ALLOWED_ORIGINS is unset makes browsers block the response
  // rather than letting every site read it.
  const allowed = origin && isOriginAllowed(origin);
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      ...(allowed ? { "Access-Control-Allow-Origin": origin } : {}),
      "Access-Control-Allow-Headers":
        "authorization, x-client-info, apikey, content-type",
      "Access-Control-Allow-Methods": "POST, OPTIONS",
      "Vary": "Origin",
      "Content-Type": "application/json",
    },
  });
}

Deno.serve(async (request) => {
  const origin = request.headers.get("Origin");

  if (request.method === "OPTIONS") return json({ ok: true }, 200, origin);
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405, origin);
  }

  // Reject disallowed origins outright rather than merely omitting the CORS
  // header: deletion is irreversible, so an origin we would not let read the
  // response must not be able to trigger one.
  if (origin && !isOriginAllowed(origin)) {
    return json({ error: "Origin not allowed" }, 403, null);
  }

  const authorization = request.headers.get("Authorization");
  if (!authorization) {
    return json({ error: "Unauthorized" }, 401, origin);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return json({ error: "Account deletion is not configured" }, 503, origin);
  }

  // Resolve the caller from their own token. The target id is never taken from
  // the request body.
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authorization } },
  });
  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser();
  if (userError || !user) {
    return json({ error: "Unauthorized" }, 401, origin);
  }

  const adminClient = createClient(supabaseUrl, serviceRoleKey);

  if (inDeletionCooldown(user.id)) {
    return json(
      { error: "Please wait before retrying account deletion" },
      429,
      origin,
    );
  }
  recentDeletions.set(user.id, Date.now());

  const { error: deleteError } = await adminClient.auth.admin.deleteUser(user.id);
  if (deleteError) {
    // Log the detail server-side; return a generic message so internals and the
    // admin API's wording are not disclosed to the caller.
    console.error(
      `delete-account: failed for ${user.id}: ${deleteError.message}`,
    );
    return json({ error: "Account deletion failed" }, 502, origin);
  }

  // Audit trail. Deletion is irreversible, so record that it happened. The email
  // is stored hashed-by-omission: we keep the id (the durable identifier) and
  // deliberately drop the address so the log cannot become a PII store.
  console.log(
    JSON.stringify({
      event: "account_deleted",
      user_id: user.id,
      provider: user.app_metadata?.provider ?? "unknown",
      at: new Date().toISOString(),
    }),
  );

  // The client is responsible for clearing its local session and local database
  // after this returns 200. The function has no way to reach the device.
  return json({ success: true }, 200, origin);
});