import { createClient } from "npm:@supabase/supabase-js@2";

// =============================================================================
//  gemini-proxy — NEET Mitosis AI tutor edge function
// =============================================================================
//  A thin, rate-limited cache in front of the Gemini API.
//
//    T2: prompt-hash cache hit  -> return cached response, $0
//    T3: cache miss             -> call Gemini Flash, write-through, return
//
//  Callers identify themselves via their Supabase JWT. Guests are supported
//  (the function is deployed `--no-verify-jwt`) but are held to a much tighter
//  quota and a separate cache partition, because "who are you" for an
//  unauthenticated caller is necessarily a guess.
//
//  Deploy (from the project root):
//    1. supabase secrets set GEMINI_API_KEY=<your-key>
//       # optional: supabase secrets set GEMINI_MODEL=gemini-1.5-flash
//       # optional: supabase secrets set GEMINI_RATE_LIMIT=30
//       # optional: supabase secrets set GEMINI_ANON_RATE_LIMIT=5
//       # optional: supabase secrets set ALLOWED_ORIGINS=https://your.app,http://localhost:3000
//    2. supabase functions deploy gemini-proxy --no-verify-jwt
//       # --no-verify-jwt so guest users (no JWT) can still use the tutor.
//       # Do NOT remove it if the tutor must work for signed-out visitors.
//    3. node scripts/apply-migrations.mjs   (applies supabase/*.sql in order)
// =============================================================================

// -----------------------------------------------------------------------------
// CORS
// -----------------------------------------------------------------------------
// ⚠️ This was `"*"`, which let any website on the internet drive the shared
// GEMINI_API_KEY through this function — a third party could use your quota and
// your key with a one-line fetch from their own page.
//
// The allowlist is now explicit. Set ALLOWED_ORIGINS (comma-separated) to the
// origins that legitimately host the app: the production web origin, the
// staging origin, and local dev during testing.
//
// ⚠️ CORS is a browser-enforced read barrier, NOT authentication. It stops
// other websites from *reading* responses; it does not stop a non-browser
// client (curl, a script) from calling the function. The real access control is
// the JWT check and the rate limit below.
const ALLOWED_ORIGINS = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
  .split(",")
  .map((o) => o.trim())
  .filter((o) => o.length > 0);

/** True when [origin] is on the allowlist. */
function isOriginAllowed(origin: string): boolean {
  return ALLOWED_ORIGINS.includes(origin);
}

function corsHeaders(origin: string | null): Record<string, string> {
  // Reflect the origin only when it is on the allowlist. When the allowlist is
  // empty we deliberately send no CORS headers at all, so browsers block the
  // response rather than silently allowing every site.
  const allowed = origin && isOriginAllowed(origin);
  return {
    ...(allowed ? { "Access-Control-Allow-Origin": origin } : {}),
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

const MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-2.0-flash-exp";
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;

/** Reads a positive-integer quota from the environment.
 *
 *  `Number(env ?? fallback)` fails OPEN on a bad value: `Number("")` is 0 and
 *  `Number("30/hour")` is NaN, and `count >= NaN` is always false — so a stray
 *  character in the config silently removes the spend ceiling entirely.
 *  Anything unparseable falls back to the documented default. */
function readLimit(name: string, fallback: number): number {
  const raw = Deno.env.get(name);
  if (raw === undefined || raw.trim() === "") return fallback;
  const parsed = Number(raw);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    console.error(
      `gemini-proxy: ${name}="${raw}" is not a positive number; using ${fallback}`,
    );
    return fallback;
  }
  return Math.floor(parsed);
}

/** Quota for an authenticated caller (strong identity: a real user id). */
const RATE_LIMIT_PER_HOUR = readLimit("GEMINI_RATE_LIMIT", 30);
/**
 * Quota for an unauthenticated caller.
 *
 * Deliberately ~6x lower. An anonymous identity is derived from an IP address,
 * which an attacker controls by rotating proxies, so the hourly quota is not a
 * reliable spend ceiling — it only raises the cost of casual abuse.
 */
const ANON_RATE_LIMIT_PER_HOUR = readLimit("GEMINI_ANON_RATE_LIMIT", 5);
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000;

/** Bounds a single request so it cannot be used to burn quota on huge inputs. */
const MAX_PROMPT_CHARS = 8000;
const MAX_SYSTEM_PROMPT_CHARS = 4000;

interface RequestBody {
  prompt?: unknown;
  systemPrompt?: unknown;
  questionId?: unknown;
  temperature?: unknown;
  /**
   * Opt-in to the shared cache. MUST be false whenever `systemPrompt` carries
   * any per-student data (accuracy, weak topics, days-to-exam, study mode).
   *
   * The cache is a shared corpus: an entry written by one student is served to
   * every other. Personalised answers are therefore never cacheable — serving
   * them would leak one student's progress and weak topics to another. An
   * absent flag means false, so an older client that does not send this is
   * treated as un-cacheable rather than trusted.
   */
  cacheable?: unknown;
}

function json(
  data: unknown,
  status = 200,
  origin: string | null = null,
): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders(origin), "Content-Type": "application/json" },
  });
}

