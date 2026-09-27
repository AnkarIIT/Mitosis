# NEET Mitos — Recovery & Ship-Readiness Plan

**Status:** Research complete, awaiting implementation approval  
**Current state (verified):**
- Analyzer: **0 errors**, 19 warnings/info
- Tests: **126 passing**, 6 pre-existing widget-test failures
- Build: **unblocked** (release APK builds successfully)
- Architecture: local-first flags default to `false`; app launches without Supabase

**Goal:** Transform the app from "promising prototype" to a production-ready, free-for-students, offline-first NEET prep app that a student can rely on for actual exam preparation.

**Constraint:** Zero ongoing infrastructure cost. All cloud features must remain optional and lazy-loaded.

---

## Key Finding: Not All Audit Items Are Still Live

The prior audit (`project-analysis.md`, Aug 24 2025) correctly identified several severe issues. Since then, multiple fixes have landed:

| Audit # | Claimed Issue | Current State |
|---|---|---|
| B1 | `flashcard_generation_service.dart:259` undefined `proxy` | **Fixed** — replaced with `_proxy!` after null guard |
| C1 | CBT passes `PaperConfig` + topic-ID strings; router crashes | **Fixed** — now passes `ExamConfig.neet()` + `List<Question>` |
| C2 | v21 migration deletes `error_book` / `spaced_repetition` data | **Fixed** — migration now copies to temp tables before dropping |
| H1 | Onboarding never sets `onboardingCompleteProvider` | **Fixed** — line 220 now sets `ref.read(onboardingCompleteProvider.notifier).state = true` |
| H8 | CBT timer freezes in background | **Fixed** — `_remainingSeconds -= backgroundSeconds` compensates for wall-clock drift |

**The remaining plan targets the issues that are still real today, plus the strategic gaps that make the app not-yet-shippable.**

---

## Phase 0 — Stabilize the Dev Loop (Week 1, P0)

**Goal:** Make it impossible to break the build or ship without catching regressions.

### 0.1 CI Gate
- Add GitHub Actions workflow: `flutter analyze` + `flutter test` on every PR and push to `main`.
- Make CI status required in branch protection.
- **Why:** Most seam bugs (wrong casts, null-safety breaks) are caught by analyzer in seconds. The current "tests green but doesn't compile" situation happened because tests mock around broken paths.

### 0.2 Strict Lints
- Add `very_good_analysis` or equivalent curated lint set.
- Treat all analyzer warnings as errors in CI (`--fatal-infos` optional, but at least fail on warnings).
- Replace 42 `debugPrint` calls with a structured logger (`package:logger`) gated by `kDebugMode`.

### 0.3 Pre-commit Hook
- `flutter analyze` + `flutter format .` + `dart fix --apply` on every commit.

**Acceptance Criteria:**
- CI runs on every push and blocks merge on failure.
- `flutter analyze` exits 0 locally with no warnings.
- No `debugPrint` in `lib/` outside `logger.dart`.

---

## Phase 1 — Kill Data-Loss & First-Run Bugs (Week 1, P0)

**Goal:** Eliminate the bugs that destroy user trust irreversibly.

### 1.1 Destructive Migration Audit
- **Location:** `lib/core/database/drift_database.dart` v21 and earlier.
- **Task:** Review every `from < N` migration block for `deleteTable` without data copy.
- **Action:** Add data-preservation pattern to any remaining destructive migrations. Add integration tests that:
  1. Insert known rows in schema vN-1.
  2. Run migration.
  3. Assert rows still exist with correct types.
- **Risk:** Silent data loss on upgrade. For an exam app, losing error-book entries is unforgivable.

### 1.2 Unpaginated Sync Data Loss
- **Location:** `lib/core/services/content_sync_service.dart` + `cloud_sync_service.dart`.
- **Task:** Add cursor-based pagination to all Supabase queries. The free-tier row cap is 1000; current queries fetch everything in one shot.
- **Action:** Replace `.select('*')` with range queries (`.range(start, end)`); track `lastSyncedRowId` in local state; loop until fewer rows than page size are returned.
- **Risk:** Rows past the 1000-row watermark are silently dropped and later marked `isActive=false`.

