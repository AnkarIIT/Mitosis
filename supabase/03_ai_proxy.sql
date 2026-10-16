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
--  Run with:  node scripts/apply-migrations.mjs
--  (or paste this file into the Supabase SQL Editor).
--
--  NOTE: `supabase db push` does NOT work in this repository. It applies
--  supabase/migrations/*.sql and requires a supabase/config.toml, and neither
--  exists here — the tree is a flat, filename-ordered set of .sql files applied
--  by scripts/apply-migrations.mjs. `supabase db push` against this layout is
--  at best a silent no-op.
--  Idempotent: safe to re-run.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. ai_response_cache
-- ---------------------------------------------------------------------------
-- ⚠️ `scope` exists to stop anonymous callers harvesting the shared cache.
--
-- Previously the cache was keyed on `prompt_hash` alone and readable by any
-- caller that reached the function, so an unauthenticated request could read
-- answers that authenticated users had paid for, and could seed the cache with
-- attacker-chosen content that every later user would then be served.
--
-- `scope` partitions the cache:
--    'shared'  — written by an authenticated user, readable only by
--                authenticated callers.
--    'anon'    — written by an unauthenticated caller. Only readable by
--                unauthenticated callers.
--
-- Both directions are partitioned symmetrically. Reads used to be unscoped for
-- authenticated callers, so an anonymous caller could seed an entry that every
-- signed-in user was then served — the exact poisoning this column exists to
-- prevent.
--
-- Because the two partitions are independent, the unique key MUST include
-- `scope`: with `prompt_hash` alone, the second partition's row is silently
-- dropped by `onConflict: 'prompt_hash', ignoreDuplicates: true`, and one
-- partition permanently starves the other.
CREATE TABLE IF NOT EXISTS public.ai_response_cache (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    prompt_hash TEXT NOT NULL,
    original_prompt TEXT NOT NULL,
    question_id TEXT,
    response TEXT NOT NULL,
    model VARCHAR(50),
    scope VARCHAR(10) NOT NULL DEFAULT 'shared'
        CHECK (scope IN ('shared', 'anon')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT ai_response_cache_prompt_scope_key UNIQUE (prompt_hash, scope)
);

-- Upgrade an already-provisioned table: the original constraint name/lockup is
-- dropped so the composite unique can be created.
ALTER TABLE public.ai_response_cache
    DROP CONSTRAINT IF EXISTS ai_response_cache_prompt_hash_key;

CREATE UNIQUE INDEX IF NOT EXISTS idx_ai_cache_prompt_scope
    ON public.ai_response_cache(prompt_hash, scope);

CREATE INDEX IF NOT EXISTS idx_ai_cache_hash
    ON public.ai_response_cache(prompt_hash);
CREATE INDEX IF NOT EXISTS idx_ai_cache_question_id
    ON public.ai_response_cache(question_id)
    WHERE question_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ai_cache_scope
    ON public.ai_response_cache(scope);

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

-- Retention. The rate limiter only ever counts rows in a 1-hour window, so
-- anything older is dead weight — but without a bound both tables grow without
-- limit and the counting query that gates every paid call gets slower over time.
-- The index below supports the prune; it is NOT itself a cap.
CREATE INDEX IF NOT EXISTS idx_ai_usage_created_at
    ON public.ai_usage_log(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_cache_created_at
    ON public.ai_response_cache(created_at);

-- Prunes usage rows older than 30 days. Run on a schedule (pg_cron or an
-- external job); it is deliberately not scheduled here so the hosting project
-- does not silently acquire a cron dependency.
-- SECURITY DEFINER + pinned search_path: runs as the owner, so it needs both.
CREATE OR REPLACE FUNCTION public.prune_ai_usage_log(
    p_keep_days INTEGER DEFAULT 30
) RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
DECLARE
    removed INTEGER;
BEGIN
    DELETE FROM public.ai_usage_log
    WHERE created_at < NOW() - make_interval(days => p_keep_days);
    GET DIAGNOSTICS removed = ROW_COUNT;
    RETURN removed;
END;
$$;

REVOKE ALL ON FUNCTION public.prune_ai_usage_log(INTEGER) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.prune_ai_usage_log(INTEGER) TO service_role;

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
