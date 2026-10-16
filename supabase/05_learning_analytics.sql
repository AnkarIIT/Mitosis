-- Learning Intelligence analytics. Run after 00_core_tables.sql.
-- Every row is user-owned and protected by auth.uid() RLS.

CREATE TABLE IF NOT EXISTS public.mistake_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  attempt_id UUID REFERENCES public.quiz_attempts(id) ON DELETE SET NULL,
  question_id TEXT NOT NULL,
  topic_id TEXT NOT NULL,
  mistake_type TEXT NOT NULL CHECK (
    mistake_type IN ('concept', 'calculation', 'speed', 'silly', 'unknown')
  ),
  time_seconds REAL NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.retention_reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  topic_id TEXT NOT NULL,
  interval_days INTEGER NOT NULL CHECK (interval_days IN (3, 7, 14)),
  due_at TIMESTAMPTZ NOT NULL,
  checked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  accuracy REAL CHECK (accuracy IS NULL OR (accuracy >= 0 AND accuracy <= 100))
);

ALTER TABLE public.mistake_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.retention_reviews ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mistake_events: users read own" ON public.mistake_events;
CREATE POLICY "mistake_events: users read own"
  ON public.mistake_events FOR SELECT
  USING (user_id = public.current_user_id());
DROP POLICY IF EXISTS "mistake_events: users insert own" ON public.mistake_events;
CREATE POLICY "mistake_events: users insert own"
  ON public.mistake_events FOR INSERT
  WITH CHECK (user_id = public.current_user_id());
DROP POLICY IF EXISTS "mistake_events: users delete own" ON public.mistake_events;
CREATE POLICY "mistake_events: users delete own"
  ON public.mistake_events FOR DELETE
  USING (user_id = public.current_user_id());

DROP POLICY IF EXISTS "retention_reviews: users read own" ON public.retention_reviews;
CREATE POLICY "retention_reviews: users read own"
  ON public.retention_reviews FOR SELECT
  USING (user_id = public.current_user_id());
DROP POLICY IF EXISTS "retention_reviews: users insert own" ON public.retention_reviews;
CREATE POLICY "retention_reviews: users insert own"
  ON public.retention_reviews FOR INSERT
  WITH CHECK (user_id = public.current_user_id());
DROP POLICY IF EXISTS "retention_reviews: users delete own" ON public.retention_reviews;
CREATE POLICY "retention_reviews: users delete own"
  ON public.retention_reviews FOR DELETE
  USING (user_id = public.current_user_id());

GRANT SELECT, INSERT, DELETE ON public.mistake_events TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.retention_reviews TO authenticated;
GRANT ALL ON public.mistake_events, public.retention_reviews TO service_role;

CREATE INDEX IF NOT EXISTS idx_mistake_events_user_topic
  ON public.mistake_events(user_id, topic_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_retention_reviews_user_topic
  ON public.retention_reviews(user_id, topic_id, checked_at DESC);
