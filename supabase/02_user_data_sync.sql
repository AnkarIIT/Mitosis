-- =============================================================================
--  02_user_data_sync.sql  -  Cloud sync schema for user data (timestamp-first)
-- =============================================================================
--  Run this in the Supabase SQL Editor. It upgrades the three user-data tables
--  that the Flutter app syncs (quiz_attempts / topic_progress / bookmarks) to
--  support timestamp-first two-way reconciliation:
--
--    * every row carries an `updated_at` TIMESTAMPTZ the app uses to decide
--      which side of a conflict is newer (NOT a trigger - the app stamps the
--      authoritative timestamp on each write),
--    * unique conflict targets matching the app's upserts:
--        quiz_attempts  -> (user_id, attempted_at)
--        topic_progress -> (user_id, topic_id)
--        bookmarks      -> (user_id, question_id)
--
--  Idempotent: safe to re-run.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. quiz_attempts
-- ---------------------------------------------------------------------------
ALTER TABLE quiz_attempts
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- Collapse any legacy duplicate natural keys (keep the newest row).
DELETE FROM quiz_attempts a
USING quiz_attempts b
WHERE a.user_id = b.user_id
  AND a.attempted_at IS NOT DISTINCT FROM b.attempted_at
  AND a.updated_at < b.updated_at
  AND a.ctid < b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS quiz_attempts_user_attempted_uidx
  ON quiz_attempts(user_id, attempted_at);

-- ---------------------------------------------------------------------------
-- 2. topic_progress
-- ---------------------------------------------------------------------------
ALTER TABLE topic_progress
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DELETE FROM topic_progress a
USING topic_progress b
WHERE a.user_id = b.user_id
  AND a.topic_id IS NOT DISTINCT FROM b.topic_id
  AND a.updated_at < b.updated_at
  AND a.ctid < b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS topic_progress_user_topic_uidx
  ON topic_progress(user_id, topic_id);

-- ---------------------------------------------------------------------------
-- 3. bookmarks
-- ---------------------------------------------------------------------------
ALTER TABLE bookmarks
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DELETE FROM bookmarks a
USING bookmarks b
WHERE a.user_id = b.user_id
  AND a.question_id IS NOT DISTINCT FROM b.question_id
  AND a.updated_at < b.updated_at
  AND a.ctid < b.ctid;

CREATE UNIQUE INDEX IF NOT EXISTS bookmarks_user_question_uidx
  ON bookmarks(user_id, question_id);

-- ---------------------------------------------------------------------------
-- Verification
-- ---------------------------------------------------------------------------
SELECT tablename, indexname
FROM pg_indexes
WHERE tablename IN ('quiz_attempts', 'topic_progress', 'bookmarks')
  AND indexname LIKE '%_uidx'
ORDER BY tablename;
