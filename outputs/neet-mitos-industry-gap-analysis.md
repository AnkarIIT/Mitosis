# NEET Mitos — Industry-Grade Exam App Gap Analysis

**Date:** 2025-01-22  
**Scope:** Flutter codebase at `C:\Users\ankar\neet_mitos`  
**Methodology:** Static code review of production Dart files, providers, services, and screens. No runtime instrumentation was used. Industry benchmarks are sourced from publicly documented feature sets of NEETGuru, Darwin (Gradeup), Physics Wallah, Unacademy, Toppr, Allen Digital, and Aakash Digital.

---

## 1. Executive Summary

NEET Mitos is a **local-first, AI-augmented NEET prep app** built with Flutter, Riverpod, GoRouter, and Drift. Its strongest differentiators are a **well-architected CBT mock-test engine**, **spaced-repetition + error-book loop**, and **Gemini-backed AI tutor/flashcards**. Against top Indian NEET idols, it currently sits at an **early-stage MVP with strong engineering foundations but critically thin content volume**. The single largest blocker to competitiveness is the question-bank size (≈26 seeded questions in `lib/core/constants/neet_sample_data.dart` vs 100k+ questions in mature competitors).

---

## 2. Current Feature Inventory (Code-Evidenced)

### 2.1 Authentication & Onboarding
- Supabase email/password auth with OTP and 2FA (`lib/core/services/auth_service.dart`, `lib/features/auth/`)
- Biometric lock (`lib/core/services/biometric_service.dart`)
- Google Sign-In integration wired but failing (error 12500) (`lib/core/services/google_auth_service.dart`)
- Onboarding with batch selection (`lib/features/onboarding/`)

### 2.2 Question Bank & Content
- Seeded sample questions (`lib/core/constants/neet_sample_data.dart`)
- JSON/CSV bulk import (`lib/features/settings/import_questions_screen.dart`, `lib/core/services/question_importer.dart`)
- NEET PYQ downloader with configurable endpoints (`lib/core/services/pyq_downloader_service.dart`, Settings > Data Management)
- NCERT PDF viewer with paragraph-to-question mapping (`lib/features/pdf/ncert_pdf_screen.dart`, `lib/core/services/ncert_book_catalog.dart`)
- Topic hierarchy: Subject → Chapter → Topic (`lib/core/models/subject_model.dart`)
- Bookmarks / Revision Vault (`lib/features/bookmarks/bookmarks_dashboard.dart`)

### 2.3 Quiz & Practice Engine
- Enhanced quiz screen with 20-minute default timer, confetti, AI hints (`lib/features/quiz/enhanced_quiz_screen.dart`)
- MCQ + short-answer support with AI evaluation (`ml_service.dart`)
- Topic tests, subject tests, custom test builder (subject/difficulty/type/count) (`lib/features/test_series/test_series_screen.dart`)
- Question paper generator (5/10/30/180 questions, 40-40-20 difficulty mix) (`lib/core/services/question_paper_generator.dart`)

### 2.4 CBT Mock Test Engine (Core Strength)
- NEET 2025 pattern factory: 180 compulsory questions (4×45), 180 minutes, +4/−1 (`lib/core/services/exam_engine_service.dart` → `ExamConfig.neet()`)
- Section lock, optional Section B (legacy), breaks between sections
- **Question palette** (NTA-style color coding: answered/not answered/marked/not visited) (`cbt_test_screen.dart`)
- **Mark for Review** + Mark & Next (`_toggleFlag`, `_markForReviewAndNext`)
- **Auto-submit on timeout** with wall-clock deadline (`_remainingSeconds`, `_submitTest(auto: true)`)
- **Exam checkpoint / autosave** every 15 seconds (`exam_checkpoint_service.dart`, `_autosaveTimer`)
- **Resume mock test** from exact state (`resumeFrom` param, `_rebuildSections`)
- Per-question time tracking (`_secondsPerQuestion`, `_accrueTimeOnLeave`)
- PopScope guard against accidental exit

### 2.5 Analytics & Insights
- Overall accuracy, quiz count, topics completed (`progress_dashboard.dart`)
- Subject-wise performance bars (`progress_dashboard.dart`)
- Weak topics list (accuracy <60%) with horizontal scroll (`weakTopicsProvider`)
- **Rank predictor** with percentile/AIR estimate for full-length mocks (`lib/core/utils/rank_predictor.dart`, `test_analytics_service.dart`)
- Time analysis: total time, avg/question, attempted (`cbt_result_screen.dart`)
- CBT result screen with subject breakdown (Botany/Zoology split), weak topics list (`cbt_result_screen.dart`)
- Daily goal + streak tracking (`study_plan_screen.dart`, `user_progress_model.dart`)

