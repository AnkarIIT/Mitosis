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

ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_roles are admin/maintainable" ON public.user_roles
  FOR ALL
  USING (auth.uid() IN (
    SELECT user_id FROM public.user_roles WHERE role = 'admin'
  ));

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
CREATE INDEX IF NOT EXISTS idx_questions_subject ON public.questions(subject);
CREATE INDEX IF NOT EXISTS idx_questions_chapter_id ON public.questions(chapter_id);
CREATE INDEX IF NOT EXISTS idx_tests_updated_at ON public.tests(updated_at);

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
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_id = auth.uid() AND role IN ('admin', 'educator')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_id = auth.uid() AND role IN ('admin', 'educator')
    )
  );

DROP POLICY IF EXISTS "Admin write access for tests" ON public.tests;
CREATE POLICY "Admin write access for tests"
  ON public.tests FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_id = auth.uid() AND role IN ('admin', 'educator')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.user_roles
      WHERE user_id = auth.uid() AND role IN ('admin', 'educator')
    )
  );

-- ---------------------------------------------------------------------------
-- 5. Grants (anon reads public catalog; authenticated reads; admin writes via
--           the policies above)
-- ---------------------------------------------------------------------------
GRANT SELECT ON public.questions TO anon, authenticated;
GRANT SELECT ON public.tests TO anon, authenticated;
GRANT ALL ON public.questions TO service_role;
GRANT ALL ON public.tests TO service_role;