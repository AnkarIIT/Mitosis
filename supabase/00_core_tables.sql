-- =============================================================================
--  00_core_tables.sql  -  Core user data tables for NEET Mitosis
-- =============================================================================
--  Run this FIRST in the Supabase SQL Editor before any other migrations.
--  Creates all user-scoped tables with proper RLS policies.
--
--  Tables created:
--    * profiles              : synced from local auth (already in 04_user_profiles.sql)
--    * quiz_attempts         : quiz/test attempt records
--    * topic_progress        : per-topic mastery tracking
--    * bookmarks             : saved questions for review
--    * error_book            : incorrect questions for spaced review
--    * spaced_repetition     : SM-2 scheduling cards
--    * flashcards            : user-created + AI-generated flashcards
--    * daily_goals           : daily question targets
--    * dpp_sets              : Daily Practice Paper sets
--    * dpp_questions         : questions within DPP sets
--    * quiz_sessions         : in-progress quiz save/resume
--    * evaluations           : test evaluations/results
--    * chats                 : AI tutor conversation history
--
--  Security: all tables have RLS with user_id isolation.
--  Service role has full access for edge functions.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- Helper: SECURITY DEFINER function for auth.uid() in RLS policies
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.current_user_id()
RETURNS UUID AS $$
  SELECT auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- ---------------------------------------------------------------------------
-- 1. quiz_attempts
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.quiz_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    topic_id TEXT NOT NULL,
    subject TEXT NOT NULL,
    test_type TEXT NOT NULL DEFAULT 'topic',
    subject_scores JSONB,
    score INTEGER NOT NULL DEFAULT 0,
    incorrect_count INTEGER NOT NULL DEFAULT 0,
    total_questions INTEGER NOT NULL DEFAULT 0,
    time_spent_seconds INTEGER NOT NULL DEFAULT 0,
    attempted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    selected_answers JSONB NOT NULL DEFAULT '[]',
    raw_score INTEGER,
    max_marks INTEGER,
    seed INTEGER,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Updated_at trigger
DROP TRIGGER IF EXISTS quiz_attempts_updated_at ON public.quiz_attempts;
CREATE TRIGGER quiz_attempts_updated_at
  BEFORE UPDATE ON public.quiz_attempts
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Unique index for upsert conflict target (user_id, attempted_at)
-- Clean duplicates using ROW_NUMBER (keeps newest by updated_at)
DELETE FROM public.quiz_attempts a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, attempted_at ORDER BY updated_at DESC
    ) as rn FROM public.quiz_attempts
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS quiz_attempts_user_attempted_uidx
  ON public.quiz_attempts(user_id, attempted_at);

-- RLS
ALTER TABLE public.quiz_attempts ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "quiz_attempts: users read own" ON public.quiz_attempts;
CREATE POLICY "quiz_attempts: users read own"
  ON public.quiz_attempts FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "quiz_attempts: users insert own" ON public.quiz_attempts;
CREATE POLICY "quiz_attempts: users insert own"
  ON public.quiz_attempts FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "quiz_attempts: users update own" ON public.quiz_attempts;
CREATE POLICY "quiz_attempts: users update own"
  ON public.quiz_attempts FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "quiz_attempts: users delete own" ON public.quiz_attempts;
CREATE POLICY "quiz_attempts: users delete own"
  ON public.quiz_attempts FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quiz_attempts TO authenticated;
GRANT ALL ON public.quiz_attempts TO service_role;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user_topic ON public.quiz_attempts(user_id, topic_id);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user_subject ON public.quiz_attempts(user_id, subject);
CREATE INDEX IF NOT EXISTS idx_quiz_attempts_user_attempted ON public.quiz_attempts(user_id, attempted_at DESC);

-- ---------------------------------------------------------------------------
-- 2. topic_progress
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.topic_progress (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    topic_id TEXT NOT NULL,
    questions_attempted INTEGER NOT NULL DEFAULT 0,
    questions_correct INTEGER NOT NULL DEFAULT 0,
    time_spent_seconds INTEGER NOT NULL DEFAULT 0,
    average_time_seconds REAL NOT NULL DEFAULT 0.0,
    last_attempted TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS topic_progress_updated_at ON public.topic_progress;
CREATE TRIGGER topic_progress_updated_at
  BEFORE UPDATE ON public.topic_progress
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DELETE FROM public.topic_progress a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, topic_id ORDER BY updated_at DESC
    ) as rn FROM public.topic_progress
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS topic_progress_user_topic_uidx
  ON public.topic_progress(user_id, topic_id);