### 1.3 Onboarding Loop Guard
- **Location:** `lib/features/onboarding/onboarding_screen.dart` + `lib/core/providers/settings_providers.dart`.
- **Task:** Ensure `onboarding_complete` and `batch_onboarding_complete` are kept in sync, or collapse them into a single flag.
- **Action:** Write a widget/integration test that simulates: fresh install → onboarding → home. Assert no loop back to onboarding.

### 1.4 Auth / 2FA Correctness
- **Location:** `lib/core/services/auth_service.dart`.
- **Task:**
  1. Ensure `login()` does NOT establish a persisted session before 2FA completes.
  2. Bind `pending_2fa_code` to the email/phone it was sent for.
  3. Add timeout (5 min) and rate limit (3 attempts) to 2FA codes.
- **Risk:** As coded, a code issued for account A verifies login for account B.

**Acceptance Criteria:**
- Fresh install → onboarding → home in < 10 taps, no loop.
- Upgrade from v20 DB preserves all error-book and spaced-rep rows.
- 2FA code cannot verify a different user's login.

---

## Phase 2 — Make CBT Engine NTA-Faithful (Week 2-3, P0)

**Goal:** The CBT simulator must be indistinguishable from the real NTA platform. This is the app's core differentiator.

### 2.1 Data-Driven ExamConfig
- **Location:** `lib/core/services/exam_engine_service.dart` + `lib/core/models/`.
- **Task:** Replace hardcoded values with a configurable `ExamPattern` model.
- **Fields:** `totalQuestions`, `totalMarks`, `durationMinutes`, `sections` (each with `name`, `questionCount`, `duration`, `markingScheme`), `optionalSections` (with `attemptMin` / `attemptMax` logic).
- **Why:** NTA changes pattern year to year (Section B optionality, durations). Hardcoding 720/200-min values makes the app stale the moment NTA updates the bulletin.

### 2.2 Question Palette with 5 Canonical States
- **Location:** `lib/features/exam_engine/cbt_test_screen.dart`.
- **Task:** Implement exact NTA palette states + colors:
  - Not Visited (grey)
  - Not Answered (red)
  - Answered (green)
  - Marked for Review (purple)
  - Answered & Marked for Review (purple + green tick)
- **Why:** Students practice on your simulator; muscle memory must match the real exam.

### 2.3 Four Action Buttons + Section Logic
- **Task:** Implement exact button wording: *Save & Next*, *Clear*, *Save & Mark for Review*, *Mark for Review & Next*.
- **Optional-section logic:** If pattern has "attempt best 10 of 15", evaluate only the first 10 attempted questions per NTA rules.
- **Timer:** Wall-clock authoritative timer. Pause on app background? **No** — real exam time doesn't pause. Auto-submit at zero with no grace period.

### 2.4 Submit → Summary → Confirm Flow
- **Task:** Replace direct submit with:
  1. Section-wise summary screen (answered / not-answered / marked counts per section).
  2. Confirm dialog with "Submit Test".
  3. Only then navigate to `/cbt/result`.

### 2.5 Scoring Golden Tests
- **Location:** `test/exam_engine_test.dart` (create if missing).
- **Task:** Write deterministic tests covering:
  - +4 correct, -1 incorrect, 0 unanswered.
  - Negative total score possible.
  - Optional section "best N" evaluation.
  - Section-wise totals sum to grand total.
- **Why:** Scoring bugs destroy trust. These tests must be green before any content is added.

**Acceptance Criteria:**
- CBT screen visually matches NTA's 2025 mock interface (side-by-side screenshot comparison).
- All 15+ golden scoring tests pass.
- Timer does not pause when app is backgrounded.
- Submit requires explicit confirmation after summary review.

---

## Phase 3 — Content Pipeline & PYQ Bank (Week 3-4, P0→P1)

**Goal:** Move from ~10 bundled questions to a verified, NCERT-aligned bank. Content is the actual product.

### 3.1 Strict Content Schema
- **Task:** Define the canonical `Question` schema contract:
  ```
  id (text, stable),
  subject, chapter, topic, difficulty,
  question (text),
  options[] (4 strings),
  correctIndex (int),
  explanation (text),
  ncertReference: { class, chapter, lineRange? },
  pyqYear?, tags[],
  isVerified, verifiedBy, verifiedAt
  ```
- **Action:** Update `question_model.dart` and `drift_database.dart` schema v22 to match. Add migration.

