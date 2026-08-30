# Industry-Grade Exam / DPP / Quiz Engine vs NEET Mitos — Phase 1 Update

**Date:** 2026-08-29  
**Baseline:** Codebase after Phase 1 enhancements (Schema v25, 12 commits on `origin/main`)  
**Scope:** Exam Engine (`ExamEngineService`, `CbtTestScreen`, `CbtResultScreen`), DPP Engine (`DppEngine`, `DppScreen`, `DppAttemptScreen`), Quiz Engine (`QuizNotifier`, `EnhancedQuizScreen`, `QuizFooter`)

---

## Executive Summary

Phase 1 closed every **HIGH-severity gap** identified in the Aug 28 audit:
- ✅ NTA-style question palette with color-coded status (CBT + Quiz)
- ✅ Mark for Review / Mark & Next in CBT and Quiz
- ✅ Hard auto-submit on wall-clock deadline (CBT + DPP)
- ✅ NEET 2025 pattern as default (`ExamConfig.neet()`)
- ✅ Seed-based deterministic shuffle for reproducibility
- ✅ Per-question review in CBT result screen
- ✅ DPP attempt screen with timer, instant review sheet, and auto-submit
- ✅ Repeat-free delivery across quiz/mock via `excludedIds` + `QuestionHistoryService`

The engine now sits at **competitive parity with mid-tier idols** (Gradeup/Darwin early stage, ExamBro, NEETGuru) on core CBT mechanics. Remaining gaps are **content volume**, **DPP multi-subject depth**, **analytics richness**, and **adaptive intelligence**.

---

## Phase 1 Deliverables — Evidence

| Feature | File(s) | Status |
|---|---|---|
| **Question palette (CBT)** | `cbt_test_screen.dart` → `_buildPaletteChip`, `_buildBottomControls` | ✅ Live |
| **Question palette (Quiz)** | `enhanced_quiz_screen.dart` → `_buildQuestionPalette` | ✅ Live |
| **Mark for Review (CBT)** | `cbt_test_screen.dart` → `_toggleFlag`, `_markForReviewAndNext` | ✅ Live |
| **Mark for Review (Quiz)** | `quiz_footer.dart` → `onFlagToggle`, `onMarkForReviewAndNext` | ✅ Live |
| **Auto-submit CBT** | `cbt_test_screen.dart` → `_onTick` calls `_submitTest(auto: true)` | ✅ Live |
| **Auto-submit DPP** | `dpp_attempt_screen.dart` → `_autoSubmit` | ✅ Live |
| **NEET 2025 default** | `exam_engine_service.dart` → `ExamConfig.neet()` (180 Q, 180 min, +4/−1) | ✅ Live |
| **Seed tracking** | `cbt_test_screen.dart` (`_seed`), `quiz_providers.dart` (`QuizState.seed`), `user_progress_model.dart` (`QuizAttempt.seed`) | ✅ Live |
| **CBT review sheet** | `cbt_result_screen.dart` → `_buildQuestionReview` (color tiles + explanations) | ✅ Live |
| **DPP attempt screen** | `dpp_attempt_screen.dart` (timer, review bottom sheet, exit guard) | ✅ Live |
| **Repeat-free delivery** | `question_history_service.dart`, `content_providers.dart` (`recentlySeenQuestionIdsProvider`), `exam_engine_service.dart` (`excludedIds`) | ✅ Live |

---

## Updated Gap Analysis

### 4.1 Critical Gaps — Still Blocking

| Gap | Evidence in Codebase | Industry Standard | Impact |
|---|---|---|---|
| **Question bank size** | `neet_sample_data.dart` holds ~26 questions | 50k–200k questions | Cannot sustain mock tests or DPP without repetition |
| **Cloud sync** | `cloud_sync_service.dart` placeholder; Supabase sync not functional | Real cross-device sync | Loses local-first advantage for multi-device users |
| **Video content** | No video player, no streaming | Core content type in PW/Unacademy | Category exclusion |
| **Live class / educator access** | No scheduling, no streaming | Key differentiator | Cannot compete for paid users |

### 4.2 High-Priority Gaps — Exam/DPP/Quiz Specific

| Gap | Evidence | Industry Standard |
|---|---|---|
| **Multi-subject DPP depth** | `DppConfig.neetPattern` exists but `DppScreen` only offers single-subject route (`/dpp/:subject`); home banner is per-subject | Cross-subject mixed DPP (Phy+Chem+Bio) with per-subject timers in single session |
| **DPP streak / performance analytics** | No streak tracking, no DPP-specific accuracy trend | Daily streak, improvement curve, weak-topic heatmap for DPP |
| **Adaptive difficulty in quiz** | `QuizNotifier` shuffles once; no real-time adjustment based on streak of correct/wrong answers | Next-question difficulty adapts after N consecutive correct |
| **Per-question timer analytics** | `cbt_test_screen.dart` tracks `_secondsPerQuestion`; not surfaced in result screen | Time-per-question heatmap, pacing warnings |
| **Mastery-based progression** | No concept-level mastery; only topic-level accuracy | Unlock next topic only after mastery threshold |
| **Review mode replay from seed** | Seed persisted but no UI to reconstruct exact attempt state | Replay exact paper with original answers/timing |

