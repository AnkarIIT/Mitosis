# NEET Mitos — Full Project Audit

**Date:** 2026-10-28 · **Auditor:** independent code audit (read-only)
**Scope:** all of `lib/` (194 Dart files, ~2.6 MB), `test/` (49 files), `assets/` (metadata + PDF text extraction), `pubspec.yaml`, `analysis_options.yaml`, `android/`, `ios/`, `supabase/`, CI. `flutter analyze` and `flutter test` were actually executed on the working tree.

> ⚠️ **Working-tree state:** 39 files are modified but uncommitted, and `lib/features/exam/` (2 screens + 2 widgets, ~33 KB) exists on disk but is **untracked** by git. Several findings below are caused by that untracked WIP, not by the committed code. The report distinguishes the two.

---

> ## Status update — 2026-10-29
>
> The findings below are preserved as written on 2026-10-28. Where a fix has landed, the text is annotated in place; this table is the summary.
>
> | Finding | Status |
> |---|---|
> | Class-12 Biology + Physics chapter→PDF mapping shifted by one; 5 mapped PDFs missing | **Fixed.** `ncert_book_catalog.dart` was re-mapped against NCERT's rationalised numbering. `scripts/verify_ncert_mapping.py` extracts each PDF's own chapter title and checks 33 mappings: **0 problems, exit 0**. `test/ncert_book_catalog_test.dart` pins the result. |
> | `bio_ch20/21/22` placeholder chapters visible to students | **Removed** from both `neet_sample_data.dart` and `study_resource_content.dart`. |
> | Chapters dropped from the rationalised syllabus | **Kept, not deleted** — old PYQs still reference them. They carry `isRemovedFromSyllabus: true` (`subject_model.dart`) and show a "Not in current NCERT" badge (`topic_browser_screen.dart`). `entryFor()` returns `null` for them so the name-based fallback cannot hand back the wrong PDF. |
> | Fake "PYQ Downloads" screen | **Hidden.** `FeatureFlags.pyqDownloads` defaults to `false` (`--dart-define=PYQ_DOWNLOADS=true` to re-enable) and `/pyq` redirects to `/practice`. The PDF service was sanitised: 9 direct `.pdf` sources (2015–2023) instead of 20 URLs, 11 of which were `careers360.com/articles/...` HTML pages that were saved as `neet_<year>.pdf`. Downloads are now rejected unless the body starts with `%PDF`. |
> | CBT palette : answering did not match NTA | **Fixed.** A clicked option is a draft: the palette stays "Not Answered" until `SAVE & NEXT` / `SAVE & MARK FOR REVIEW`. Leaving a question drops the draft with a warning, and the submit dialog lists unsaved selections. |
> | `flutter test` | **427 / 427 pass.** |
>
> Still open: 582 `flutter analyze` issues (all in untracked scratch files and the untracked WIP, none in tracked `lib/`/`test/` sources), ~403 MB of bundled NCERT PDFs, the committed key in `docs/STAGING_BOOTSTRAP.md`, the missing iOS FaceID plist, and the 77-question bank.

---

## 1. Executive summary

1. **The core product is real and mostly good.** Drift DB (schema v40, real migrations), question bank seeded into SQLite, CBT exam engine with wall-clock deadlines, checkpoints, +4/−1 grading, NTA-style palette, autosave every 10s (`lib/features/exam_engine/cbt_test_screen.dart:66-120`, `lib/core/services/exam_engine_service.dart:578-640`).
2. **Content quality is high where it exists.** All **77** banked questions were manually answer-checked: **0 wrong answers**. 7 revision-note entries fact-checked against NCERT: **0 factual errors**. Distractors are genuine NEET-grade (same concept family), not generic strings.
3. **The single biggest risk to students is coverage masquerading as completeness**: only **77 PYQ-tagged questions** (target 450+), **Chemistry 2 chapters / Physics 2 chapters** modeled (vs ~19–30 / ~28 each), and **16 of 38 revision notes are empty shells** — yet the UI presents all subjects/chapters equally.
4. ~~**5 NCERT PDFs referenced in the catalog are missing from disk** and **Class-12 Biology + Physics chapter→PDF mappings are systematically shifted by one chapter**~~ — **fixed 2026-10-29**: re-mapped against the rationalised numbering, verified by `scripts/verify_ncert_mapping.py` (33 mappings, 0 problems).
5. ~~**The "PYQ Downloads" screen is fake**~~ — it animated a progress bar for 3 seconds and announced "Downloaded NEET 2019 Physics paper" without downloading anything (`lib/features/pyq/pyq_download_screen.dart:445-491`). **Hidden 2026-10-29** behind `FeatureFlags.pyqDownloads` (default `false`); `/pyq` redirects to `/practice`.
6. ~~**9 of 409 tests fail**~~ — **as of 2026-10-29: 427/427 pass.** `dart format` drift still to check; `flutter analyze` exits 1 (582 issues — all in untracked scratch files `tools/experiments/` and the untracked WIP `lib/features/exam/`, 0 in tracked `lib/`+`test/`).
7. **AI features are OFF by default and the "RAG" is a mock** returning `null` (`lib/core/services/ai_router_service.dart:88-95`). The chatbot only works if the user pastes their own Gemini key; UI must not imply otherwise.
8. **A real-looking Google API key was committed** in `docs/STAGING_BOOTSTRAP.md:116` (redacted there on 2026-10-31; the value is still in commit `e825f34`). **Rotation in Google Cloud is still mandatory** — redaction alone does not revoke it.
9. **~403 MB of NCERT PDFs ship inside the app bundle** (pubspec assets, lines 75–84) — Play Store's 150 MB base-module limit makes this **unshippable as-is**, independent of the copyright question.
10. **`ML service`, `tflite`, `groq`, `google_fonts`, `confetti`, `intl`, `permission_handler`, `flutter_hooks`, `state_notifier` are declared but unused**; `assets/ml/` is empty except `.gitkeep`; `assets/fonts/` (5 TTFs) are declared nowhere and never wired in.