### 3.2 PYQ Import Pipeline
- **Task:** Import NEET previous-year questions (2020-2024) as the first content wave.
- **Source:** Official NTA released papers (public domain for educational use).
- **Process:**
  1. Parse PDF/text to JSON.
  2. Run through `question_verifier_service.dart` (human-review gate before DB insert).
  3. Batch insert with dedup on `id`.
- **Target:** 2,000+ verified MCQs in first import wave.

### 3.3 Explanation Backfill
- **Current:** `explanation_seeder.dart` is slow (~7 days for 5K) and AI-generated explanations must be human-reviewed.
- **Task:** Replace AI-first seeding with:
  1. Official NCERT/exam-solution explanations from PYQ sources.
  2. AI generation as a *second pass* for questions missing explanations, marked `isAiGenerated=true`.
  3. Human review queue before `isVerified=true`.

### 3.4 Import Screen Polish
- **Location:** `lib/features/settings/import_questions_screen.dart`.
- **Task:** Add per-year import chips (2020, 2021, 2022, 2023, 2024), import progress bar, and post-import summary.

**Acceptance Criteria:**
- At least 2,000 questions with verified keys and explanations in Drift.
- Every question has `ncertReference` populated.
- Import screen shows clear success/failure counts per batch.

---

## Phase 4 — Correctness & Trust (Week 4, P0)

**Goal:** Eliminate silent failures, fabricated data, and scoring errors.

### 4.1 Golden Tests for Core Logic
- **Quiz scoring:** +4/-1/0, negative totals, short-answer grading (H6 fix if still present).
- **Spaced repetition:** SM-2 interval math, Hard rating doesn't leave `interval=0` (perpetually due).
- **Flashcard scheduling:** SM-2 + Leitner box consistency.
- **Rank predictor:** Either ground in real mark-vs-rank data or label clearly as estimate. Remove fabricated difficulty breakdown.

### 4.2 Error Boundaries + Crash Reporting
- Add `ErrorWidget.builder` override in `main.dart`.
- Wrap top-level screens in `try-catch` with fallback UI.
- Add `sentry_flutter` or `firebase_crashlytics` (free tier) for production crash visibility.
- **Why:** Currently zero crash visibility. You don't know when a user hits an unhandled exception.

### 4.3 Silent Failure Audit
- Find all `catch (_) {}` and replace with logged errors + user-facing fallback.
- Find all `debugPrint` and replace with structured logger.

### 4.4 Test-Rate-Limiting + Timeouts
- **Location:** `lib/core/services/gemini_proxy_service.dart`, `gemini_chat_service.dart`, `email_service.dart`.
- **Task:** Add request timeouts (10s for AI, 5s for email), retry with exponential backoff for transient failures.

**Acceptance Criteria:**
- 100% of core scoring paths covered by golden tests.
- No `catch (_) {}` blocks in `lib/`.
- All network requests have timeouts.
- Crash reporting dashboard shows first test crash within 24h of install.

---

## Phase 5 — App Polish & Performance (Week 5, P1)

**Goal:** Make the app feel like a proper product on budget Android devices.

### 5.1 Release Size Optimization
- **Current:** ~97 MB release APK.
- **Task:**
  - Enable R8 full mode (`minifyEnabled true`, `shrinkResources true`).
  - Per-ABI splits (`abiFilters` in `build.gradle.kts`).
  - Remove unused dependencies (`flutter_hooks`, `state_notifier` — Riverpod subsumes them).
  - Move NCERT PDFs to on-demand download instead of bundling all.
- **Target:** < 35 MB base APK.

### 5.2 Low-End Device Performance
- Add DB indexes on `questions.subject`, `questions.topicId`, `questions.isActive`, `flashcards.dueAt`, `quiz_attempts.subject`.
- Stream PDF text extraction instead of loading entire file into memory.
- Profile startup time on a 2GB-RAM device.

### 5.3 Offline UX Polish
- `OfflineBanner` already created; wire it into `HomeShellScreen`.
- Show "Cloud features unavailable" badge in Settings when Supabase is disabled.
- Add retry affordances for transient sync failures.

### 5.4 Dead Code Cleanup
- Delete: `neet_home_screen.dart`, `home_tab_backup.dart`, `chatbot_screen_backup.dart`, `local_ai_service.dart` (if unused), `supabase/` folder (after Phase 0-1 confirm no local code paths need it).
- Remove unused imports across all files.
- Consolidate duplicate `TestResultScreen` classes.

