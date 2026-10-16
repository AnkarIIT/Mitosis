-- =============================================================================
--  01_content_catalog.sql  -  NEET Mitosis content catalog for Supabase
-- =============================================================================
--  Run this in the Supabase SQL Editor before enabling the app's content sync.
--
--  What it provides:
--    * user_roles  : admin/educator/student role gate for write operations
--    * questions   : the master NEET question bank served to the Flutter app
--    * tests       : published test-series manifests (NTA / standard patterns)
--    * RLS policies: anyone (even unauthenticated guests) can READ active,
--                    published content; only admins/educators can write.
--
--  The Flutter app downloads `questions` (public read), stores them in local
--  Drift/SQLite, and runs the NTA engine 100% offline.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 0. Admin / educator roles
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_roles (
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    role VARCHAR(20) NOT NULL CHECK (role IN ('admin', 'educator', 'student')),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Helper function to check if current user is admin/educator without recursion
-- SET search_path pins name resolution to public; a SECURITY DEFINER function
-- without it can be subverted by any writable schema earlier in the path.
CREATE OR REPLACE FUNCTION public.is_admin_or_educator()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role IN ('admin', 'educator')
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.user_roles
    WHERE user_id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp;

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

-- Only admins can manage roles. Educators must never be able to promote
-- themselves or another account by writing this table.
DROP POLICY IF EXISTS "user_roles admin full access" ON public.user_roles;
DROP POLICY IF EXISTS "user_roles admin manage" ON public.user_roles;
CREATE POLICY "user_roles admin manage" ON public.user_roles
  FOR ALL
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "user_roles self read" ON public.user_roles;
CREATE POLICY "user_roles self read" ON public.user_roles
  FOR SELECT
  USING (user_id = auth.uid());

-- Explicit grants. RLS is not sufficient on its own: without a grant, the
-- default is to deny, and without an explicit policy drop/recreate the table
-- had no declared privileges.
GRANT SELECT ON public.user_roles TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_roles TO service_role;

-- ---------------------------------------------------------------------------
-- Bootstrap for the first admin
-- ---------------------------------------------------------------------------
-- `user_roles` is only writable by an existing admin, and the table ships
-- empty. A fresh deploy therefore has ZERO admins and ZERO educators, and
-- nobody can ever write the question catalog through PostgREST — the deployment
-- looks healthy and is permanently read-only.
--
-- There is no safe in-migration bootstrap: this file is applied by both a
-- privileged SQL-editor paste and an automated runner, and seeding a hard-coded
-- user id would be both non-idempotent and unauditable.
--
-- Promote the first admin ONCE, out of band, after applying the migrations:
--
--   INSERT INTO public.user_roles (user_id, role)
--   VALUES ('<auth.users.id>', 'admin')
--   ON CONFLICT (user_id, role) DO NOTHING;
--
-- Until that is done every write policy above evaluates false for every caller.
-- The helper below makes the state checkable: `SELECT public.count_admins();`
-- returns 0 on a deployment that skipped this step.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.count_admins()
RETURNS INTEGER
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
    SELECT COUNT(*)::INTEGER FROM public.user_roles WHERE role = 'admin';
$$;

REVOKE ALL ON FUNCTION public.count_admins() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.count_admins() TO service_role;

-- ---------------------------------------------------------------------------
-- 1. Question catalog
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    subject VARCHAR(20) NOT NULL CHECK (subject IN ('Physics', 'Chemistry', 'Botany', 'Zoology')),
    chapter_id VARCHAR(100) NOT NULL,
    chapter_name VARCHAR(200) NOT NULL,
    topic_name VARCHAR(200),
    question_text TEXT NOT NULL,
    question_image_url TEXT,
    options JSONB NOT NULL, -- {"A": "...", "B": "...", "C": "...", "D": "..."}
    correct_option CHAR(1) NOT NULL CHECK (correct_option IN ('A', 'B', 'C', 'D')),
    explanation TEXT,
    ncert_reference VARCHAR(150),
    difficulty VARCHAR(10) CHECK (difficulty IN ('Easy', 'Medium', 'Hard')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Touch updated_at on every write so delta syncs pick changes up reliably.
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ⚠️ This function is also referenced by 00_core_tables.sql, which documents
-- itself as "run this FIRST". That file creates 11 triggers calling
-- public.set_updated_at(), so on a fresh database 00_core_tables.sql FAILED
-- outright with "function public.set_updated_at() does not exist".
--
-- This file is therefore applied first regardless of filename order, so the
-- helper exists before any trigger that depends on it.
DROP TRIGGER IF EXISTS questions_updated_at ON public.questions;
CREATE TRIGGER questions_updated_at
  BEFORE UPDATE ON public.questions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 2. Test series catalog
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.tests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(250) NOT NULL,
    description TEXT,
    pattern_type VARCHAR(30) DEFAULT 'NTA_200_Q', -- 'NTA_200_Q' | 'STANDARD_180_Q'
    total_questions INT DEFAULT 200,
    duration_minutes INT DEFAULT 200,
    total_marks INT DEFAULT 720,
    question_ids JSONB NOT NULL, -- ordered array of question UUIDs
    is_published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

DROP TRIGGER IF EXISTS tests_updated_at ON public.tests;
CREATE TRIGGER tests_updated_at
  BEFORE UPDATE ON public.tests
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ---------------------------------------------------------------------------
-- 3. Indexes for delta-sync watermarks and content lookup
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_questions_updated_at ON public.questions(updated_at);
-- Composite index matching the client's delta page query:
--   WHERE is_active = true AND updated_at <= :boundary
--     AND (updated_at > :cursor_ts OR (updated_at = :cursor_ts AND id > :cursor_id))
--   ORDER BY updated_at, id LIMIT 1000
-- The single-column updated_at index cannot serve both the predicate and the
-- ordering, so Postgres sorted every page in memory. This index makes the scan
-- index-ordered end to end.
CREATE INDEX IF NOT EXISTS idx_questions_sync_cursor
  ON public.questions(updated_at, id)
  WHERE is_active = true;
-- Supports the soft-delete reconciliation pass (is_active = false, updated_at <= boundary).
CREATE INDEX IF NOT EXISTS idx_questions_inactive_updated_at
  ON public.questions(updated_at)
  WHERE is_active = false;
CREATE INDEX IF NOT EXISTS idx_questions_subject ON public.questions(subject);
CREATE INDEX IF NOT EXISTS idx_questions_chapter_id ON public.questions(chapter_id);
CREATE INDEX IF NOT EXISTS idx_tests_updated_at ON public.tests(updated_at);
-- The anonymous read path is `SELECT ... WHERE is_published = true`, and the
-- policy filters on exactly this column. Without the index every guest catalog
-- read is a full scan plus heap fetches.
CREATE INDEX IF NOT EXISTS idx_tests_is_published ON public.tests(is_published);

-- Deferred foreign key: public.evaluations.test_id was declared as a bare UUID
-- with no REFERENCES and no index, so it could point at nothing and any join
-- on it was a sequential scan. It cannot be declared inline in
-- 00_core_tables.sql because public.tests does not exist until this file runs.
ALTER TABLE public.evaluations
  DROP CONSTRAINT IF EXISTS evaluations_test_id_fkey;
ALTER TABLE public.evaluations
  ADD CONSTRAINT evaluations_test_id_fkey
  FOREIGN KEY (test_id) REFERENCES public.tests(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_evaluations_test_id
  ON public.evaluations(test_id)
  WHERE test_id IS NOT NULL;

-- ---------------------------------------------------------------------------
-- 4. Row Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tests ENABLE ROW LEVEL SECURITY;

-- Everyone (including anonymous guests) can read active / published content.
DROP POLICY IF EXISTS "Public read access for questions" ON public.questions;
CREATE POLICY "Public read access for questions"
  ON public.questions FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Public read access for published tests" ON public.tests;
CREATE POLICY "Public read access for published tests"
  ON public.tests FOR SELECT USING (is_published = true);

-- Only registered admins / educators may write the catalog.
DROP POLICY IF EXISTS "Admin write access for questions" ON public.questions;
CREATE POLICY "Admin write access for questions"
  ON public.questions FOR ALL
  USING (public.is_admin_or_educator())
  WITH CHECK (public.is_admin_or_educator());

DROP POLICY IF EXISTS "Admin write access for tests" ON public.tests;
CREATE POLICY "Admin write access for tests"
  ON public.tests FOR ALL
  USING (public.is_admin_or_educator())
  WITH CHECK (public.is_admin_or_educator());

-- ---------------------------------------------------------------------------
-- 5. Grants (anon reads public catalog; authenticated reads; admin writes via
--           the policies above)
-- ---------------------------------------------------------------------------
GRANT SELECT ON public.questions TO anon, authenticated;
GRANT SELECT ON public.tests TO anon, authenticated;
GRANT ALL ON public.questions TO service_role;
GRANT ALL ON public.tests TO service_role;