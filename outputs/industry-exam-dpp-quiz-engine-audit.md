# Industry-Grade Exam / DPP / Quiz Engine vs NEET Mitos Current Implementation

## Executive Summary

This report benchmarks NEET Mitos' current `ExamEngineService`, `DppEngine`, and quiz delivery against industry standards observed in NEET/JEE prep platforms (ExamBro, Eklavya, NEETGuru, Darwin), general exam engines (Moodle, Exam.net, Synap), and adaptive learning research. The conclusion is mixed: the local exam/DPP/quiz core is **structurally sound**, but it is **missing several high-signal features** that separate a basic CBT shell from a competitive edtech product.

---

## 1. Exam Engine

### 1.1 Industry-standard features (NEET/JEE context)

| Feature | Industry prevalence | Notes |
|---|---|---|
| **NTA-style CBT interface** | Universal | Exact replica of NTA UI: question palette, section tabs, color-coded status |
| **Question palette** | Universal | White=not visited, Red=visited/unanswered, Green=answered, Violet=marked for review |
| **Section-wise navigation** | Universal | Physics / Chemistry / Biology tabs; jump to any question |
| **Mark for Review** | Universal | Flag and return later; auto-clears on final submit |
| **Auto-submit on timeout** | Universal | Hard stop at 0:00; no grace period |
| **Checkpoint / resume** | Advanced | Full-length mocks survive app kill / background |
| **Optional N-of-M sections** | Historical | Was in NEET 2021–2024 (Section B); **removed in NEET 2025** |
| **Randomized question delivery** | Standard | Different order per attempt |
| **Item bank / blueprint** | Institute-grade | Controls topic/chapter weights per paper |
| **Per-section timer** | Advanced | Separate countdowns per section |
| **Break timer** | Advanced | Scheduled breaks between sections |
| **Review mode after submit** | Universal | Re-open paper with frozen palette + solutions |
| **Rank / percentile estimate** | Competitive | Only for full-length mocks with sufficient history |
| **Section B optional logic** | Historical | N of M grading, discard beyond cap |

Sources: ExamBro, Eklavya, NEET 2027 CBT guides, JustExam NEET software.

### 1.2 Critical NEET pattern change (2025)

**NEET UG 2025 removed optional Section B.**  
- 180 compulsory questions (45 Physics, 45 Chemistry, 90 Biology)
- 3 hours duration
- No optional questions, no extra time

Source: Indian Express, Careers360, Moneycontrol (Jan 2025)

### 1.3 NEET Mitos current exam engine

**Strengths:**
- ✅ Supports standard NEET config (4 sections, 180 questions)
- ✅ Supports practice mode with custom duration
- ✅ Supports optional Section-B variant (`neetWithOptionalB`) — though now outdated for NEET 2025+
- ✅ Grading engine handles N-of-M discard logic correctly
- ✅ Question allocation with `excludedIds` to avoid repeats across attempts
- ✅ Checkpoint service for resume after kill
- ✅ Break timer support
- ✅ Section locking support

**Gaps vs industry:**

| Gap | Severity | Detail |
|---|---|---|
| **No question palette UI** | HIGH | Current screen uses next/prev footer only; missing side palette with color-coded status |
| **No Mark for Review** | HIGH | Industry standard; candidates need to flag and revisit |
| **No auto-submit on timeout** | HIGH | Current code shows countdown but does not hard-stop |
| **No randomized question order** | MEDIUM | `allocateQuestions` shuffles once, but if pool is small (26 seeded questions), repetition is likely |
| **Optional Section B outdated** | MEDIUM | Code supports it, but NEET 2025 removed it; should be configurable, not default |
| **No per-section timer** | LOW | Single global timer only |
| **No rank/percentile** | LOW | Only shown if `isFullLengthMock`; no estimation algorithm |
| **No item bank / blueprint** | LOW | No topic-weight controls per paper |
| **No review mode after submit** | MEDIUM | After submit, user sees score; cannot revisit question paper |

---

## 2. DPP Engine

### 2.1 Industry-standard DPP features

| Feature | Industry prevalence | Notes |
|---|---|---|
| **Daily auto-generation** | Universal | One DPP per subject per day, fresh questions |
| **Topic / chapter filter** | Universal | Select specific chapters for DPP |
| **Difficulty mix** | Standard | Typically 30% easy, 50% medium, 20% hard |
| **Weak-topic bias** | Advanced | Prioritize topics where student scored low |
| **Repeat-free delivery** | Standard | Track seen questions across DPP, quiz, mock tests |
| **Performance tracking** | Standard | Time spent, accuracy, improvement over days |
| **Streak maintenance** | Gamification | Daily streak counter for motivation |
| **Adaptive difficulty** | Advanced | Increase difficulty as student improves |
| **Multi-subject DPP** | Standard | Physics + Chemistry + Biology in one sheet |
| **Instant scoring + solutions** | Universal | Show answers/explanations after submit |

