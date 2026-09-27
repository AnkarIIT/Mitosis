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
ALTER TABLE quiz_attempts
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Collapse any legacy duplicate natural keys (keep the newest row).
-- Uses ROW_NUMBER() for safe deduplication.
DELETE FROM quiz_attempts a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, attempted_at ORDER BY updated_at DESC
    ) as rn FROM quiz_attempts
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS quiz_attempts_user_attempted_uidx
  ON quiz_attempts(user_id, attempted_at);

-- ---------------------------------------------------------------------------
-- 2. topic_progress
-- ---------------------------------------------------------------------------
ALTER TABLE topic_progress
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DELETE FROM topic_progress a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, topic_id ORDER BY updated_at DESC
    ) as rn FROM topic_progress
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS topic_progress_user_topic_uidx
  ON topic_progress(user_id, topic_id);

-- ---------------------------------------------------------------------------
-- 3. bookmarks
-- ---------------------------------------------------------------------------
ALTER TABLE bookmarks
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DELETE FROM bookmarks a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, question_id ORDER BY updated_at DESC
    ) as rn FROM bookmarks
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS bookmarks_user_question_uidx
  ON bookmarks(user_id, question_id);

-- ---------------------------------------------------------------------------
-- 4. error_book
-- ---------------------------------------------------------------------------
ALTER TABLE error_book
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DELETE FROM error_book a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, question_id ORDER BY updated_at DESC
    ) as rn FROM error_book
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS error_book_user_question_uidx
  ON error_book(user_id, question_id);

-- ---------------------------------------------------------------------------
-- 5. spaced_repetition
-- ---------------------------------------------------------------------------
ALTER TABLE spaced_repetition
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DELETE FROM spaced_repetition a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, question_id ORDER BY updated_at DESC
    ) as rn FROM spaced_repetition
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS spaced_repetition_user_question_uidx
  ON spaced_repetition(user_id, question_id);

-- ---------------------------------------------------------------------------
-- 6. daily_goals
-- ---------------------------------------------------------------------------
ALTER TABLE daily_goals
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DELETE FROM daily_goals a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, date ORDER BY updated_at DESC
    ) as rn FROM daily_goals
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS daily_goals_user_date_uidx
  ON daily_goals(user_id, date);

-- ---------------------------------------------------------------------------
-- 7. dpp_sets
-- ---------------------------------------------------------------------------
ALTER TABLE dpp_sets
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DELETE FROM dpp_sets a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, date, subject ORDER BY updated_at DESC
    ) as rn FROM dpp_sets
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS dpp_sets_user_date_subject_uidx
  ON dpp_sets(user_id, date, subject);

-- ---------------------------------------------------------------------------
-- 8. quiz_sessions
-- ---------------------------------------------------------------------------
ALTER TABLE quiz_sessions
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DELETE FROM quiz_sessions a
USING (
  SELECT ctid FROM (
    SELECT ctid, ROW_NUMBER() OVER (
      PARTITION BY user_id, session_id ORDER BY updated_at DESC
    ) as rn FROM quiz_sessions
  ) t WHERE t.rn > 1
) b
WHERE a.ctid = b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS quiz_sessions_user_session_uidx
  ON quiz_sessions(user_id, session_id);

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