ALTER TABLE public.topic_progress ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "topic_progress: users read own" ON public.topic_progress;
CREATE POLICY "topic_progress: users read own"
  ON public.topic_progress FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "topic_progress: users insert own" ON public.topic_progress;
CREATE POLICY "topic_progress: users insert own"
  ON public.topic_progress FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "topic_progress: users update own" ON public.topic_progress;
CREATE POLICY "topic_progress: users update own"
  ON public.topic_progress FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "topic_progress: users delete own" ON public.topic_progress;
CREATE POLICY "topic_progress: users delete own"
  ON public.topic_progress FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.topic_progress TO authenticated;
GRANT ALL ON public.topic_progress TO service_role;

CREATE INDEX IF NOT EXISTS idx_topic_progress_user ON public.topic_progress(user_id);

-- ---------------------------------------------------------------------------
-- 3. bookmarks
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    question_id TEXT NOT NULL,
    subject TEXT NOT NULL,
    topic_id TEXT NOT NULL,
    bookmarked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS bookmarks_updated_at ON public.bookmarks;
CREATE TRIGGER bookmarks_updated_at
  BEFORE UPDATE ON public.bookmarks
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DELETE FROM public.bookmarks a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, question_id ORDER BY updated_at DESC
    ) as rn FROM public.bookmarks
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS bookmarks_user_question_uidx
  ON public.bookmarks(user_id, question_id);

ALTER TABLE public.bookmarks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "bookmarks: users read own" ON public.bookmarks;
CREATE POLICY "bookmarks: users read own"
  ON public.bookmarks FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "bookmarks: users insert own" ON public.bookmarks;
CREATE POLICY "bookmarks: users insert own"
  ON public.bookmarks FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "bookmarks: users update own" ON public.bookmarks;
CREATE POLICY "bookmarks: users update own"
  ON public.bookmarks FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "bookmarks: users delete own" ON public.bookmarks;
CREATE POLICY "bookmarks: users delete own"
  ON public.bookmarks FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.bookmarks TO authenticated;
GRANT ALL ON public.bookmarks TO service_role;

CREATE INDEX IF NOT EXISTS idx_bookmarks_user ON public.bookmarks(user_id);

-- ---------------------------------------------------------------------------
-- 4. error_book
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.error_book (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    question_id TEXT NOT NULL,
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    retry_count INTEGER NOT NULL DEFAULT 0,
    is_resolved BOOLEAN NOT NULL DEFAULT FALSE,
    notes TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS error_book_updated_at ON public.error_book;
CREATE TRIGGER error_book_updated_at
  BEFORE UPDATE ON public.error_book
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DELETE FROM public.error_book a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, question_id ORDER BY updated_at DESC
    ) as rn FROM public.error_book
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS error_book_user_question_uidx
  ON public.error_book(user_id, question_id);

ALTER TABLE public.error_book ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "error_book: users read own" ON public.error_book;
CREATE POLICY "error_book: users read own"
  ON public.error_book FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "error_book: users insert own" ON public.error_book;
CREATE POLICY "error_book: users insert own"
  ON public.error_book FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "error_book: users update own" ON public.error_book;
CREATE POLICY "error_book: users update own"
  ON public.error_book FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "error_book: users delete own" ON public.error_book;
CREATE POLICY "error_book: users delete own"
  ON public.error_book FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.error_book TO authenticated;
GRANT ALL ON public.error_book TO service_role;

CREATE INDEX IF NOT EXISTS idx_error_book_user ON public.error_book(user_id);

-- ---------------------------------------------------------------------------
-- 5. spaced_repetition
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.spaced_repetition (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    question_id TEXT NOT NULL,
    box INTEGER NOT NULL DEFAULT 0,
    ease_factor REAL NOT NULL DEFAULT 2.5,
    interval_days INTEGER NOT NULL DEFAULT 0,
    repetitions INTEGER NOT NULL DEFAULT 0,
    lapses INTEGER NOT NULL DEFAULT 0,
    due_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_reviewed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS spaced_repetition_updated_at ON public.spaced_repetition;
CREATE TRIGGER spaced_repetition_updated_at
  BEFORE UPDATE ON public.spaced_repetition
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DELETE FROM public.spaced_repetition a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, question_id ORDER BY updated_at DESC
    ) as rn FROM public.spaced_repetition
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS spaced_repetition_user_question_uidx
  ON public.spaced_repetition(user_id, question_id);

ALTER TABLE public.spaced_repetition ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "spaced_repetition: users read own" ON public.spaced_repetition;
CREATE POLICY "spaced_repetition: users read own"
  ON public.spaced_repetition FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "spaced_repetition: users insert own" ON public.spaced_repetition;