---

## 2. Part 1 — Inventory

- **lib/ structure:** `core/` (config, constants, database [19 tables + repository], models [20], providers [13 files], router, services [50], theme, utils, widgets), `features/` (~55 screens across 22 feature folders), `main.dart`.
- **Dependency direction:** clean in committed code — `lib/core` never imports `lib/features` (verified by grep: 0 hits). Feature files import core via `providers.dart` barrel.
- **State management:** Riverpod 2.5.1 everywhere (`StateNotifierProvider` for quiz/progress/auth, `FutureProvider`/`StreamProvider` for async data, `Provider.family` for per-subject stats). No BLoC, no `setState`-heavy screens in core flows.
- **Declared-but-unused dependencies** (never imported in lib/ or test/): `groq` (pubspec.yaml:17), `google_fonts` (:39), `confetti` (:44), `intl` (:49), `permission_handler` (:50), `flutter_hooks` (:53), `state_notifier` (:54), `cupertino_icons` (:12). `sqlite3` (:28) is used only transitively via drift. `tflite_flutter` (:15) is imported by `ml_service*.dart` but **no model file exists** (`assets/ml/` contains only `.gitkeep`), so inference can never run.
- **Dead/legacy files in lib/** (defined but referenced by nothing except themselves): `lib/features/home/modern_home_screen.dart`, `lib/features/home/home_content/learn_hub_screen.dart`, `practice_hub_screen.dart`, `review_tab.dart`, plus the entire untracked `lib/features/exam/` (screen + widgets + `lib/core/models/exam_model.dart`, which only the dead files import). `lib/core/services/pyq_pdf_downloader_service.dart` is referenced only by its own test.

## 3. Part 2 — Behavior

### Flows (all verified in code)
| Flow | Path | State | Data source |
|---|---|---|---|
| Launch | `main.dart:21-64` → notifications init (5 s timeout) → prefs preload → `runApp` → Supabase + seeding in background | `bootstrapStatusProvider` | SharedPreferences, Drift |
| Home | router `/` → `HomeShell` → `HomeTab` (`app_router.dart:145`) | `overallStatsProvider`, `learningRecommendationsProvider`, `dailyGoalProvider`, `dueCardsProvider`, `activeCbtCheckpointProvider` | Drift + in-memory providers — **all real data** (`home_tab.dart:16-42`) |
| Subjects→Chapter | `/subjects/:id` → `/topic/:id` → `/chapter/:id` (`subjects_tab.dart:79-82`, `app_router.dart:177-400`) | `subjectsProvider` (constants), `questionsForTopicProvider` (DB) | `neet_sample_data.dart` catalog + Drift questions |
| Notes | `/resources/notes?chapterId=` → `chapter_notes_screen.dart`; `StudyResourceContent` map; "Open NCERT PDF" → `ncert_pdf_screen` | read-only | `study_resource_content.dart` + bundled PDFs |
| Quiz practice | `/quiz?topicId=` → `enhanced_quiz_screen.dart` | `quizProvider` StateNotifier, autosave 10 s (`quiz_providers.dart:214-250`) | Drift (questions + quiz_sessions) |
| Custom paper | `/test-series` → `question_paper_selector` → `QuestionPaperGenerator.generatePaper` (`question_paper_generator.dart:10-75`) | local | DB pool; difficulty-balanced 40/40/20 sampling; honest "(Sample)" title when pool too small (:254-263) |
| CBT mock | `/cbt/instructions` → `/cbt` → `/cbt/result` | `cbt_test_screen` + `exam_checkpoint_service` | DB pool via `ExamEngineService.allocateQuestions` |
| Progress | `/progress` → `progress_dashboard.dart` | `overallStatsProvider`, `mockStats`, `weakTopics`, fl_chart BarChart (`:255-256`), `RankPredictor` (`:6,40`) | Drift attempts |

### Persistence reality check — Drift IS written and read
- Startup seeds: `repository.importBundledQuestions('assets/questions/neet_sample_10.json')` + `insertSampleQuestions()` (77 questions, idempotent) + starter flashcards (`main.dart:106-119`; `question_repository.dart:21-64`).
- Written: quiz sessions (autosave, `quiz_providers.dart:216-246`), quiz attempts, DPP sets+questions (`dpp_engine.dart:388+`), bookmarks, error book, flashcards, spaced repetition, chats, consent, chapter/topic progress — all through `AppDatabase` (19 tables, `drift_database.dart:38-60`).
- Schema **v40** with a real stepwise `MigrationStrategy` + `_addColumnSafely` guards (`drift_database.dart:77-150+`). Schema changes are handled; the migration list is long and hand-maintained — risk of drift (no tests exercising from-v1 upgrades found).
- DB is a plain unencrypted SQLite file at `getApplicationDocumentsDirectory()/neet_questions.db` (`connection_native.dart:12-19`).

### Question generation
- **Real logic, no fabricated distractors.** Options come pre-authored in the bank; the generator only samples/balances. `ExamEngineService.validatePool` drops ungradable questions before any exam (`exam_engine_service.dart:486-497`) — a good integrity gate.
- Sample distractor quality (from the actual bank): Q9 crossing over: `Pachytene | Zygotene | Leptotene | Diplotene`; Q102 third-shell orbitals: `9 | 4 | 16 | 3`; Q48 degenerate code: `More than one codon codes for a single amino acid | One codon codes for more than one amino acid | ...` — all same-concept, NEET-plausible. **No "It lacks a membrane boundary"-style fillers found.**

### Exam engine specifics
- Timer: absolute wall-clock deadlines; remaining = `deadline − now`, rounded **up** to avoid early auto-submit (`cbt_test_screen.dart:70-105`); background-safe; per-question time banked on leave.
- Auto-submit at 0 (`cbt_test_screen.dart:318, 394, 555`); proctoring counts app-switch violations; fullscreen + secure screen on (`:122-147`).
- Scoring +4/−1/0 with optional N-of-M sections: first `min(graded, allocated)` answered count, excess discarded without penalty (`exam_engine_service.dart:578-640`).
- Result math has **zero-division guards**: `maxScore <= 0 ? 0.0` (`cbt_result_screen.dart:32,122`), `subject.attempted == 0 ? 0` (`:321-323`). The "known accuracy division-by-zero" issue is **already fixed** in current code.
- Palette (live screen): five-state chain at `cbt_test_screen.dart:1612-1623` — answered+flagged → green **with flag badge** (`:1660-1673`), answered → green, flagged-unanswered → purple (`SubjectColors.chemistry`), visited-unanswered → red, unseen → background. **No shadowed branch.**

## 4. Part 3 — Frontend

- **Theme discipline is good.** Only 9 hard-coded `Color(0x…)` literals in tracked feature code (`lesson_screen.dart` ×4, `chapter_quiz_screen.dart` ×4, `resources_screen.dart` ×1). The other 61 are in the untracked WIP `nta_exam_screen.dart` (59) + `question_palette.dart` (2).
- **Deprecated APIs (tracked code): none.** `withValues` used 254×; `WillPopScope` ×1 and `withOpacity` ×3 exist **only** in the untracked WIP (`nta_exam_screen.dart:91,214,386`, `question_palette.dart:78`). No `CardTheme(`/`MaterialStateProperty` anywhere.
- **Responsiveness:** live screens use `ConstrainedBox(maxWidth: 720)` (`home_tab.dart:50`), ListView/GridView — no breaking fixed widths found in the live exam screen (palette chips are 44×44, `cbt_test_screen.dart:1638-1639`). The bad fixed widths (`width: 280` at `nta_exam_screen.dart:109`, 42×42 chips at `:519`) are in the dead WIP only.
- **Accessibility:**
  - Palette chips 44×44 dp and legend dots 12×12 (`cbt_test_screen.dart:1638`, `question_palette.dart:109`) — below the 48 dp guideline; palette chips also have **no semantics labels** (numbers only).
  - `subjects_tab.dart:28-33` — search `IconButton` with **no tooltip** and a no-op `// TODO: subject search` handler.
  - Contrast (computed): white on `#555555` ≈ **7.5:1** (pass), black on `#FCD34D` ≈ **15.8:1** (pass), `#888888` on `#1a1a1a` ≈ **5.5:1** (pass). The WIP palette's color pairs are actually fine; the problem there is logic, not contrast.
- **Palette bug (reported in the task brief): CONFIRMED — but only in the dead WIP.** `nta_exam_screen.dart:505-513`: branch 1 catches `attempted || attemptedReview` → green; branch 2 tests `markedReview || attemptedReview` → amber, whose `attemptedReview` clause is **unreachable** (shadowed). Consequence: answered+marked shows plain green with no mark indicator (the live `cbt_test_screen` handles this correctly with a badge). Since nothing routes to this screen, it is dead code — but it breaks `flutter analyze`.
- **Home percentages:** the live `HomeTab` computes everything from providers (`home_tab.dart:20-42,171-173`). The hard-coded fake progress (Biology 0.75/135-180, Chemistry 0.60/90-150, Physics 0.55/66-120) lives in the **unreferenced** `modern_home_screen.dart:214-233`. The exact "65/33/78" values from the brief do not exist in the current tree (likely from an older revision).
- **Rank/percentile UI** is honest: "Rough estimate — not an official NEET rank/percentile" (`cbt_result_screen.dart:76`), and `RankPredictor` is a labeled heuristic lookup table (`rank_predictor.dart:4-34`).

## 5. Part 4 — Data layer

- **Tables (19):** Questions, QuizAttempts, QuizSessions, TopicProgressEntries, Bookmarks, Chats, DailyGoals, Users, ErrorBook, Evaluations, SyncWatermarks, SpacedRepetition, Flashcards, DppSets, DppQuestions, ResourceProgress, MistakeEvents, RetentionReviews, ConsentRecords (`drift_database.dart:39-60`).
- **Repositories:** `QuestionRepository` is fully DB-backed with pagination and dedup (`question_repository.dart:114-147`). Progress/stats providers read Drift (`user_providers.dart:442-511`); `subjectStatsProvider` accuracy = correct/total with a 0-guard (`:478`) and `QuizAttempt.score` is defined as *number of correct answers* (`user_progress_model.dart:78`) — math is consistent.
- **Asset pipeline:**
  - Declared and present: 11 NCERT folders (100 PDFs, ~403 MB), `assets/questions/` (1 JSON, 10 questions), `assets/images/mitos-app-icon-1024.png`, `assets/ml/` (empty).
  - **`assets/fonts/` (5 TTFs) are declared nowhere** — not in `assets:`, no `fonts:` block — and no code references Poppins/Inter (earlier grep hits were the word "inter…" in prose). Dead weight in the repo; the app silently uses system fonts.
- **`ncert_book_catalog.dart` vs disk** (verified by parsing every mapped path and by extracting PDF text):
  - 83 unique mapped PDFs; **5 missing on disk**: `kebo120.pdf`, `kebo121.pdf`, `kebo122.pdf` (catalog lines 55-57), `lebo114.pdf`, `lebo115.pdf` (lines 46-47). Those 5 chapters cannot open their NCERT PDF at runtime.
  - 22 orphan PDFs on disk (answer keys `*an.pdf`, contents `*ps.pdf`, `kech1a1`, `leph108`, etc.) — shipped in the APK but unmapped.
  - **Wrong-content mappings (verified via pypdf text extraction) — fixed 2026-10-29, kept as evidence:**
    - `phys_ch2` ("Units & Measurements") → `keph102.pdf`, which is actually **"Motion in a Straight Line"**; the real Units chapter is `keph101.pdf` ("CHAPTER ONE UNITS AND MEASUREMENT"). `phys_ch3` ("Motion in a Straight Line") → `keph103.pdf` = **"Motion in a Plane"** (`ncert_book_catalog.dart:68-69`).
    - Class-12 Biology is **shifted by one for all 13 mapped chapters**: e.g. `bio_ch2_12` "Sexual Reproduction in Flowering Plants" → `lebo102.pdf` which is **Human Reproduction**; `bio_ch3_12` "Human Reproduction" → `lebo103.pdf` = **Reproductive Health** ("You have learnt about human reproductive system … in Chapter 2", extracted from lebo103); `bio_ch10_12` "Microbes in Human Welfare" → `lebo110.pdf` = **Biotechnology and its Applications**. Two mapped chapters (`Reproduction in Organisms`, `Strategies for Enhancement in Food Production`) were **removed from the rationalized NCERT** and don't exist as PDFs at the right number at all.
    - Class-11 Biology spot-checks were correct (kebo112 = Respiration ✓, kebo115 = Body Fluids ✓).
  - `studyResourceContent` ↔ chapters: 38/38 keys match, no orphans in either direction. But **16 entries have empty keyFacts/pyqTraps/rules/diagrams** (bio_ch5/6/7/15/17/18/19/20/21/22, bio_ch1_12/2_12/4_12/9_12/10_12/12_12) — the app shows an overview-only page for 42% of chapters.
- **PYQ data integrity (scripted over all 77 questions):** duplicate IDs **0**; duplicate question texts **0**; `correctAnswer ∈ options` violations **0**; options≠4 **0**; invalid difficulty **0**; empty explanations **0**; year-vs-`PYQ-`tag mismatches **0**; all 77 `topicId`s exist in the catalog; all `Topic.questionCount` claims match actual counts. *(This is unusually clean.)*
- **PYQ totals:** 77 banked (Biology 57, Chemistry 10, Physics 10) + 10 in `assets/questions/neet_sample_10.json` = **87 max seedable**. Years: 2014×1, 2016×2, 2017×2, 2018×5, 2019×11, 2020×16, 2021×14, 2022×12, 2023×11, 2024×1, untagged×2.

## 6. Part 5 — Content accuracy (critical)

**Verdict: no factual errors found. Every check passed.**

1. **Revision notes fact-check (7 full entries verified against NCERT knowledge):**
   - `chem_ch1` (mole concept, molarity/molality, limiting reagent, M₁V₁=M₂V₂) — correct.
   - `chem_ch2` (Bohr `rₙ=0.529n²/Z Å`, `Eₙ=−2.18e-18·Z²/n² J`, nodes `n−l−1/l/n−1`, Cr=[Ar]3d⁵4s¹, Cu=[Ar]3d¹⁰4s¹, R_H≈109 677 cm⁻¹, 4s-fills-first/removed-first) — correct.
   - `phys_ch2` (dimensional analysis necessity-vs-sufficiency, error propagation `Δz/z` rule) — correct.
   - `phys_ch3` (kinematics, `sₙ = u + a(2n−1)/2`, stopping distance ∝ v²) — correct.
   - `bio_ch8` (70S/80S, organelle DNA, fluid mosaic) — correct.
   - `bio_ch13` (PS II→PS I order, cyclic = ATP-only, Calvin 3 ATP+2 NADPH/CO₂, 18 ATP+12 NADPH/glucose, RuBisCO bifunctional, photorespiration products) — correct.
   - `bio_ch5_12` (3:1, 1:2:1, 9:3:3:1, ABO codominance, Morgan linkage, sickle-cell Val→Glu position 6, HbAS malaria resistance, honeybee haplodiploidy) — correct.
   - ⚠️ One **authoring artifact** shipped inside data: `bio_ch5_12` formulas contains `“Base ratios for chiasmata? (not applicable — skip numeric content here).”` — a leftover AI-drafting note that students will see.
2. **Answer-key check: all 77 questions manually evaluated — 0 wrong answers.** (Includes the numerics: 0.1 mol triatomic → 1.806×10²³ ✓; n=3 → 9 orbitals ✓; 18 electrons ✓; [M⁻¹L³T⁻²] ✓; 3 significant figures in 0.00250 ✓.)
3. **Distractor plausibility:** every option set examined is same-concept (see §3). No generic-filler distractors anywhere in the bank.
4. **`ncertReference` / year claims:** questions carry `ncertReference: "NCERT Class 11, Chapter X, Page Y"` and `year: 20XX` + `PYQ-20XX` tags. The repository contains 10 NTA-paper PDFs in the untracked `NEET_PYQ/` folder, but **no pdftotext tool is installed** and the folder is not part of the app; **the year attributions could not be verified against the source papers.** Several questions are clear paraphrases of classic NEET items rather than verbatim reproductions, so the `PYQ-20XX` labels should be treated as *unverified* until checked. No internal contradictions (year vs tag) were found.
5. **Diagrams:** notes reference diagrams as *text descriptions* ("Taxonomic hierarchy: Kingdom → …"), never as image files — so no missing image assets exist, but there are **no actual diagram images anywhere** in the app (assets/images has only the app icon). The test `every …biology carries diagrams` fails because the 16 shell entries have empty diagram lists.
6. **Chapter/PDF mismatch** (the worst content-accuracy finding) is detailed in §5: 5 missing PDFs + systematic off-by-one Class-12/Physics mapping, verified by extracting chapter titles from the PDFs themselves. **Fixed 2026-10-29** — see the status table at the top.
7. **Placeholder chapters (resolved 2026-10-29):** `bio_ch20/21/22` used to be literally named "Chapter 20/21/22" with descriptions "Placeholder chapter 20/21/22" (`neet_sample_data.dart:1008,1025,1042`) — visible to students. They have been deleted from both the chapter catalog and the content catalog.

## 7. Part 6 — Security & privacy

| Item | Finding | Severity |
|---|---|---|
| Committed API key | `docs/STAGING_BOOTSTRAP.md:116` contained a Google/Firebase-style key in plaintext (**redacted 2026-10-31**, but still present in commit `e825f34`). Even if it is "just" a client identifier, it is rotatable material in git history — rotate it. | **High** (rotation) |
| `.env` handling | `.env` exists locally (232 B), is **not** tracked, `.gitignore` covers `.env` and `.env*.local`; only `.example` files are committed. `main.dart:24-36` documents why. | OK |
| Secrets in client | No service_role/Gemini key anywhere in `lib/`. Edge functions read `Deno.env` (`supabase/functions/*/index.ts`). CI has a secret-scan job (`ci.yml:60-95`). Gemini key is **BYOK**: user-pasted, stored in `flutter_secure_storage` (`gemini_chat_service.dart:13-18`). | OK |
| google-services.json | Contains the standard (public-by-design) Android `api_key` `AIzaSyCnq5jZihwYqtpuIIU248H_bBLbQzuRNFs` — normal for Firebase Android, but listed for completeness. | Info |
| Android | No `usesCleartextTraffic`; `network_security_config.xml` forbids cleartext and pins Supabase/Resend certs — **pin-set expires 2026-12-31** (2 months away; after expiry pinning silently stops being enforced). Release build **hard-fails without real signing config** instead of silently debug-signing (`build.gradle.kts:41-57`) — excellent. minSdk/targetSdk = Flutter defaults. Permissions (INTERNET, NETWORK_STATE, USE_BIOMETRIC, POST_NOTIFICATIONS, VIBRATE, RECEIVE_BOOT_COMPLETED, USE_EXACT_ALARM) all map to real features. | OK / pin-expiry Medium |
| iOS | `ios/Runner/Info.plist` **was missing `NSFaceIDUsageDescription`** although `local_auth` biometric lock is a core feature (`main.dart:186-213`). **Fixed 2026-10-31** — the key is present and the plist parses. Needs a real device run before release. | Fixed |
| Local data | Unencrypted SQLite with users (PBKDF2-hashed passwords — verified by `auth_security_test.dart` passing), attempts, chats. Standard practice, but no SQLCipher. No analytics/crash SDK at all (no firebase/sentry imports). | Info |
| Network endpoints | Supabase (config-dependent), `raw.githubusercontent.com/cursed-engineer/NEET-PYQs`, `neetpyqs.hf.space` (settings PYQ download), careers360/collegedekho/personal-site URLs (in the dead `PyqPdfDownloaderService`). Third-party PYQ JSON is **untrusted content imported straight into the DB** (`pyq_downloader_service.dart:28-42` → `bulkInsertQuestions`). | Medium |
| Copyright | 100 NCERT chapter PDFs (~403 MB) are bundled into the binary (pubspec.yaml:75-84). NCERT PDFs are freely downloadable but their license does not automatically permit app redistribution. The 10 NTA paper PDFs in `NEET_PYQ/` are **not** in git and **not** bundled. The PYQ *downloader* points students at third-party mirror CDNs. | **High** (launch/legal) |

## 8. Part 7 — Build, test & quality

- **`flutter analyze`: exit 1.** Totals: **582 issues — 457 errors, 105 warnings, 20 infos.**
  - 452 errors are in **untracked scratch files** `tools/experiments/dpp_*.dart` (import nonexistent paths, syntax errors).
  - 5 errors in **untracked WIP** `lib/features/exam/widgets/question_palette.dart` (undefined `AppColors.bgMedium/bgLight/accent/textSecondary` at lines 18, 22, 38, 73, 120).
  - **Tracked lib/ + test/: 0 errors.** CI runs `flutter analyze --no-fatal-warnings --no-fatal-infos lib test` (`ci.yml:22`), which is why CI stays green while a local full-repo analyze is red.
- **`flutter test`: 427 passed, 0 failed** (as of 2026-10-29). The 9 failures listed below were the 2026-10-28 state and have since been fixed — 8 were stale expectations, 1 was the real `forceRefresh` DPP bug:
  1. `dpp_engine_test.dart` "forceRefresh creates a new DPP" — **real bug**: `DppEngine.generate(forceRefresh: true)` never deletes the existing set; it inserts a second one (`dpp_engine.dart:321-389`; test expects 1 set, got 2 with same date/subject).
  2–3. `small_screen_test.dart` ×2 — expects `"NEET Rank Predictor"` in the progress dashboard; that string exists **only in the test** (dashboard was redesigned; `progress_dashboard.dart` has no such text). Stale expectation.
  4–5. `study_resource_content_test.dart` ×2 — the content **quality gate working as designed**: 16 shell entries have no keyFacts/traps/rules (test `:34-57`) and no diagrams (test `:76-80`).
  6–9. `widget_test.dart` ×4 — stale home expectations: `"Featured Subjects"` (`:98`), `"Ongoing Progress"` (`:99,125`), home `"Weak Topics"` banner (`:158`), and topic-detail fallback `"TRY TEST SERIES INSTEAD"` (`:245`) — none of these strings exist in lib/ (the fallback text moved to `allen_study_module_screen.dart:667`, a different screen).
- **`dart format --set-exit-if-changed lib test`: 10 files unformatted** → CI format job fails on the current tree.
- **TODO/FIXME/placeholder inventory (lib/):** `subjects_tab.dart:31` (TODO search noop); `neet_sample_data.dart:1008,1025,1042` ("Placeholder chapter 20/21/22"); `ai_router_service.dart:93` ("Simple mock logic for now"); `study_resource_content.dart` bio_ch5_12 artifact (§6.1); `auth_screen.dart:285` (Google sign-in unconfigured fallback message); `pyq_download_screen.dart:463-464` (commented-out real download call).
- **Duplicate logic found:**
  - **Two exam models:** `ExamConfig/ExamEngineService` (live) vs `ExamSession/QuestionStatus` (`exam_model.dart`, consumed only by dead WIP). One should be deleted.
  - **Two palette implementations:** `cbt_test_screen.dart:1603-1677` (correct) vs `question_palette.dart` (broken, dead).
  - **Two timer formatters:** `cbt_test_screen._formatTime` vs dead `exam_timer.dart`.
  - **Two PYQ downloader services** (real JSON downloader wired in Settings vs dead PDF downloader with 20 source URLs).
- **Stub/fake list (user-visible):** `pyq_download_screen` (§1.5); `AiRouterService._searchLocalRag` (mock); `ml_service*` (no model file); `NotificationService` "strict mode" is just a `debugPrint` (`cbt_test_screen.dart:142-147`).

## 9. Part 8 — Architecture (as-built)

- **Layers:** `features → core/providers → core/services → core/database → drift`. Direction is clean; the `providers.dart` barrel is the only sanctioned import path for features.
- **Business logic lives in:** services (exam engine, DPP engine, mastery, mistake classifier, spaced repetition) + a few `StateNotifier`s. Widgets are mostly presentational in the live flows.
- **Violations (minor):** `UserProgressNotifier` couples DB reads with cross-provider reads inside the notifier (`user_providers.dart:442-446`); `AppDatabase` is a hand-rolled singleton with a mutable static (`drift_database.dart:63-75`) — fine for Flutter, but it makes multi-instance test warnings (seen in the DPP test logs) easy to trigger; several `late final` fields in `cbt_test_screen` gated by a `_ready` flag (`:86-89`) instead of typed state.
- **Scalability:** the Drift schema, pagination (`getQuestionsPaginated`), seed idempotency, and sync watermark table indicate a design that can absorb 2 000+ questions and 90+ chapters. The risk is **content authoring** (16 shell notes, 2-chapter chem/phys), not the engine. Sync: `SyncWatermarks` + `content_sync_service` exist but `enableCloudSync` defaults OFF with an honest warning comment (`app_config.dart:83-92`) — treat sync as unproven.

## 10. Part 9 — Gap analysis for launch

| Feature | Status | Evidence | Blocker? |
|---|---|---|---|
| PYQ database (450+ target) | **Missing** (77+10) | §5 PYQ totals | **Y** |
| Revision notes coverage | **Partial** — 22/38 authored, 16 shells | study_resource_content_test failures | **Y** |
| Exam engine (CBT) | **Working** (tested: exam_engine_* 4 suites pass) | §3 | N |
| Progress persistence | **Working** (Drift real writes) | §3 | N |
| Custom paper generator | **Working** (honest degradation) | `question_paper_generator.dart` | N |
| PYQ Downloads screen | **Hidden** (2026-10-29) — `FeatureFlags.pyqDownloads` = false, `/pyq` redirects to `/practice`; screen still exists for re-wiring | `feature_flags.dart`, `app_router.dart` | N (until re-enabled) |
| NCERT PDF reader | **Fixed** (2026-10-29) — mapping verified by `scripts/verify_ncert_mapping.py`, 33 mappings / 0 problems | `ncert_book_catalog.dart`, `test/ncert_book_catalog_test.dart` | N |
| Login/accounts | **Working** (Supabase email + Google, PBKDF2 local, 2FA, lockout — 12 suites pass) | test/auth_*, two_factor | N |
| Cloud sync | **Stub-by-design** (flagged OFF, known defects documented) | `app_config.dart:83-92` | N (if kept off) |
| AI tutor | **Partial** — BYOK-only; RAG mock; proxy OFF by default | §1.7 | N (if labeled) |
| Analytics | **Missing** (no SDK, no self-telemetry) | §7 | N (privacy-positive) |
| Crash reporting | **Missing** | no imports | N- |
| Play Store readiness | **No** — 403 MB assets blow the base-module limit; icons exist; signing guarded | §7 | **Y** |
| Accessibility | **Partial** — 44 dp chips, missing tooltips/semantics, no iOS FaceID plist | §4 | Y (iOS) |
| Content licensing | **Unresolved** — NCERT PDFs bundled; third-party PYQ sources | §7 | **Y** |
| Test suite | **Green** (2026-10-29) — 427/427 pass; format drift still to check | §8 | N (CI) |

## 11. Ranked issues

### Critical (fix before any student uses it)
1. ~~**Wrong NCERT PDFs for all mapped Class-12 Biology chapters + both Physics chapters; 5 mapped PDFs missing.**~~ **Fixed 2026-10-29.** `ncert_book_catalog.dart` was re-mapped to the rationalised numbering and verified by `scripts/verify_ncert_mapping.py` (33 mappings, 0 problems); `test/ncert_book_catalog_test.dart` guards it.
2. ~~**Fake "PYQ Downloads" screen**~~ **Hidden 2026-10-29.** `FeatureFlags.pyqDownloads` is false by default and `/pyq` redirects to `/practice`; the source list was cut to 9 verified PDFs with a `%PDF` check. Re-enable only after verified 2024/2025 PDFs exist.
3. **Question bank 77 vs 450+** — Chemistry has 10 questions across 2 chapters, Physics 10 across 2. A "Chemistry full mock" is impossible; `hasSufficientPool` will refuse (`exam_engine_service.dart:550-563`), which is graceful but the marketing/UI must not imply full coverage.
4. **Committed API key** `docs/STAGING_BOOTSTRAP.md:116` — remove + rotate; add the file pattern to the CI scan.
5. **16 empty note chapters visible to students** — either author them or hide the chapters until authored. (The 3 literal "Chapter 20/21/22" placeholders were deleted on 2026-10-29.)

### High
6. **403 MB of PDFs in the app bundle** — Play base-module limit (150 MB) makes the AAB unshippable; move PDFs to on-demand delivery (play `asset packs` / remote download like `pyq_downloader`) and keep the catalog lazy.
7. ~~**iOS FaceID plist missing** (`ios/Runner/Info.plist`) while biometric lock is a headline feature.~~ **Fixed 2026-10-31** — `NSFaceIDUsageDescription` added; still needs a device test.
8. **DPP forceRefresh duplicates the day's set** (`dpp_engine.dart:323-389`) — failing test demonstrates it; add `deleteDppSet(existing.id)` (or reuse-by-replace) in the forceRefresh path.
9. ~~**9 failing tests + 10 unformatted files**~~ — **tests fixed 2026-10-29: 427/427 pass.** `dart format` drift still to check.
10. **Delete or land the untracked WIP** (`lib/features/exam/`, `tools/experiments/*.dart`): they contribute 457 analyze errors, the shadowed-palette bug, the second exam model, and the only deprecated-API usages in the tree. *Note 2026-10-29: the repository owner has asked that `lib/features/exam/nta_exam_screen.dart` be left untouched, so it is excluded from this recommendation until they say otherwise.*

### Medium / low
11. Cert-pinning expiry 2026-12-31 (`network_security_config.xml:6`) — schedule a rotation.
12. Third-party PYQ JSON imported without schema validation beyond the importer (`pyq_downloader_service.dart`) — consider signing/allowlisting or at least a sanity gate.
13. Unused deps (`groq`, `google_fonts`, `confetti`, `intl`, `permission_handler`, `flutter_hooks`, `state_notifier`) and orphaned `assets/fonts/` — remove or wire in.
14. Accessibility: 44 dp palette chips, missing tooltips (e.g. `subjects_tab.dart:28`), no semantics on palette numbers.
15. `nta_exam_screen.dart` strict-mode "proctoring" is a `debugPrint` stub while the UI implies enforcement (`cbt_test_screen.dart:142-147`).
16. `bio_ch5_12` formula-list artifact string (§6.1) — delete the line.
17. `quiz_providers.dart:87` computes accuracy as `score/selectedAnswers.length` — a 0-answer session yields 0/0 (NaN) depending on call order; guard it.
18. Checked-in stale log `analyze_output.txt` and `.pi/`, `.pi-subagents/`, `.vs/` artifacts in git — repo hygiene.

## 12. Content gap vs targets

| Metric | Actual | Target | Gap |
|---|---|---|---|
| PYQ questions | 77 (+10 JSON) | 450+ | **−373 (−83%)** |
| Chemistry questions | 10 | ~150 | −93% |
| Physics questions | 10 | ~150 | −93% |
| Chapters modeled | 38 (bio 34 / chem 2 / phys 2) | ~97 (old ed.) / ~79 (rationalized) | −61% / −52% |
| Authored revision notes | 22 | 38 (own catalog) / ~79 | 16 shells; −58% vs full NCERT |
| Verified-wrong answers | **0 of 77** | 0 | ✓ |

## 13. Recommended next 5 actions (in order)

1. ~~**Content triage sprint (2–3 days):** fix the Class-12/Physics PDF mapping (mechanical), add the 5 missing PDFs or hide those chapters, delete the 3 placeholder chapters, remove the `bio_ch5_12` artifact line.~~ **Done 2026-10-29** — mapping re-verified (33/33), placeholders deleted, removed-syllabus chapters badged.
2. ~~**Kill or wire the fake PYQ Downloads screen** and route it to the real downloader (Settings path already works).~~ **Done 2026-10-29** — hidden behind `FeatureFlags.pyqDownloads` (default false), `/pyq` → `/practice`, source list cut to 9 verified PDFs with a `%PDF` check. Wiring needs verified 2024/2025 PDFs and a redistribution decision.
3. **Repo hygiene pass (0.5 day):** commit-or-delete the 39 modified files; delete `tools/experiments/*.dart` scratch files and the dead `lib/features/exam/` + `exam_model.dart` + `modern_home_screen` + `learn_hub/practice_hub/review_tab` + `pyq_pdf_downloader_service`; remove the 8 unused deps; run `dart format`. Result: analyze 0 errors, tests green (427/427 as of 2026-10-29), CI green.
4. **Question bank expansion sprint 1 (1–2 weeks):** Chemistry + Physics to ≥50 chapters / ≥250 questions total, prioritizing high-weight chapters already in the DPP/mastery engines; add automated answer-key review (the existing `validatePool` + a new "two reviewers per question" gate) before each batch lands.
5. **Ship-readiness (3–4 days):** move NCERT PDFs to on-demand asset delivery (or first-run download with the existing downloader pattern), bump pin-set expiry, **rotate the committed key** (redacted 2026-10-31, still in history), then a real `flutter build appbundle --release` size test. (`NSFaceIDUsageDescription` added 2026-10-31.)

## 14. Unknowns (could not verify, and why)

- **PYQ year/shift attributions** (`year: 20XX`, "PYQ-20XX" tags): `pdftotext` is not installed on this machine and the 10 PDFs in `NEET_PYQ/` are untracked reference material — I could not machine-verify which paper each question came from. Treat years as unverified.
- **Exact NCERT edition of every PDF** was verified by title extraction for 9 files (the basis of the mapping findings); the remaining ~74 were assumed consistent with those — spot-check the rest when re-mapping.
- **Runtime behavior of the 5 missing PDFs** (error handling in `ncert_pdf_screen.dart` was not exercised on a device).
- **Supabase backend behavior** (RLS enforcement, Edge Function auth) — SQL files and functions were read, but no live project was queried.
- **`google-services.json` key restrictions** — whether the committed `AIza…` keys are API-restricted cannot be determined from the repo.
- **Whether `dart format` failures are committed or local-only** — the 10 unformatted files include tracked files (`topic_detail_screen.dart`, `study_resource_content_test.dart`), so CI format job fails as-is.
- **iOS build** could not be compiled/verified on this Windows machine; the FaceID plist gap is from static inspection.
- The prompt's referenced files `sample_questions.dart`, `quiz_screen.dart`, `SmartQuestionGenerator`, `PYQDatabase` **do not exist** in this tree; the audit mapped those intents onto their real counterparts (seed constants, `enhanced_quiz_screen`, `QuestionPaperGenerator`, the Drift `questions` table + repositories). The "65/33/78" home percentages also don't exist in the current tree (nearest: hard-coded 0.75/0.60/0.55 in dead `modern_home_screen.dart:214-233`).
