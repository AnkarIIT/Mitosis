-- User profiles synced from the Flutter app's local auth.
-- The app upserts here on email/password register & login and on Google sign-in
-- so account details exist in Supabase even though authentication runs locally
-- (offline-first). Authoritative source of truth remains the device DB; this
-- table reflects the latest synced snapshot for cross-device/analytics use.

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    username TEXT,
    full_name TEXT,
    two_factor_enabled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles: users read own rows" ON public.profiles;
CREATE POLICY "profiles: users read own rows"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles: users insert own rows" ON public.profiles;
CREATE POLICY "profiles: users insert own rows"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "profiles: users update own rows" ON public.profiles;
CREATE POLICY "profiles: users update own rows"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "profiles: users delete own rows" ON public.profiles;
CREATE POLICY "profiles: users delete own rows"
    ON public.profiles FOR DELETE
    USING (auth.uid() = id);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.profiles TO service_role;