CREATE POLICY "spaced_repetition: users insert own"
  ON public.spaced_repetition FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "spaced_repetition: users update own" ON public.spaced_repetition;
CREATE POLICY "spaced_repetition: users update own"
  ON public.spaced_repetition FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "spaced_repetition: users delete own" ON public.spaced_repetition;
CREATE POLICY "spaced_repetition: users delete own"
  ON public.spaced_repetition FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.spaced_repetition TO authenticated;
GRANT ALL ON public.spaced_repetition TO service_role;

CREATE INDEX IF NOT EXISTS idx_spaced_repetition_user_due ON public.spaced_repetition(user_id, due_at);
CREATE INDEX IF NOT EXISTS idx_spaced_repetition_user ON public.spaced_repetition(user_id);

-- ---------------------------------------------------------------------------
-- 6. flashcards
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.flashcards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    front TEXT NOT NULL,
    back TEXT NOT NULL,
    subject TEXT NOT NULL,
    topic_id TEXT DEFAULT '',
    image_url TEXT,
    chapter_id TEXT DEFAULT '',
    ncert_reference TEXT DEFAULT '',
    source_page INTEGER DEFAULT 0,
    difficulty TEXT NOT NULL DEFAULT 'Medium',
    is_generated BOOLEAN NOT NULL DEFAULT FALSE,
    box INTEGER NOT NULL DEFAULT 0,
    ease_factor REAL NOT NULL DEFAULT 2.5,
    interval_days INTEGER NOT NULL DEFAULT 0,
    repetitions INTEGER NOT NULL DEFAULT 0,
    lapses INTEGER NOT NULL DEFAULT 0,
    due_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS flashcards_updated_at ON public.flashcards;
CREATE TRIGGER flashcards_updated_at
  BEFORE UPDATE ON public.flashcards
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Flashcards use (user_id, id) as composite key - no dedup needed
ALTER TABLE public.flashcards ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "flashcards: users read own" ON public.flashcards;
CREATE POLICY "flashcards: users read own"
  ON public.flashcards FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "flashcards: users insert own" ON public.flashcards;
CREATE POLICY "flashcards: users insert own"
  ON public.flashcards FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "flashcards: users update own" ON public.flashcards;
CREATE POLICY "flashcards: users update own"
  ON public.flashcards FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "flashcards: users delete own" ON public.flashcards;
CREATE POLICY "flashcards: users delete own"
  ON public.flashcards FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.flashcards TO authenticated;
GRANT ALL ON public.flashcards TO service_role;

CREATE INDEX IF NOT EXISTS idx_flashcards_user ON public.flashcards(user_id);
CREATE INDEX IF NOT EXISTS idx_flashcards_user_due ON public.flashcards(user_id, due_at);
CREATE INDEX IF NOT EXISTS idx_flashcards_user_subject ON public.flashcards(user_id, subject);

-- ---------------------------------------------------------------------------
-- 7. daily_goals
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.daily_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    target INTEGER NOT NULL DEFAULT 50,
    completed INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'missed')),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS daily_goals_updated_at ON public.daily_goals;
CREATE TRIGGER daily_goals_updated_at
  BEFORE UPDATE ON public.daily_goals
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DELETE FROM public.daily_goals a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, date ORDER BY updated_at DESC
    ) as rn FROM public.daily_goals
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS daily_goals_user_date_uidx
  ON public.daily_goals(user_id, date);

ALTER TABLE public.daily_goals ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "daily_goals: users read own" ON public.daily_goals;
CREATE POLICY "daily_goals: users read own"
  ON public.daily_goals FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "daily_goals: users insert own" ON public.daily_goals;
CREATE POLICY "daily_goals: users insert own"
  ON public.daily_goals FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "daily_goals: users update own" ON public.daily_goals;
CREATE POLICY "daily_goals: users update own"
  ON public.daily_goals FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "daily_goals: users delete own" ON public.daily_goals;
CREATE POLICY "daily_goals: users delete own"
  ON public.daily_goals FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.daily_goals TO authenticated;
GRANT ALL ON public.daily_goals TO service_role;

CREATE INDEX IF NOT EXISTS idx_daily_goals_user ON public.daily_goals(user_id);