**Acceptance Criteria:**
- Release APK < 35 MB.
- Cold start < 2s on Android 12 / 4GB-RAM device.
- `flutter analyze` exits 0 with 0 warnings.
- No dead files > 50 lines in `lib/`.

---

## Phase 6 — Strategic Deprioritizations (Week 5+)

**Goal:** Stop spending time on features that don't move the needle for a free, offline NEET app.

### Defer or Cut
| Feature | Recommendation | Reason |
|---|---|---|
| AI Chatbot / RAG | **Defer to v2** | Dead stub, costs money, no student asked for it in survey. Local explanations are enough. |
| Cloud Sync | **Keep optional** | Already lazy-loaded. Only 5% of power users need it. Don't invest here until core is solid. |
| 2FA / Email | **Cut** | Cosmetic, adds auth complexity, no offline path. |
| Mark Booster | **Deprioritize** | Niche feature. Error book + spaced review cover the same need. |
| TFLite ML models | **Cut** | `assets/ml/` is empty placeholders. Remove dependency until real models exist. |

### Keep and Double Down
| Feature | Reason |
|---|---|
| CBT Mock Test | Core differentiator. Must be NTA-faithful. |
| PYQ Bank + NCERT deep-links | Content is the product. |
| Spaced Repetition + Error Book | Highest-impact learning loops. |
| Offline-first architecture | Matches user reality (tier-2/3, spotty connectivity). |

---

## Phase 7 — Launch Readiness (Week 6, P1→P2)

### 7.1 Device Testing
- Test on Samsung Galaxy A56 5G (SM-A566E, Android 16 API 36) — confirmed target.
- Test on one budget device (4GB RAM, Android 12) for performance.
- Test offline: airplane mode, all features functional.

### 7.2 Play Store / F-Droid Prep
- App Store assets: icon, feature graphic, screenshots (CBT, flashcards, PYQ bank).
- Privacy policy (required even for free apps).
- Open-source: MIT License on GitHub, enable GitHub Releases + F-Droid repo.
- **Cost:** $25 Google Play one-time fee (or $0 if F-Droid-only).

### 7.3 Community Content Pipeline
- Set up a simple GitHub workflow for community PYQ submissions:
  1. Contributor opens PR with JSON following the strict schema.
  2. GitHub Actions validates JSON + runs golden tests.
  3. Maintainer merges after spot-check.
- This is how you get to 5,000+ questions without paying for content curation.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| NTA changes exam pattern mid-year | Medium | High | Data-driven `ExamConfig` makes pattern changes a JSON edit, not a code change. |
| Content quality complaints | High | High | Human review gate before any question ships. AI-generated content marked clearly. |
| Low-end device crashes (OOM) | Medium | Medium | Stream PDFs, add DB indexes, test on 2GB-RAM device. |
| Supabase free-tier limits | Low | Low | All core features are local-first. Supabase is optional. |
| Play Store policy rejection | Low | Medium | No hardcoded API keys, privacy policy, no deceptive behavior. |

---

## Open Questions (Block Research If Needed)

1. **Official NTA 2026 bulletin numbers:** Verify exact question counts, durations, and marking scheme from the latest official notification before hardcoding `ExamConfig.neet()`. The current values may be stale.
2. **PYQ copyright:** Confirm that importing and redistributing NTA released papers is permissible for educational apps in India.
3. **F-Droid vs Play Store:** User preference unknown. F-Droid is fully free but slower review; Play Store has wider reach but $25 fee.

---

## Artifact Status

- **Verified:** Analyzer clean, tests passing, build unblocked, CBT cast bug fixed, onboarding loop fixed, migration preserves data.
- **Unverified:** Exact NTA 2026 pattern numbers (need official bulletin), PYQ copyright status.
- **Blocked:** Nothing blocking implementation start.

---

## Recommended Next Action

Start with **Phase 0 (CI gate) + Phase 1.1-1.2 (data-loss fixes)** in parallel. These are low-effort, high-trust changes that unblock everything else. Then move to **Phase 2 (CBT engine)** because it's the app's differentiating feature and the scoring golden tests catch integration bugs early.
