-- =============================================================================
--  Supabase Row-Level Security (RLS) Policies for neet_mitos
--  SEC-002 Fix — Run this in the Supabase SQL Editor
--  (Dashboard → SQL Editor → New Query → paste → Run)
-- =============================================================================
--
--  What this does:
--    • Enables RLS on all user-data tables so that even if someone obtains
--      the anon key, they can ONLY read/write their own rows.
--    • The `auth.uid()` function is provided by Supabase Auth and always
--      returns the UUID of the currently-authenticated user.
--
--  Tables covered:
--    quiz_attempts | topic_progress | bookmarks
-- =============================================================================


-- ---------------------------------------------------------------------------
-- 1. quiz_attempts
-- ---------------------------------------------------------------------------
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;

-- Users can only SELECT their own quiz attempts
CREATE POLICY "quiz_attempts: users read own rows"
  ON quiz_attempts
  FOR SELECT
  USING (user_id = auth.uid());

-- Users can only INSERT rows stamped with their own user_id
CREATE POLICY "quiz_attempts: users insert own rows"
  ON quiz_attempts
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- Users can only UPDATE their own rows
CREATE POLICY "quiz_attempts: users update own rows"
  ON quiz_attempts
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Users can only DELETE their own rows
CREATE POLICY "quiz_attempts: users delete own rows"
  ON quiz_attempts
  FOR DELETE
  USING (user_id = auth.uid());


-- ---------------------------------------------------------------------------
-- 2. topic_progress
-- ---------------------------------------------------------------------------
ALTER TABLE topic_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "topic_progress: users read own rows"
  ON topic_progress
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "topic_progress: users insert own rows"
  ON topic_progress
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "topic_progress: users update own rows"
  ON topic_progress
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "topic_progress: users delete own rows"
  ON topic_progress
  FOR DELETE
  USING (user_id = auth.uid());


-- ---------------------------------------------------------------------------
-- 3. bookmarks
-- ---------------------------------------------------------------------------
ALTER TABLE bookmarks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "bookmarks: users read own rows"
  ON bookmarks
  FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "bookmarks: users insert own rows"
  ON bookmarks
  FOR INSERT
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "bookmarks: users update own rows"
  ON bookmarks
  FOR UPDATE
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "bookmarks: users delete own rows"
  ON bookmarks
  FOR DELETE
  USING (user_id = auth.uid());


-- ---------------------------------------------------------------------------
-- Verification — run this after applying policies to confirm they are active
-- ---------------------------------------------------------------------------
SELECT
  schemaname,
  tablename,
  rowsecurity          AS rls_enabled,
  policyname,
  cmd                  AS operation,
  qual                 AS using_expr,
  with_check           AS with_check_expr
FROM pg_policies
WHERE tablename IN ('quiz_attempts', 'topic_progress', 'bookmarks')
ORDER BY tablename, cmd;