-- ---------------------------------------------------------------------------
-- 8. dpp_sets
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.dpp_sets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    subject TEXT NOT NULL,
    chapter_id TEXT,
    topic_id TEXT,
    total_questions INTEGER NOT NULL DEFAULT 0,
    duration_minutes INTEGER,
    correct_count INTEGER NOT NULL DEFAULT 0,
    incorrect_count INTEGER NOT NULL DEFAULT 0,
    unattempted_count INTEGER NOT NULL DEFAULT 0,
    time_spent_seconds INTEGER NOT NULL DEFAULT 0,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS dpp_sets_updated_at ON public.dpp_sets;
CREATE TRIGGER dpp_sets_updated_at
  BEFORE UPDATE ON public.dpp_sets
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DELETE FROM public.dpp_sets a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, date, subject ORDER BY updated_at DESC
    ) as rn FROM public.dpp_sets
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS dpp_sets_user_date_subject_uidx
  ON public.dpp_sets(user_id, date, subject);

ALTER TABLE public.dpp_sets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dpp_sets: users read own" ON public.dpp_sets;
CREATE POLICY "dpp_sets: users read own"
  ON public.dpp_sets FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "dpp_sets: users insert own" ON public.dpp_sets;
CREATE POLICY "dpp_sets: users insert own"
  ON public.dpp_sets FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "dpp_sets: users update own" ON public.dpp_sets;
CREATE POLICY "dpp_sets: users update own"
  ON public.dpp_sets FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "dpp_sets: users delete own" ON public.dpp_sets;
CREATE POLICY "dpp_sets: users delete own"
  ON public.dpp_sets FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.dpp_sets TO authenticated;
GRANT ALL ON public.dpp_sets TO service_role;

CREATE INDEX IF NOT EXISTS idx_dpp_sets_user ON public.dpp_sets(user_id);
CREATE INDEX IF NOT EXISTS idx_dpp_sets_user_date ON public.dpp_sets(user_id, date DESC);

-- ---------------------------------------------------------------------------
-- 9. dpp_questions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.dpp_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    dpp_set_id UUID NOT NULL REFERENCES public.dpp_sets(id) ON DELETE CASCADE,
    question_id TEXT NOT NULL,
    subject TEXT NOT NULL,
    chapter TEXT NOT NULL,
    topic TEXT NOT NULL,
    topic_id TEXT NOT NULL,
    difficulty TEXT NOT NULL,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL,
    correct_answer TEXT NOT NULL,
    explanation TEXT,
    year INTEGER,
    source TEXT NOT NULL DEFAULT 'dpp',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.dpp_questions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "dpp_questions: users read own" ON public.dpp_questions;
CREATE POLICY "dpp_questions: users read own"
  ON public.dpp_questions FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "dpp_questions: users insert own" ON public.dpp_questions;
CREATE POLICY "dpp_questions: users insert own"
  ON public.dpp_questions FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "dpp_questions: users update own" ON public.dpp_questions;
CREATE POLICY "dpp_questions: users update own"
  ON public.dpp_questions FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "dpp_questions: users delete own" ON public.dpp_questions;
CREATE POLICY "dpp_questions: users delete own"
  ON public.dpp_questions FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.dpp_questions TO authenticated;
GRANT ALL ON public.dpp_questions TO service_role;

CREATE INDEX IF NOT EXISTS idx_dpp_questions_set ON public.dpp_questions(dpp_set_id);
CREATE INDEX IF NOT EXISTS idx_dpp_questions_user ON public.dpp_questions(user_id);

-- ---------------------------------------------------------------------------
-- 10. quiz_sessions
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.quiz_sessions (
    session_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    topic_id TEXT NOT NULL,
    subject TEXT NOT NULL,
    test_type TEXT NOT NULL DEFAULT 'topic',
    quiz_mode TEXT NOT NULL DEFAULT 'practice',
    time_limit_seconds INTEGER NOT NULL DEFAULT 0,
    seed INTEGER NOT NULL,
    current_index INTEGER NOT NULL DEFAULT 0,
    selected_answers JSONB NOT NULL DEFAULT '{}',
    answer_results JSONB NOT NULL DEFAULT '{}',
    time_spent_per_question JSONB NOT NULL DEFAULT '{}',
    flagged_questions JSONB NOT NULL DEFAULT '[]',
    visited_questions JSONB NOT NULL DEFAULT '[]',
    score INTEGER NOT NULL DEFAULT 0,
    incorrect_count INTEGER NOT NULL DEFAULT 0,
    elapsed_seconds INTEGER NOT NULL DEFAULT 0,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    question_ids JSONB NOT NULL DEFAULT '[]',
    question_data JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS quiz_sessions_updated_at ON public.quiz_sessions;
CREATE TRIGGER quiz_sessions_updated_at
  BEFORE UPDATE ON public.quiz_sessions
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DELETE FROM public.quiz_sessions a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, session_id ORDER BY updated_at DESC
    ) as rn FROM public.quiz_sessions
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS quiz_sessions_user_session_uidx
  ON public.quiz_sessions(user_id, session_id);