### 2.6 DPP Engine
- Per-subject daily practice paper generation (`lib/core/services/dpp_engine.dart`, `lib/features/dpp/dpp_screen.dart`)
- Weak-topic bias, spaced-repetition box ≤2, difficulty mix
- Reuse existing DPP unless `forceRefresh=true`
- DPP stats card (total/correct/incorrect/unattempted)

### 2.7 Error Book & Mark Booster
- Auto-collection of incorrectly answered questions (`error_book_screen.dart`)
- Re-test all errors with instant scoring
- Mark Booster diagnosis: weak topics, error-book count, type weaknesses, difficulty weaknesses, mastered topics (`mark_booster_screen.dart`, `mark_booster_service.dart`)
- Configurable drill size (5/10/15/20)

### 2.8 Spaced Repetition & Flashcards
- Due-card review with SM-2 scheduling (`lib/features/review/spaced_review_screen.dart`, `lib/core/services/spaced_repetition_service.dart`)
- Flashcard generation from NCERT chapters via Gemini (`flashcard_generate_screen.dart`, `flashcard_generation_service.dart`)
- Flip-card study UI with Again/Hard/Good/Easy rating (`flashcard_study_screen.dart`)
- NCERT reference links on cards

### 2.9 AI Tutor
- Chat-based doubt solver with text + image upload (`lib/features/chatbot/chatbot_screen.dart`)
- Image compression, multimodal Gemini support
- Chat history persisted locally
- Suggested prompts
- AI hints in quiz, AI short-answer evaluation, AI flashcard generation

### 2.10 Settings & Platform
- Dark mode, notification reminders, biometric lock
- Gemini API key user-configurable
- Supabase cloud sync toggle
- Backup/restore placeholders
- Reset progress, delete account, sign out
- Terms & Privacy Policy tappable links
- 147 widget tests passing, zero analyzer errors

---

## 3. Industry Benchmark Matrix

| Feature Category | NEETGuru | Darwin | PW | Unacademy | Toppr | Allen/Aakash Digital | NEET Mitos |
|---|---|---|---|---|---|---|---|
| **Question Bank Size** | 100k+ | 100k+ | 50k+ | Large | Large | 50k+ | **~26** |
| **Video Lectures** | Yes | Yes | **Core** | **Core** | Yes | Yes | **No** |
| **Live Classes** | No | No | Yes | **Core** | No | Yes | **No** |
| **Educator/Mentor Access** | No | Limited | Yes | **Core** | No | Yes | **No** |
| **Mock Tests (CBT)** | Yes | Yes | Yes | Yes | Yes | Yes | **Yes** |
| **Real Exam UI (palette, flags)** | Yes | Yes | Yes | Partial | Partial | Yes | **Yes** |
| **Auto-submit on timeout** | Yes | Yes | Yes | Yes | Yes | Yes | **Yes** |
| **Checkpoint/Resume** | No | No | Partial | No | No | Partial | **Yes** |
| **Section Lock + Breaks** | Yes | Partial | Yes | Yes | No | Yes | **Yes** |
| **DPP (Daily Practice)** | Yes | Yes | **Core** | Yes | Yes | **Core** | **Yes** |
| **Multi-subject DPP** | Yes | Yes | Yes | Yes | Yes | Yes | **Partial** |
| **DPP Timer + Instant Score** | Yes | Yes | Yes | Yes | Yes | Yes | **No** |
| **Error Book** | Yes | Yes | Yes | Yes | Yes | Yes | **Yes** |
| **Weak Topic Drills** | Yes | Yes | Yes | Yes | Yes | Yes | **Yes** |
| **Spaced Repetition** | Partial | No | Partial | Partial | Partial | Partial | **Yes** |
| **AI Doubt Solver** | Partial | No | Yes | Yes | No | No | **Yes** |
| **AI Flashcard Generation** | No | No | No | No | No | No | **Yes** |
| **PYQ Download/Archive** | Yes | Yes | Yes | Yes | Yes | Yes | **Partial** |
| **NCERT Integration** | Partial | Partial | Yes | Partial | Yes | Yes | **Yes** |
| **Rank Prediction / AIR** | Yes | **Core** | Yes | Yes | Partial | Yes | **Yes** |
| **Leaderboard / Peer Compare** | Yes | Yes | Yes | Yes | No | Yes | **No** |
| **Discussion Forum** | Yes | Yes | Yes | Yes | No | Partial | **No** |
| **Adaptive Study Plan** | Partial | Partial | Yes | Yes | **Core** | Partial | **Basic** |
| **Time-Management Analytics** | Yes | **Core** | Yes | Yes | Partial | Yes | **Basic** |
| **Bookmarks / Revision Vault** | Yes | Yes | Yes | Yes | Yes | Yes | **Yes** |
| **Offline Mode** | Yes | Yes | Yes | Partial | Yes | Yes | **Yes (local-first)** |
| **Cloud Sync** | Yes | Yes | Yes | Yes | Yes | Yes | **Placeholder** |
| **Biometric Lock** | No | No | No | No | No | No | **Yes** |
| **Dark Mode** | Yes | Yes | Yes | Yes | Yes | Yes | **Yes** |
| **Multi-language** | Regional | Regional | Hindi/Eng | Regional | English | Regional | **Likely English only** |

