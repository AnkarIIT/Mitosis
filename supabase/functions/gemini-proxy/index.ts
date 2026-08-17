import { createClient } from "npm:@supabase/supabase-js@2";

// =============================================================================
//  gemini-proxy — NEET Mitosis AI tutor edge function
// =============================================================================
//  A thin, rate-limited cache in front of the Gemini API.
//
//    T2: prompt-hash cache hit  -> return cached response, $0
//    T3: cache miss             -> call Gemini Flash, write-through, return
//
//  Callers identify themselves via their Supabase JWT (or anonymous by IP).
//  Cache reads are free for everyone; live Gemini calls are rate-limited
//  per user per hour so a single API key survives 100K users.
//
//  Deploy (from the project root):
//    1. supabase secrets set GEMINI_API_KEY=<your-key>
//       # optional: supabase secrets set GEMINI_MODEL=gemini-1.5-flash
//       # optional: supabase secrets set GEMINI_RATE_LIMIT=30
//    2. supabase functions deploy gemini-proxy --no-verify-jwt
//       # --no-verify-jwt so guest users (no JWT) can still use the tutor
//    3. supabase db push   (applies supabase/03_ai_proxy.sql)
// =============================================================================

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const MODEL = Deno.env.get("GEMINI_MODEL") ?? "gemini-1.5-flash";
const GEMINI_URL =
  `https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent`;
const RATE_LIMIT_PER_HOUR = Number(Deno.env.get("GEMINI_RATE_LIMIT") ?? "30");
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000;

interface RequestBody {
  prompt?: unknown;
  systemPrompt?: unknown;
  questionId?: unknown;
  temperature?: unknown;
}

function json(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
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
    const detail = (await res.text()).slice(0, 400);
    throw new Error(`Gemini API ${res.status}: ${detail}`);
  }

  const data = await res.json();
  const parts: { text?: string }[] =
    data?.candidates?.[0]?.content?.parts ?? [];
  return parts.map((p) => p.text ?? "").join("").trim();
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return json({ ok: true });
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  );

  // ---- Caller identity: JWT subject, or anonymous by client IP ------------
  const authHeader = req.headers.get("Authorization");
  const token = authHeader?.startsWith("Bearer ")
    ? authHeader.slice(7)
    : null;
  let identity: string | null = null;
  if (token) {
    const { data, error } = await supabase.auth.getUser(token);
    if (!error && data.user?.id) identity = data.user.id;
  }
  if (!identity) {
    const ip = req.headers.get("x-forwarded-for")?.split(",")[0]?.trim() ??
      "unknown";
    identity = `anon:${ip}`;
  }

  // ---- Parse & validate the request --------------------------------------
  let body: RequestBody;
  try {
    body = await req.json();
  } catch {
    return json({ error: "Invalid JSON body" }, 400);
  }

  const prompt = typeof body.prompt === "string" ? body.prompt.trim() : "";
  if (!prompt) {
    return json({ error: "prompt is required" }, 400);
  }
  const systemPrompt = typeof body.systemPrompt === "string"
    ? body.systemPrompt
    : undefined;
  const questionId = typeof body.questionId === "string" &&
      body.questionId.length > 0
    ? body.questionId
    : null;
  const temperature = typeof body.temperature === "number"
    ? Math.min(Math.max(body.temperature, 0), 1)
    : 0.2;

  // ---- T2: cache lookup ---------------------------------------------------
  const hash = await sha256Hex(`${systemPrompt ?? ""}\n${prompt}`);
  const { data: cached, error: cacheErr } = await supabase
    .from("ai_response_cache")
    .select("response")
    .eq("prompt_hash", hash)
    .maybeSingle();

  if (!cacheErr && cached?.response) {
    return json({
      cached: true,
      source: "cache",
      response: cached.response,
      model: MODEL,
    });
  }

  // ---- Rate limit before touching the paid API ---------------------------
  const { count } = await supabase
    .from("ai_usage_log")
    .select("*", { count: "exact", head: true })
    .eq("user_id", identity)
    .gte("created_at", new Date(Date.now() - RATE_LIMIT_WINDOW_MS).toISOString());

  if ((count ?? 0) >= RATE_LIMIT_PER_HOUR) {
    return json(
      {
        error: "Rate limit exceeded. Please try again in an hour.",
        retryAfterSeconds: RATE_LIMIT_WINDOW_MS / 1000,
      },
      429,
    );
  }

  // ---- T3: live Gemini call with write-through cache ----------------------
  try {
    const response = await callGemini(prompt, systemPrompt, temperature);
    await supabase.from("ai_usage_log").insert({ user_id: identity });

    if (response) {
      await supabase
        .from("ai_response_cache")
        .insert({
          prompt_hash: hash,
          original_prompt: prompt,
          question_id: questionId,
          response,
          model: MODEL,
        })
        .onConflict("prompt_hash")
        .ignore();
    }

    return json({
      cached: false,
      source: "gemini",
      response,
      model: MODEL,
    });
  } catch (err) {
    return json(
      { error: err instanceof Error ? err.message : "Upstream error" },
      502,
    );
  }
});