ALTER TABLE public.quiz_sessions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "quiz_sessions: users read own" ON public.quiz_sessions;
CREATE POLICY "quiz_sessions: users read own"
  ON public.quiz_sessions FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "quiz_sessions: users insert own" ON public.quiz_sessions;
CREATE POLICY "quiz_sessions: users insert own"
  ON public.quiz_sessions FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "quiz_sessions: users update own" ON public.quiz_sessions;
CREATE POLICY "quiz_sessions: users update own"
  ON public.quiz_sessions FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "quiz_sessions: users delete own" ON public.quiz_sessions;
CREATE POLICY "quiz_sessions: users delete own"
  ON public.quiz_sessions FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.quiz_sessions TO authenticated;
GRANT ALL ON public.quiz_sessions TO service_role;

CREATE INDEX IF NOT EXISTS idx_quiz_sessions_user ON public.quiz_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_quiz_sessions_user_updated ON public.quiz_sessions(user_id, updated_at DESC);

-- ---------------------------------------------------------------------------
-- 11. evaluations
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    test_id UUID,
    test_type TEXT NOT NULL,
    subject TEXT NOT NULL,
    score INTEGER NOT NULL DEFAULT 0,
    total_questions INTEGER NOT NULL DEFAULT 0,
    correct_count INTEGER NOT NULL DEFAULT 0,
    incorrect_count INTEGER NOT NULL DEFAULT 0,
    time_spent_seconds INTEGER NOT NULL DEFAULT 0,
    subject_scores JSONB,
    question_results JSONB,
    evaluated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS evaluations_updated_at ON public.evaluations;
CREATE TRIGGER evaluations_updated_at
  BEFORE UPDATE ON public.evaluations
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.evaluations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "evaluations: users read own" ON public.evaluations;
CREATE POLICY "evaluations: users read own"
  ON public.evaluations FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "evaluations: users insert own" ON public.evaluations;
CREATE POLICY "evaluations: users insert own"
  ON public.evaluations FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "evaluations: users update own" ON public.evaluations;
CREATE POLICY "evaluations: users update own"
  ON public.evaluations FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "evaluations: users delete own" ON public.evaluations;
CREATE POLICY "evaluations: users delete own"
  ON public.evaluations FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.evaluations TO authenticated;
GRANT ALL ON public.evaluations TO service_role;

CREATE INDEX IF NOT EXISTS idx_evaluations_user ON public.evaluations(user_id);
CREATE INDEX IF NOT EXISTS idx_evaluations_user_evaluated ON public.evaluations(user_id, evaluated_at DESC);

-- ---------------------------------------------------------------------------
-- 12. chats
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_user BOOLEAN NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    session_id TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP TRIGGER IF EXISTS chats_updated_at ON public.chats;
CREATE TRIGGER chats_updated_at
  BEFORE UPDATE ON public.chats
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.chats ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chats: users read own" ON public.chats;
CREATE POLICY "chats: users read own"
  ON public.chats FOR SELECT
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "chats: users insert own" ON public.chats;
CREATE POLICY "chats: users insert own"
  ON public.chats FOR INSERT
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "chats: users update own" ON public.chats;
CREATE POLICY "chats: users update own"
  ON public.chats FOR UPDATE
  USING (user_id = public.current_user_id())
  WITH CHECK (user_id = public.current_user_id());

DROP POLICY IF EXISTS "chats: users delete own" ON public.chats;
CREATE POLICY "chats: users delete own"
  ON public.chats FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, UPDATE, DELETE ON public.chats TO authenticated;
GRANT ALL ON public.chats TO service_role;

CREATE INDEX IF NOT EXISTS idx_chats_user ON public.chats(user_id);
CREATE INDEX IF NOT EXISTS idx_chats_user_timestamp ON public.chats(user_id, timestamp);

-- ---------------------------------------------------------------------------
-- Verification
-- ---------------------------------------------------------------------------
SELECT
    schemaname,
    tablename,
    rowsecurity,
    CASE WHEN rowsecurity THEN 'RLS ENABLED' ELSE 'RLS DISABLED' END as rls_status
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'quiz_attempts', 'topic_progress', 'bookmarks', 'error_book',
    'spaced_repetition', 'flashcards', 'daily_goals', 'dpp_sets',
    'dpp_questions', 'quiz_sessions', 'evaluations', 'chats'
  )
ORDER BY tablename;