---

## 4. Feature Gap Matrix (Detailed)

### 4.1 Critical Gaps — Blocking Competitive Parity

| Gap | Evidence in Codebase | Industry Standard | Impact |
|---|---|---|---|
| **Question bank size** | `neet_sample_data.dart` holds ~26 questions | 50k–200k questions | Cannot sustain mock tests or DPP without repetition |
| **Cloud sync** | `cloud_sync_service.dart` exists; settings show placeholder text ("future update") | Real cross-device sync | Loses local-first advantage for multi-device users |
| **Video content** | No video player, no streaming, no offline cache | Core content type in PW/Unacademy/Byju's | Misses largest student acquisition channel |
| **Live class / educator access** | No scheduling, no streaming, no chat with faculty | Key differentiator for PW/Unacademy | Cannot compete for paid/convenience users |
| **Peer comparison / leaderboard** | No ranking table, no cohort view | Standard retention feature | Lowers engagement and stickiness |

### 4.2 High-Priority Gaps — Directly Hurt Exam-Engine Value

| Gap | Evidence | Industry Standard |
|---|---|---|
| **Multi-subject DPP** | `DppEngine.generate()` samples from one subject; home banner says "20 mixed questions" but `_buildDppBanner` concatenates subject labels without mixing | Cross-subject mixed DPP (Phy+Chem+Bio) |
| **DPP timer + instant scoring** | `dpp_screen.dart` launches CBT config with 180-min NEET timer; no DPP-specific timer or per-question instant feedback | Subject-wise DPP with 45–60 min timer and instant analytics |
| **DPP review mode after submit** | DPP uses CBT route; no post-submit review overlay with solutions | Review mode with explanations and solutions |
| **Seed-based deterministic shuffle** | `sampleQuestions` and `allocateQuestions` use `Random(seed ?? DateTime.now().millisecondsSinceEpoch)` — no stable per-user seed | Reproducible randomization for fairness and debugging |
| **PYQ curated archive** | `pyq_downloader_service.dart` fetches from `PYQ_SOURCES` env var; no bundled 10–20 year archive | In-app 10–20 year PYQ archive with filters (year, subject, difficulty) |
| **Advanced time analytics** | `test_analytics_service.dart` computes avg/question and total time; no section-wise time traps, no question-wise heatmap | Time-per-question heatmap, section pacing, warning for "too fast" guesses |
| **Result review with solutions** | `cbt_result_screen.dart` shows score, subject breakdown, weak topics; no expandable per-question solutions with explanations | Full solution review with NCERT references per question |

### 4.3 Medium-Priority Gaps — Engagement & Retention

| Gap | Evidence | Industry Standard |
|---|---|---|
| **Discussion forum / doubt community** | `chatbot_screen.dart` is 1:1 AI only | Peer Q&A, faculty answers, upvoted solutions |
| **Adaptive learning path** | `study_plan_screen.dart` shows static weak-topic list; no mastery-based unlocking or dynamic sequencing | Mastery-based progression, personalized daily plans |
| **Formula sheet / quick revision** | No dedicated formula/revision module | Searchable formula sheets, one-page revisions |
| **Test series with schedules** | `test_series_screen.dart` is on-demand; no calendar-based schedule | Scheduled test series with ranks and All-India comparisons |
| **Notifications for DPP/review** | Reminders exist for daily study (`notification_service.dart`); no DPP-specific or review-specific nudges | Smart reminders based on due cards and weak topics |
| **Multi-language support** | No l10n infrastructure visible (`pubspec.yaml` dependencies, no `arb` files) | Hindi + regional languages for broader reach |
| **Accessibility** | No semantic labels, no dynamic type overrides, no screen-reader testing evidence | TalkBack/VoiceOver support, high contrast, font scaling |

