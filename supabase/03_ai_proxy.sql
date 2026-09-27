-- =============================================================================
--  03_ai_proxy.sql  -  AI tutor edge-function infrastructure
-- =============================================================================
--  Backing tables for the `gemini-proxy` Supabase Edge Function:
--
--    * ai_response_cache : prompt-hash keyed cache of generated answers. The
--                          SAME question asked by 1000 students returns on the
--                          second+ request for free (T2 in the app's 3-tier
--                          offline-first AI strategy).
--    * ai_usage_log      : append-only per-user call log used to enforce the
--                          hourly live-AI rate limit (T3 calls only).
--
--  Security: only the edge function (service_role) can touch these tables.
--  The Flutter app never reads them directly — it goes through the function.
--
--  Run with:  supabase db push   (or paste into the Supabase SQL Editor).
--  Idempotent: safe to re-run.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. ai_response_cache
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_response_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prompt_hash TEXT NOT NULL UNIQUE,
    original_prompt TEXT NOT NULL,
    question_id TEXT,
    response TEXT NOT NULL,
    model VARCHAR(50),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_cache_hash
    ON public.ai_response_cache(prompt_hash);
CREATE INDEX IF NOT EXISTS idx_ai_cache_question_id
    ON public.ai_response_cache(question_id)
    WHERE question_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 2. ai_usage_log
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_usage_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_usage_user_time
    ON public.ai_usage_log(user_id, created_at);

-- ---------------------------------------------------------------------------
-- 3. Row Level Security — service_role only
-- ---------------------------------------------------------------------------
ALTER TABLE public.ai_response_cache ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_usage_log ENABLE ROW LEVEL SECURITY;

-- Anon and authenticated clients must NOT bypass the proxy.
DROP POLICY IF EXISTS "no anon access to ai_response_cache" ON public.ai_response_cache;
DROP POLICY IF EXISTS "no anon access to ai_usage_log" ON public.ai_usage_log;

GRANT ALL ON public.ai_response_cache TO service_role;
GRANT ALL ON public.ai_usage_log TO service_role;