Sources: SchoolDeck DPP Generator, Cracku, Competishun, Physics Wallah.

### 1.3 NEET Mitos current DPP engine

**Strengths:**
- ✅ Daily generation per subject
- ✅ Excludes recently seen questions
- ✅ Weak-topic bias (spaced repetition box ≤ 2)
- ✅ Difficulty mix (30/50/20)
- ✅ Chapter/topic filter
- ✅ Reuses existing DPP if already generated today
- ✅ Persists DPP set + questions to Drift DB

**Gaps vs industry:**

| Gap | Severity | Detail |
|---|---|---|
| **No multi-subject DPP** | HIGH | Industry standard DPP covers all 3 subjects; current is per-subject only |
| **No DPP timer / timed mode** | MEDIUM | DPPs are untimed; real DPPs have ~10–15 min per subject |
| **No DPP analytics over time** | MEDIUM | No streak, no accuracy trend, no improvement tracking |
| **No adaptive difficulty** | LOW | Fixed 30/50/20; doesn't adjust based on performance |
| **No instant scoring UI** | MEDIUM | DPP screen exists but scoring/review flow unclear from engine code |
| **No force-refresh UX** | LOW | Engine supports it, but no UI control |

---

## 3. Quiz Engine

### 3.1 Industry-standard quiz features

| Feature | Industry prevalence | Notes |
|---|---|---|
| **Topic-wise drilling** | Universal | Pick a chapter/topic, get a quiz |
| **Adaptive difficulty** | Advanced | Next question difficulty based on last answer |
| **Mastery-based progression** | Advanced | Advance only when mastery threshold met |
| **Spaced repetition integration** | Advanced | Wrong answers enter SR queue; correct answers reviewed later |
| **Multiple question types** | Standard | MCQ, MSQ, assertion-reason, match, numerical, integer-type |
| **Bloom's taxonomy tagging** | Advanced | Questions tagged by cognitive level |
| **Instant feedback** | Universal | Show correct answer + explanation immediately |
| **Learning path recommendation** | Advanced | AI suggests next topic based on gaps |
| **Gamification** | Standard | Streaks, badges, leaderboards, XP |
| **Detailed analytics** | Standard | Time-per-question, accuracy by topic, error patterns |

Sources: NEETGuru, Darwin NEET, NEETsheet, MedicNEET, adaptcard, StudyQuiz.

### 3.2 NEET Mitos current quiz engine

**Strengths:**
- ✅ Topic-wise quiz loading
- ✅ Question navigation (next/prev)
- ✅ Timer with visual countdown
- ✅ Bookmarking
- ✅ Hints/explanations
- ✅ Short-answer ML evaluation
- ✅ Subject-wise scoring
- ✅ Question exclusion across attempts

**Gaps vs industry:**

| Gap | Severity | Detail |
|---|---|---|
| **No adaptive difficulty** | HIGH | All questions same difficulty; no real-time adjustment |
| **No mastery-based progression** | HIGH | No concept-level mastery tracking or gating |
| **No SR integration in quiz flow** | MEDIUM | SR exists for flashcards; quiz results don't feed back into quiz scheduling |
| **No question palette / Mark for Review** | HIGH | Same as exam engine |
| **Limited question types** | MEDIUM | Only MCQ + short answer; no assertion-reason, match, numerical |
| **No Bloom's taxonomy** | LOW | Questions not tagged by cognitive level |
| **No learning path** | MEDIUM | No AI recommendation of next topic |
| **No gamification** | LOW | No streaks, badges, leaderboards in quiz flow |
| **No per-question timer analytics** | LOW | Total time tracked, not per-question |

---

## 4. Cross-Cutting Architecture Observations

### 4.1 What is genuinely good
- **Local-first architecture**: Works offline, syncs when possible
- **Drift DB with proper schema**: Versioned, migration-capable
- **Repeat-free question delivery**: `QuestionHistoryService` + `excludedIds` propagation is sound
- **Exam grading engine**: Correctly handles optional sections, N-of-M discard logic
- **Checkpoint service**: Resume after app kill for full-length mocks
- **Spaced repetition foundation**: SM-2-like scheduling exists for flashcards and error book