async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(text),
  );
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Best-effort client IP for anonymous rate limiting.
 *
 * ⚠️ `x-forwarded-for` is client-controlled: a caller can send any value, and
 * the previous implementation read the FIRST entry, which is the one the client
 * writes. The honest reading is the LAST entry — intermediaries append the
 * address they actually observed, so anything the client prepended is a lie.
 *
 * This remains spoofable in principle: a client that sets no header at all, or
 * strips the trailing entry, still controls what we see. It is a speed bump
 * against casual abuse, not an authentication mechanism. Do not treat the
 * anonymous quota as a spend guarantee.
 */
function clientIp(req: Request): string {
  const forwarded = req.headers.get("x-forwarded-for");
  if (forwarded) {
    const hops = forwarded.split(",").map((h) => h.trim()).filter(Boolean);
    if (hops.length > 0) return hops[hops.length - 1];
  }
  return req.headers.get("x-real-ip")?.trim() || "unknown";
}

/** Calls Gemini and returns the trimmed response text. */
async function callGemini(
  prompt: string,
  systemPrompt: string | undefined,
  temperature: number,
): Promise<string> {
  const apiKey = Deno.env.get("GEMINI_API_KEY");
  if (!apiKey) {
    throw new Error("GEMINI_API_KEY secret is not configured on the function");
  }

  const payload: Record<string, unknown> = {
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    generationConfig: { temperature },
  };
  if (systemPrompt && systemPrompt.trim().length > 0) {
    payload.systemInstruction = { parts: [{ text: systemPrompt }] };
  }

  const res = await fetch(`${GEMINI_URL}?key=${apiKey}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });

  if (!res.ok) {
    // Read the upstream body so it lands in the function log, but do NOT put it
    // in the client response: upstream errors can echo the API key back, and
    // they disclose provider internals to callers.
    const detail = (await res.text()).slice(0, 400);
    console.error(`gemini-proxy: upstream ${res.status}: ${detail}`);
    throw new Error(`upstream_${res.status}`);
  }

  const data = await res.json();
  const parts: { text?: string }[] =
    data?.candidates?.[0]?.content?.parts ?? [];
  return parts.map((p) => p.text ?? "").join("").trim();
}

Deno.serve(async (req) => {
  const origin = req.headers.get("Origin");

  if (req.method === "OPTIONS") return json({ ok: true }, 200, origin);
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405, origin);
  }

  // Reject disallowed origins outright. Previously the allowlist only decided
  // whether to *emit* Access-Control-Allow-Origin — the handler ran to
  // completion regardless. A browser then blocked the response but the Gemini
  // call had already been made and the quota already consumed, so any site on
  // the internet could still spend the shared key (this function is deployed
  // --no-verify-jwt and the anon apikey ships inside the app binary).
  if (origin && !isOriginAllowed(origin)) {
    return json({ error: "Origin not allowed" }, 403, null);
  }

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ---- Caller identity -----------------------------------------------------
  // Authenticated callers get a real user id (strong identity). Everyone else is
  // bucketed under an IP-derived key and marked anonymous, which selects both
  // the tighter quota and the isolated cache partition.
  const authHeader = req.headers.get("Authorization");
  const token = authHeader?.startsWith("Bearer ")
    ? authHeader.slice(7)
    : null;
  let userId: string | null = null;
  if (token) {
    const { data, error } = await supabase.auth.getUser(token);
    if (!error && data.user?.id) userId = data.user.id;
  }
  const isAnonymous = userId === null;
  const identity = userId ?? `anon:${clientIp(req)}`;

  // ---- Parse & validate the request ----------------------------------------
  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400, origin);
  }

  const prompt = typeof body.prompt === "string" ? body.prompt.trim() : "";
  if (!prompt) {
    return json({ error: "prompt is required" }, 400, origin);
  }
  if (prompt.length > MAX_PROMPT_CHARS) {
    return json(
      {
        error: `prompt exceeds ${MAX_PROMPT_CHARS} characters`,
      },
      413,
      origin,
    );
  }

  const rawSystem = typeof body.systemPrompt === "string"
    ? body.systemPrompt.trim()
    : "";
  const systemPrompt = rawSystem.length > MAX_SYSTEM_PROMPT_CHARS
    ? rawSystem.slice(0, MAX_SYSTEM_PROMPT_CHARS)
    : rawSystem || undefined;

  const questionId = typeof body.questionId === "string" &&
      body.questionId.length > 0
    ? body.questionId
    : null;
  const temperature = typeof body.temperature === "number"
    ? Math.min(Math.max(body.temperature, 0), 1)
    : 0.2;

  // Cache partition. Reads are scoped to the SAME partition that writes are
  // scoped to, so the two directions agree.
  //
  // This used to be `isAnonymous ? "anon" : null`, i.e. anonymous reads were
  // narrowed but *authenticated* reads were unscoped. An anonymous caller could
  // therefore seed an entry under scope='anon' that every signed-in user was
  // then served — the exact poisoning the 'anon' partition exists to prevent.
  // Writing is `isAnonymous ? "anon" : "shared"`, so both sides now use:
  const readableScope = isAnonymous ? "anon" : "shared";

  // Opt-in only. A personalised prompt produces an answer that is correct for
  // ONE student; sharing it would leak their accuracy, weak topics and
  // exam countdown to everyone else, so those requests bypass the cache in
  // both directions rather than being written with a key that happens to be
  // unique. Callers that send a subject-only, student-independent system prompt
  // opt in and get the shared corpus the table exists for.
  const cacheable = body.cacheable === true;
  if (body.cacheable !== undefined && body.cacheable !== true) {
    console.warn(
      `gemini-proxy: cacheable must be boolean true; got ${typeof body.cacheable}`,
    );
  }

  // ---- T2: cache lookup ---------------------------------------------------
  // temperature is part of the key: it is client-controlled and materially
  // changes the output, so omitting it let one caller seed a `temperature: 1.0`
  // response that every later caller with the same prompt was served for free.
  const hash = await sha256Hex(
    `${systemPrompt ?? ""}\n${prompt}\n#temp=${temperature}`,
  );
  let cacheQuery = supabase
    .from("ai_response_cache")
    .select("response")
    .eq("prompt_hash", hash);
  cacheQuery = cacheQuery.eq("scope", readableScope);

  const { data: cached, error: cacheErr } = await cacheQuery.maybeSingle();

  if (cacheable && !cacheErr && cached?.response) {
    return json(
      {
        cached: true,
        source: "cache",
        response: cached.response,
        model: MODEL,
      },
      200,
      origin,
    );
  }

  // ---- Rate limit before touching the paid API ----------------------------
  const quota = isAnonymous ? ANON_RATE_LIMIT_PER_HOUR : RATE_LIMIT_PER_HOUR;
  const { count, error: countErr } = await supabase
    .from("ai_usage_log")
    .select("*", { count: "exact", head: true })
    .eq("user_id", identity)
    .gte("created_at", new Date(Date.now() - RATE_LIMIT_WINDOW_MS).toISOString());

  // Fail CLOSED. The count query used to discard its error, so any DB fault
  // left `count` undefined, `?? 0` compared `0 >= quota` as false, and the
  // request proceeded to a *paid* Gemini call with no usage row recorded.
  if (countErr) {
    console.error("gemini-proxy: rate-limit query failed", countErr);
    return json(
      { error: "AI tutor is temporarily unavailable" },
      503,
      origin,
    );
  }

  if ((count ?? 0) >= quota) {
    return json(
      {
        error: "Rate limit exceeded. Please try again in an hour.",
        retryAfterSeconds: RATE_LIMIT_WINDOW_MS / 1000,
      },
      429,
      origin,
    );
  }

  // ---- T3: live Gemini call with write-through cache -----------------------
  // Consume the quota BEFORE the upstream call. A cache hit returns above and
  // never reaches this point, so it correctly consumes nothing.
  //
  // The check above and this insert are still not atomic (no DB-level
  // guarantee), but recording first shrinks the race window from a 1–5s
  // upstream round-trip to two adjacent DB calls. It also means an upstream 5xx
  // still costs quota instead of being free to retry into a bill. Closing the
  // race fully needs an atomic INSERT … SELECT count(*) … RETURNING.
  const { error: usageErr } = await supabase
    .from("ai_usage_log")
    .insert({ user_id: identity });
  if (usageErr) {
    console.error("gemini-proxy: failed to record usage", usageErr);
    return json({ error: "AI tutor is temporarily unavailable" }, 503, origin);
  }

  try {
    const response = await callGemini(prompt, systemPrompt, temperature);

    if (response && cacheable) {
      // Only unpersonalised answers are persisted. Writing a personalised
      // response here would put one student's accuracy / weak topics / exam
      // countdown into a table every other student can read back.
      // `original_prompt` is stored in a table the user cannot read or delete.
      // Store only a short prefix: it is enough to diagnose a bad generation,
      // and it does not persist a full transcript of what a student typed.
      await supabase.from("ai_response_cache").upsert(
        {
          prompt_hash: hash,
          original_prompt: prompt.slice(0, 500),
          question_id: questionId,
          response,
          model: MODEL,
          scope: isAnonymous ? "anon" : "shared",
        },
        // The conflict target MUST match the composite unique in
        // 03_ai_proxy.sql, UNIQUE (prompt_hash, scope). Left as "prompt_hash"
        // it resolves to a constraint that no longer exists (PostgREST 42P01),
        // and even where it does resolve it silently drops the second
        // partition's row — so a guest touching a prompt first would starve the
        // shared cache permanently and every student would pay full price.
        { onConflict: "prompt_hash,scope", ignoreDuplicates: true },
      );
    }

    return json(
      {
        cached: false,
        source: "gemini",
        response,
        model: MODEL,
      },
      200,
      origin,
    );
  } catch (err) {
    // Generic body; the detail is already in the function log above.
    return json({ error: "AI service temporarily unavailable" }, 502, origin);
  }

});