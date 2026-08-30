# Question Repetition Audit & Fix Plan

## 1. Diagnosis — Do questions repeat across modes?

**Short answer: Yes.**

| Mode | Question source | Sampling / deduplication |
|------|----------------|--------------------------|
| **Topic Quiz** (`enhanced_quiz_screen.dart`) | `questionsForTopicProvider(topicId)` → `QuestionRepository.getQuestionsByTopicId()` | ❌ Returns **all** questions for the topic. No shuffle, no sampling, no exclusion. |
| **Mock Test / CBT** (`cbt_test_screen.dart`) | `allQuestionsProvider` → `ExamEngineService.validatePool()` → `allocateQuestions()` | ✅ Shuffles within one test, ✅ dedupes *within* a single allocation. ❌ No memory of questions seen in **previous** quizzes or mock tests. |
| **Test Series** (`test_series_screen.dart`) | Same as CBT — full pool → validate → allocate | ❌ Same gap: no cross-session exclusion. |

### Evidence from code
- `lib/core/services/exam_engine_service.dart:402-430` — `allocateQuestions` tracks `takenIds` only inside the current `for` loop over sections. Once the method returns, that set is gone.
- `lib/features/quiz/enhanced_quiz_screen.dart:68` — `_loadQuestionsFromProvider` calls `questionsForTopicProvider(...).future` and feeds **every** returned question into `initializeQuiz`.
- `lib/core/models/user_progress_model.dart:71-105` — `QuizAttempt` stores `score`, `totalQuestions`, `selectedAnswers`, but **not** the list of question IDs that were presented.

### Impact with current data
- Question bank is small (~26 seeded questions).
- A user doing a topic quiz then a mock test will see many of the **same questions** again, just shuffled.

---

## 2. Root Cause

There is **no cross-mode question history**. Each launcher builds its pool independently from the same DB tables, and `QuizAttempt` does not persist which question IDs were shown.

---

## 3. Fix Plan (phased)

### Phase 1 — Immediate (no DB migration)
**Goal:** Stop topic quizzes from exhausting the entire pool, and make mock tests exclude recently seen questions in-memory.

1. **Sample topic quizzes**
   - In `enhanced_quiz_screen.dart` (or `quiz_providers.dart`), cap topic quizzes to a sensible number (e.g., min(topic questions, 15)) with a shuffled random sample.
   - This alone reduces repetition because the quiz no longer consumes the full topic pool.

2. **Build an in-memory "recently seen" set at launch time**
   - Add a provider `recentlySeenQuestionIdsProvider` that reads the last N `QuizAttempt` rows from the DB, extracts question IDs from the stored `selectedAnswers` by cross-referencing the attempt’s `topicId`/`subject` with the current question list order.
   - **Problem:** `selectedAnswers` is a flat list of strings, not objects. We cannot reconstruct question IDs from it without additional info.
   - **Workaround for Phase 1:** Only exclude questions that appear in the **current** CBT resume checkpoints (already have IDs). For full cross-mode exclusion we need Phase 2.

### Phase 2 — Persist question IDs per attempt
**Goal:** Make exclusion reliable across sessions and modes.

1. **Schema change:** Add `question_ids` (JSON array of strings) to the `quiz_attempts` table.
2. **Write path:** When a quiz or CBT attempt finishes, persist the ordered list of question IDs alongside `selectedAnswers`.
3. **Read path:** New provider `seenQuestionIdsProvider(userId)` reads distinct question IDs from recent attempts (e.g., last 7 days or last 5 attempts).
4. **Allocate with exclusion:**
   - `ExamEngineService.allocateQuestions` gains an optional `excludedIds` parameter.
   - Both CBT launcher and topic quiz launcher pass the user’s recently seen IDs.
   - If the excluded set is too large, fall back to a smaller exclusion window rather than crashing.

### Phase 3 — UX polish
- Show “X new questions remaining” or a “Practice missed questions” mode that intentionally re-shows weak/incorrect questions.
- Add a “Reset progress” toggle in Settings that clears seen-question history for a topic.

---

## 4. Recommended immediate action

Do **Phase 1.1 only first** (cap topic quiz size). It is a one-line behavior change, requires no DB migration, and immediately reduces the overlap between quiz and mock-test pools.

Then move to **Phase 2** (persist question IDs) so exclusion is actually correct.

---

## 5. Open questions
- Should we exclude by **question ID** or by **question text hash**? (ID is fine as long as imports don’t regenerate IDs.)
- How many recent attempts should define “seen”? Proposal: last 5 attempts OR last 7 days.
- What is the minimum viable pool size before exclusion becomes harmful? Proposal: if < 10 unseen questions remain, stop excluding and warn the user.