### 4.2 What is missing at the architecture level

| Missing capability | Impact |
|---|---|
| **Question palette component** | Blocks NTA-accurate exam simulation |
| **Item bank / blueprint engine** | Cannot generate balanced papers programmatically |
| **Mastery model** | No per-concept proficiency tracking; only topic-level |
| **Adaptive delivery layer** | Same pool served to all students regardless of ability |
| **Analytics warehouse** | No time-series storage for streaks, velocity, percentile trends |
| **Question metadata completeness** | No Bloom's level, no NCERT line mapping, no concept tags |
| **Multi-modal question support** | No image-based, diagram-based, or numerical-entry questions |
| **Proctoring / lockdown signals** | Not needed for practice, but required for institute mode |

---

## 5. Prioritized Roadmap

### Tier 1 — Must have for competitive parity
1. **Add question palette UI** with color-coded status (white/red/green/violet)
2. **Add Mark for Review** in exam + quiz
3. **Auto-submit on timeout** for all timed modes
4. **Update NEET factory to 2025 pattern** (180 compulsory, 3 hours, remove optional B as default)
5. **Multi-subject DPP** (Physics + Chemistry + Biology in one session)

### Tier 2 — Strongly recommended
6. **Randomize question order** per attempt with per-attempt seed
7. **DPP timer + instant scoring** with subject-wise breakdown
8. **Adaptive difficulty** in quiz: bump difficulty after 3 consecutive correct answers
9. **Per-question time tracking** for analytics
10. **Review mode after submit**: re-open paper with solutions

### Tier 3 — Differentiators
11. **Mastery engine**: Bayesian or Elo-based per-concept proficiency
12. **Learning path recommendation**: AI suggests weak topics + sequence
13. **Rank/percentile estimator**: Requires cohort history; can start with local heuristic
14. **Item bank blueprint**: Balanced topic weights per paper
15. **Gamification layer**: Streaks, badges, daily goals

---

## 6. Specific Code Recommendations

### 6.1 Exam Engine
- Keep `ExamSection.isOptional` but make NEET 2025 factory **compulsory-only** by default.
- Add `shuffleSeed` parameter to `allocateQuestions` so every attempt gets a different order from the same pool.
- Add `autoSubmitAtDeadline` flag to `CbtTestScreen` — currently `_remainingSeconds` is computed but not enforced.

### 6.2 DPP Engine
- Extend `DppConfig` to support `subjects: List<String>` for multi-subject DPP.
- Add `durationMinutes` to `DppConfig` and enforce it in the DPP screen.
- Persist DPP attempt history (`DppAttempts` table) for streak and accuracy tracking.

### 6.3 Quiz Engine
- Add `difficulty` field to `QuizState` and adjust next-question sampling based on last N answers.
- Route quiz results through `QuestionHistoryService` so wrong answers are excluded from future quizzes.

---

## 7. Sources

- ExamBro mock tests: https://exambro.app/mock-tests
- Eklavya mock tests: https://www.eklavya.io/mock-tests
- NEET 2025 pattern change (Indian Express): https://indianexpress.com/article/education/neet-ug-2025-optional-questions-section-b-discontinued-exam-pattern-revert-pre-covid-neet-nta-nic-in-9798692/
- NEET 2027 CBT guide: https://insightstudyhub.com/neet-ug-2027-cbt-exam-guide/
- NEET CBT palette: https://www.cbtneet.in/blog/what-cbt-looks-like-on-screen-5-hidden-rules-nta-wont-tell-you-about-cbt-neet-2027
- SchoolDeck DPP Generator: https://databus.co/schooldeck/features/ai-question-paper/daily-practice-problem-generator/
- Cracku DPP guide: https://cracku.in/what-is-jee-dpp/
- Adaptive learning overview: https://www.evelynlearning.com/products/adaptive-learning
- SM-2 algorithm: https://github.com/open-spaced-repetition/sm-2/
- NEETGuru app features: https://apps.apple.com/in/app/neetguru-neet-mock-tests-2026/id6758427827
- Darwin NEET prep: https://darwin.mcqdb.com/
- MedicNEET app: https://www.medicneet.com/neet-app

---

*Report generated: 2026-08-28*
*Scope: Exam Engine, DPP Engine, Quiz Engine*
*Baseline: NEET Mitos codebase at commit including Schema v23, DppEngine, ExamEngineService, QuestionHistoryService*