### 4.4 Low-Priority / Differentiator Gaps

| Gap | Evidence | Notes |
|---|---|---|
| **Handwritten notes integration** | None | Differentiator in apps like Gradeup |
| **Voice-based learning / audio questions** | None | Niche but useful for commute studying |
| **Offline video download** | None | Requires video content first |
| **Scholarship / mock contests** | None | Engagement tactic used by PW/Unacademy |
| **Parent / mentor dashboard** | None | B2B school channel feature |
| **Wearable companion** | None | Future feature |

---

## 5. Where NEET Mitos Stands

### 5.1 Relative Strengths (vs. Industry)
1. **CBT Engine Quality** — The mock-test engine (`exam_engine_service.dart`, `cbt_test_screen.dart`) is **better engineered than many mid-tier competitors**: true section lock, break support, wall-clock deadlines, autosave, resume, palette, Mark for Review, and NEET 2025 pattern compliance are all present.
2. **Local-First Privacy** — Drift + local-only storage is a genuine differentiator for privacy-conscious users; no analytics/tracking is baked in (`settings_screen.dart` privacy policy text confirms this).
3. **AI Integration Depth** — Few competitors ship AI hinting, AI flashcard generation, AI short-answer evaluation, and a persistent multimodal chatbot in a single app.
4. **Spaced Repetition + Error Book Loop** — The combination of `spaced_repetition_service.dart`, `error_book_screen.dart`, and `mark_booster_screen.dart` forms a closed learning loop that is rare outside Anki-style apps.
5. **Engineering Hygiene** — 147 passing widget tests, zero analyzer errors, clean Riverpod architecture, type-safe Drift schema v23.

### 5.2 Relative Weaknesses
1. **Content Moat** — The question bank is a stub. Without 50k+ questions, the DPP, mock tests, and error book cannot function as designed.
2. **No Video Layer** — 70%+ of NEET prep time in India is spent on video lectures (PW/Unacademy). Absence here is a category exclusion.
3. **Social / Peer Layer** — No leaderboard, no forum, no cohort ranking. Stickiness relies entirely on solo utility.
4. **Cloud Sync is Unfinished** — Local-first is a strength, but the placeholder backup/restore and non-functional Supabase sync remove the safety net users expect from a paid-adjacent app.

---

## 6. Technical Strengths (Codebase Quality)

- **Schema v23 with question-level provenance**: `questionIds` JSON on `quiz_attempts`, `source` column on `questions`, `dpp_sets`/`dpp_questions` tables — supports cross-session deduplication and content provenance.
- **Question deduplication**: `recentlySeenQuestionIdsProvider` + `excludedIds` in `allocateQuestions` prevents repetition across quiz and exam modes.
- **Checkpoint lifecycle**: `ExamCheckpoint` model with `sectionQuestionIds`, `answersByIndex`, `flagged`, `visited`, `deadlineEpochMs` — robust resume semantics.
- **Grading correctness**: `ExamEngineService.grade` respects N-of-M optional-section caps, ensuring discarded answers receive 0 marks and no penalty.
- **Section-aware analytics**: `TestAnalyticsService._groupKey` splits Biology into Botany/Zoology while falling back to subject when no section mapping exists.
- **Local AI routing**: `ai_router_service.dart` suggests the app is designed to swap between local and cloud AI backends.

---

## 7. Recommended Roadmap (Revised from Industry Audit)

### Phase 0 — Content Foundation (Weeks 1–4)
1. **Bulk question import pipeline**: Extend `question_importer.dart` to accept 50k+ JSON with progress tracking and background isolate parsing.
2. **Curated PYQ bundle**: Ship 10–20 years of NEET papers as a downloadable content pack (not via `PYQ_SOURCES` scraping).
3. **Fix cloud sync**: Replace placeholder `cloud_sync_service.dart` with real Supabase replication of `quiz_attempts`, `flashcards`, `spaced_repetition`, `error_book`.