### 4.3 Medium-Priority Gaps — Engagement

| Gap | Evidence | Industry Standard |
|---|---|---|
| **Leaderboard / peer compare** | No ranking table | Anonymous cohort ranking for mocks |
| **Discussion forum** | AI chatbot only; no peer Q&A | Threaded discussions, upvoted solutions |
| **Scheduled test series** | On-demand only; no calendar | Scheduled mocks with reminders |
| **Notification nudges** | Basic reminders only | Smart DPP/review reminders based on due cards |

### 4.4 Low-Priority / Differentiator Gaps

| Gap | Notes |
|---|---|
| **Handwritten notes** | Differentiator in Gradeup |
| **Voice-based revision** | Niche but useful |
| **Formula sheet module** | Searchable topic-tagged formulas |
| **Wearable companion** | Future feature |
| **Parent / mentor dashboard** | B2B school channel |

---

## What Phase 1 Actually Changed

### Before Phase 1 (Aug 28 audit)
- CBT had next/prev footer, no palette, no flags, no auto-submit
- Quiz had basic footer, no palette, no mark-for-review
- DPP had no timed attempt screen, no review sheet
- No seed tracking anywhere
- Result screen showed only score + subject breakdown, no question review

### After Phase 1 (current)
- **CBT**: Full NTA-style palette (5 states: answered/not answered/marked/not visited), flag toggle, Mark & Next, auto-submit, break timer, checkpoint/resume, seed-based shuffle, per-question review in results
- **Quiz**: Palette overlay, flag toggle, Mark & Next, confetti, hints, short-answer AI evaluation
- **DPP**: Dedicated attempt screen with deadline timer, review bottom sheet (Correct/Incorrect/Skipped), auto-submit, subject breakdown in DPP list
- **Analytics**: CBT result screen now shows question review with explanations, time analysis, weak topics, rank estimates

---

## Recommended Phase 2 Scope

### Sprint A — Multi-Subject DPP Hardening
1. **Multi-subject DPP route**: Add `/dpp/neet` (or similar) that launches a single session with Phy 45 + Chem 45 + Bio 90 using `DppConfig.neetPattern()`
2. **Per-subject timers**: Track remaining time per subject block with auto-advance
3. **DPP analytics**: Persist `DppAttempt` with `correctCount`, `incorrectCount`, `timeSpentSeconds`, `accuracy`; show 7-day streak and trend in `dpp_screen.dart`
4. **DPP review mode**: Expand `_DppReviewSheet` to include per-subject breakdown and NCERT reference links

### Sprint B — Quiz Intelligence
5. **Adaptive difficulty**: In `QuizNotifier.nextQuestion`, if last 3 answers correct → bias next sample toward harder questions; if last 3 wrong → bias easier
6. **Mastery gate**: Require ≥ 60% accuracy in a topic before unlocking next topic in `topic_browser_screen.dart`
7. **Per-question heatmap**: Surface `secondsPerQuestion` from CBT results as a color-coded list (green = fast, red = slow)

### Sprint C — CBT Polish
8. **Review replay from seed**: Add "Replay" button on result screen that navigates to `/cbt/test` with `seed` + `questionPool` extra to reconstruct exact paper
9. **Section-wise time limits**: Optional per-section countdown in `ExamConfig` (e.g., 45 min Physics, then auto-advance)
10. **Result export**: Share result as image/text (PDF or PNG summary)

### Sprint D — Content Pipeline
11. **Bulk import worker**: Background isolate import for 50k+ JSON with progress bar in `settings_screen.dart`
12. **PYQ bundling**: Add option to download curated year-wise PYQ packs (2010–2025) from configurable CDN endpoints

---

## Verdict

**NEET Mitos has cleared the Phase 1 barrier.** The CBT engine now matches or exceeds mid-tier idols on *interface fidelity* (palette, flags, auto-submit, breaks, checkpoint). The DPP engine has a timed attempt flow. The quiz engine has review overlays.

The **next bottleneck is not features — it is content volume and adaptive intelligence**. Without 50k+ questions, the palette and shuffle logic cannot shine. Without mastery models, the app is a smart worksheet, not a tutor.

**Recommended immediate priority**: Bulk-import a real question bank (Phase 0 content work) before building more UI chrome.

---

## Sources

- `lib/core/services/exam_engine_service.dart`
- `lib/features/exam_engine/cbt_test_screen.dart`
- `lib/features/exam_engine/cbt_result_screen.dart`
- `lib/core/services/dpp_engine.dart`
- `lib/features/dpp/dpp_screen.dart`
- `lib/features/dpp/dpp_attempt_screen.dart`
- `lib/core/providers/quiz_providers.dart`
- `lib/features/quiz/enhanced_quiz_screen.dart`
- `lib/features/quiz/quiz_footer.dart`
- `lib/core/models/user_progress_model.dart`
- `lib/core/services/question_history_service.dart`
- `lib/core/services/exam_checkpoint_service.dart`
- `lib/core/services/test_analytics_service.dart`
- Prior audit: `outputs/industry-exam-dpp-quiz-engine-audit.md` (2026-08-28)
- Prior gap analysis: `outputs/neet-mitos-industry-gap-analysis.md` (2025-01-22)
