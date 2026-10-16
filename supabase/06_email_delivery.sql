-- =============================================================================
--  06_email_delivery.sql  -  outbound email audit + rate limiting
-- =============================================================================
--  Backing table for the `send-email` Supabase Edge Function.
--
--  The client enforces a per-account resend cooldown in its local SQLite file.
--  That is not sufficient: an offline-first app's local store is under the
--  user's control, so reinstalling or clearing data resets every counter. The
--  only trustworthy limit is server-side, which is what this table provides.
--
--  Two independent ceilings are enforced by the function:
--    * per identity (session)  — stops one session from driving bulk mail
--    * per recipient            — stops rotating sessions flooding one mailbox
--
--  Security: service_role only. The client never reads or writes this table.
-- =============================================================================

CREATE TABLE IF NOT EXISTS public.email_send_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    identity TEXT NOT NULL,
    recipient TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Supports both counting queries in the function.
CREATE INDEX IF NOT EXISTS idx_email_log_identity_time
    ON public.email_send_log(identity, created_at);
CREATE INDEX IF NOT EXISTS idx_email_log_recipient_time
    ON public.email_send_log(recipient, created_at);
CREATE INDEX IF NOT EXISTS idx_email_log_created_at
    ON public.email_send_log(created_at);

-- ---------------------------------------------------------------------------
-- Retention
-- ---------------------------------------------------------------------------
-- Rows older than the rate-limit window cannot affect any decision, so they are
-- pure storage growth. Without this the table grows without limit on a busy
-- install and slows the very count that gates sending.
--
-- Safe to run on a schedule (pg_cron, or a Supabase scheduled function).
-- Every row keeps its function: it is deleted only once the window has moved
-- past it.
CREATE OR REPLACE FUNCTION public.prune_email_send_log()
RETURNS INTEGER AS $$
DECLARE
    removed INTEGER;
BEGIN
    DELETE FROM public.email_send_log
    WHERE created_at < NOW() - INTERVAL '2 days';
    GET DIAGNOSTICS removed = ROW_COUNT;
    RETURN removed;
END;
$$ LANGUAGE plpgsql;

-- By default PostgreSQL grants EXECUTE on a new function to PUBLIC. This one is
-- a DELETE against the send log, so it is only safe today because RLS happens
-- to block anon/authenticated. That coupling is one permissive policy away from
-- a destructive RPC callable by any signed-in user. Pin the blast radius now.
REVOKE ALL ON FUNCTION public.prune_email_send_log() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.prune_email_send_log() TO service_role;

-- ---------------------------------------------------------------------------
-- Row Level Security — service_role only
-- ---------------------------------------------------------------------------
-- A caller must not be able to read the send log: it reveals which addresses
-- have accounts and when they were mailed, which is an enumeration oracle.
ALTER TABLE public.email_send_log ENABLE ROW LEVEL SECURITY;

-- No anon or authenticated policy is created, so the default is deny.
GRANT ALL ON public.email_send_log TO service_role;