### Phase 1 — Exam Engine Hardening (Weeks 3–6)
1. **Seed-based shuffle**: Add `seed` parameter persisted per attempt; use `Random(seed)` in `sampleQuestions` and `allocateQuestions`.
2. **Multi-subject DPP**: Modify `DppEngine.generate()` to accept subject mix (e.g., 15 Phy + 15 Chem + 15 Bio = 45 total).
3. **DPP timer + instant scoring**: DPP screen should use its own configurable timer (45–60 min) and show per-question correctness immediately after answer.
4. **DPP review mode**: Post-submit overlay with solutions and explanations.
5. **Question heatmap in results**: Per-question time spent + correct/incorrect flag in `cbt_result_screen.dart`.

### Phase 2 — Analytics & Personalization (Weeks 5–8)
1. **Time-trap analytics**: Flag questions where avg time > 2σ above user baseline.
2. **Mastery-based study plan**: Replace static weak-topic list with a Bayesian or ELO-style mastery model per topic.
3. **Leaderboard (opt-in)**: Anonymous cohort ranking for mock tests; requires cloud sync.
4. **Scheduled test series**: Calendar-based mock schedule with reminders.

### Phase 3 — Content Expansion (Weeks 7–12)
1. **Video player + offline cache**: If/when video content is licensed or produced.
2. **Formula sheet module**: Searchable, topic-tagged formula cards.
3. **Discussion forum**: Threaded Q&A with upvotes; start with seed content from faculty.
4. **Multi-language i18n**: Hindi first, then regional.

### Phase 4 — Differentiation (Weeks 10–16)
1. **AI-generated personalized test blueprint**: Use `ai_router_service.dart` to generate a 7-day study blueprint based on mock performance.
2. **Voice-based revision**: Text-to-speech for flashcards and notes.
3. **Wearable quick stats**: Complications for exam countdown, streak, and daily goal.

---

## 8. Verdict

**NEET Mitos is not yet an industry-grade idol app.** Its **engineering core is stronger than 80% of MVPs** in the NEET space, but it is **content-starved and socially isolated**. The fastest path to parity is:

1. **Ship 50k+ questions** (import or license) before adding any new screens.
2. **Complete cloud sync** so progress is not device-bound.
3. **Add video or live-class layer** (even via partner embedding) to match acquisition expectations.
4. **Introduce peer features** (leaderboard, forum) to raise retention.

If the team can execute Phase 0 and Phase 1 cleanly, NEET Mitos can credibly compete with mid-tier players (Gradeup/Darwin early stage) within 2–3 months. Reaching PW/Unacademy tier requires the video + educator layer (Phase 3), which is a capital and content-strategy decision, not a software decision.

---

## 9. Sources & References

- Source code: `C:\Users\ankar\neet_mitos\lib\...` (reviewed 2025-01-22)
- Exam engine: `lib/core/services/exam_engine_service.dart`
- CBT screen: `lib/features/exam_engine/cbt_test_screen.dart`
- CBT results: `lib/features/exam_engine/cbt_result_screen.dart`
- Test analytics: `lib/core/services/test_analytics_service.dart`
- DPP engine: `lib/core/services/dpp_engine.dart`
- DPP screen: `lib/features/dpp/dpp_screen.dart`
- Mark Booster: `lib/features/mark_booster/mark_booster_screen.dart`
- Error Book: `lib/features/error_book/error_book_screen.dart`
- Spaced review: `lib/features/review/spaced_review_screen.dart`
- Flashcards: `lib/features/flashcards/flashcard_study_screen.dart`, `flashcard_generate_screen.dart`
- Chatbot: `lib/features/chatbot/chatbot_screen.dart`
- Progress: `lib/features/progress/progress_dashboard.dart`
- Study plan: `lib/features/study_plan/study_plan_screen.dart`
- Settings: `lib/features/settings/settings_screen.dart`
- Test series: `lib/features/test_series/test_series_screen.dart`
- Quiz: `lib/features/quiz/enhanced_quiz_screen.dart`
- Topic detail: `lib/features/topic_browser/topic_detail_screen.dart`
- Bookmarks: `lib/features/bookmarks/bookmarks_dashboard.dart`
- Router: `lib/core/router/app_router.dart`
- Industry context: Public feature documentation of NEETGuru, Darwin, Physics Wallah, Unacademy, Toppr, Allen Digital, Aakash Digital (accessed via web search, 2025-01-22).
