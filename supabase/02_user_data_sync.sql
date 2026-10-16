-- =============================================================================
--  02_user_data_sync.sql  -  Cloud sync schema for user data (timestamp-first)
-- =============================================================================
--  Run this AFTER 00_core_tables.sql. This migration adds the `updated_at`
--  columns and unique indexes for timestamp-first two-way reconciliation.
--
--  Note: 00_core_tables.sql already creates the tables with proper structure.
--  This migration is idempotent and safe to re-run.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. quiz_attempts
-- ---------------------------------------------------------------------------
ALTER TABLE public.quiz_attempts
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Collapse any legacy duplicate natural keys (keep the newest row).
-- Uses ROW_NUMBER() for safe deduplication.
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

-- ---------------------------------------------------------------------------
-- 2. topic_progress
-- ---------------------------------------------------------------------------
ALTER TABLE public.topic_progress
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

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

-- ---------------------------------------------------------------------------
-- 3. bookmarks
-- ---------------------------------------------------------------------------
ALTER TABLE public.bookmarks
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

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

-- ---------------------------------------------------------------------------
-- 4. error_book
-- ---------------------------------------------------------------------------
ALTER TABLE public.error_book
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

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

-- ---------------------------------------------------------------------------
-- 5. spaced_repetition
-- ---------------------------------------------------------------------------
ALTER TABLE public.spaced_repetition
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

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

-- ---------------------------------------------------------------------------
-- 6. daily_goals
-- ---------------------------------------------------------------------------
ALTER TABLE public.daily_goals
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

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

-- ---------------------------------------------------------------------------
-- 7. dpp_sets
-- ---------------------------------------------------------------------------
ALTER TABLE public.dpp_sets
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

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

-- ---------------------------------------------------------------------------
-- 8. quiz_sessions
-- ---------------------------------------------------------------------------
ALTER TABLE public.quiz_sessions
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

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

-- ---------------------------------------------------------------------------
-- Verification
-- ---------------------------------------------------------------------------
SELECT tablename, indexname
FROM pg_indexes
WHERE tablename IN (
  'quiz_attempts', 'topic_progress', 'bookmarks', 'error_book',
  'spaced_repetition', 'daily_goals', 'dpp_sets', 'quiz_sessions'
)
  AND indexname LIKE '%_uidx'
ORDER BY tablename;
