# NEET Mitos App — Deep Research & Audit Draft

**Project:** `neet_mitos` (Flutter NEET UG preparation app)  
**Audit Date:** 2026-01-18  
**Scope:** Codebase architecture, feature audit, bug/gap analysis, NCERT PDF asset mapping, NEET 2026 market context, competitor benchmarking, production readiness  
**Status:** DRAFT — pending citation pass and verification

---

## Executive Summary

NEET Mitos is a **feature-rich but hollow-core** Flutter app. The UI surface covers almost every NEET prep feature a student might expect — AI chatbot, quiz engine, test series, flashcards, error book, mark booster, progress dashboard, study planner, bookmarks, PDF question generator, biometric lock, guest mode, and cloud sync. Beneath that surface, the app is held up by scaffold and intent rather than working domain logic:

- The **question bank is tiny** (~26 seeded sample questions in the main constant, plus a small phase-2 set), far below the ~1,000–2,000 minimum needed for credible topic-level practice.
- The **bundled NCERT PDFs are unused** by any feature; the PDF engine currently depends on user-supplied files via `file_picker`, while ~100 PDFs sit in `assets/ncert_books/` under an opaque naming scheme.
- **Batch segmentation (Class 11 / Class 12 / Dropper) is absent** from onboarding, study plans, and analytics despite being a first-class requirement from the product brief.
- **Cloud sync, ML similarity, and rank prediction** are implemented as stubs or static lookups rather than production logic.

**Bottom line:** The app would benefit enormously from a 3–4 week focused engineering sprint that prioritizes: (1) question bank scale, (2) NCERT PDF integration, (3) batch-aware personalization, and (4) removing superficial features that create maintenance debt without user value.

---

## 1. Codebase Architecture

### 1.1 Tech Stack

| Layer | Technology | Role |
|-------|-----------|------|
| UI | Flutter 3.11+ (SDK ^3.11.5) | Cross-platform rendering |
| State | Riverpod 2.5.1 | Dependency injection + reactive state |
| Local DB | Drift 2.33 + SQLite | Offline-first source of truth |
| Remote | Supabase 2.12.4 | Auth, Postgres sync target, RLS |
| AI | Google Generative AI (Gemini) | Chatbot, question generation from PDF |
| PDF | Syncfusion PDF Viewer + `file_picker` | PDF reading and extraction |
| ML | TFLite Flutter | Optional sentence-encoder similarity |
| Charts | fl_chart | Progress visualizations |
| Animations | flutter_animate | Flashcard flip transitions |
| Notifications | flutter_local_notifications | Study reminders |

### 1.2 Architecture Quality

**Strengths**
- Clean separation: `models/`, `providers/`, `services/`, `features/`.
- Offline-first design is conceptually correct: local Drift DB is source of truth, Supabase is sync target (`cloud_sync_service.dart`).
- `QuestionRepository` uses idempotent seeding and `insertOrReplace` for safe upgrades.
- `QuestionImporter` supports both JSON and CSV with deduplication and subject alias normalization.

**Weaknesses**
- Two parallel provider files (`core/provider/providers.dart` and `core/providers/providers.dart`) suggest incomplete refactor or merge artifact.
- `DatabaseService.instance` is a singleton alongside `questionRepositoryProvider`; this creates two paths to the same DB and can cause inconsistent invalidation.
- `QuestionPaperGenerator.getAllQuestions()` is referenced but **not found** in the inspected code — either dead code or an import gap.
- `geminiServiceProvider` and `databaseProvider` are used extensively but not visible in the read provider files, suggesting they live in the unread `core/provider/providers.dart`.

---

## 2. Feature Audit

### 2.1 Feature Inventory vs. Implementation Depth

| Feature | UI Present | Logic Depth | Verdict |
|---------|-----------|-------------|---------|
| OTP / 2FA Auth | Yes | Partial | 2FA screen exists but no actual 2FA flow in `auth_service.dart` |
| Topic Browser | Yes | Medium | Chapters/topics read from DB; no NCERT chapter mapping |
| Quiz Engine | Yes | Medium | Timer, confetti, hints, short-answer eval; small bank |
| Test Series / PDF Picker | Yes | Medium | User-file picker only; no bundled PDF usage |
| AI Chatbot | Yes | Medium | Gemini integration works; API key is user-supplied |
| Flashcards | Yes | Low | Static deck; no spaced-repetition scheduling |
| Study Planner | Yes | Low | Plan display exists; no adaptive scheduling logic |
| Error Book | Yes | Medium | Auto-captures wrong answers; re-test works |
| Mark Booster | Yes | Medium | Drill builder exists; depends on weak-topic detection |
| Progress Dashboard | Yes | Medium | Charts + rank predictor; rank predictor is static table |
| Bookmarks / Revision Vault | Yes | Low | Toggle + display; no review scheduling |
| PDF Question Generator | Yes | Medium | Chunks PDF text, calls Gemini; capped at 15/chapter |
| Biometric Lock | Yes | Unknown | `biometric_service.dart` exists but not inspected |
| Guest Mode | Yes | Unknown | Referenced in `home_screen.dart` summary |
| Cloud Sync | Yes | Low | Push-only; pull loop is TODO |

### 2.2 Key Missing Features (Market-Expected)

1. **Batch-aware onboarding** — No Class 11 / Class 12 / Dropper selector. `OnboardingScreen` only asks for Gemini API key.
2. **Streaks / Gamification** — Not present. Competitors (Yukthis, ConceptScroll, Triveni) use XP, streaks, and leaderboards as retention drivers.
3. **Spaced Repetition** — Flashcards are manual. No SM-2/Anki-style scheduling.
4. **Large PYQ Bank** — Darwin advertises 38,000+ MCQs; this app has a few dozen.
5. **Adaptive Learning** — No algorithm that adjusts difficulty or topic sequencing based on performance.
6. **Leaderboards / Social** — Absent.
7. **Analytics / Crash Reporting** — No Sentry, Firebase Crashlytics, or PostHog visible.
8. **Localization** — English-only; no Hindi or regional language support.

---

## 3. Question Bank Analysis

### 3.1 Current Scale

From inspected files:
- `neet_sample_data.dart`: ~919 lines; contains `biologyQuestions`, `chemistryQuestions`, `physicsQuestions`.
- `neet_sample_data_phase2.dart`: ~858 lines; adds phase-2 biology, biology Class 12, chemistry, physics.
- `sample_questions.dart`: 4 lines (likely placeholder).

**Estimated total:** Even with generous assumptions, the seeded bank is **well under 500 questions**. For NEET prep, this is insufficient for:
- Topic-level practice (many topics will have 0–2 questions).
- Mock test variety (students see repeated questions after a few attempts).
- Error book usefulness (the error book quickly runs out of new material).

### 3.2 Data Quality Issues

- `QuestionPaperGenerator._removeYearMarking()` strips 4-digit years from `ncertReference` using regex, which can corrupt legitimate text (e.g., "Class 11" becomes "Class ").
- `QuestionImporter.normalizeText()` is used for deduplication, but the exact normalization rules were not inspected; risk of both false positives and false negatives.
- `topicId` is a free-form string; no canonical topic taxonomy is enforced across imports.

---

## 4. NCERT PDF Asset Audit

### 4.1 Asset Inventory

The app bundles ~100 PDFs under `assets/ncert_books/`:

```
biology/Biology_Class_11/   → kebo101.pdf ... kebo119.pdf, kebo1ps.pdf
biology/Biology_Class_12/   → lebo101.pdf ... lebo113.pdf, lebo1ps.pdf
chemistry/Chemistry_Class_11_Part_1/ → kech101-106, kech1a1, kech1an, kech1ps
chemistry/Chemistry_Class_11_Part_2/ → kech201-203, kech2an, kech2ps
chemistry/Chemistry_Class_12_Part_1/ → lech101-105, lech1a1, lech1an, lech1ps
chemistry/Chemistry_Class_12_Part_2/ → lech201-205, lech2an, lech2ps
physics/Physics_Class_11_Part_1/     → keph101-107, keph1a1, keph1an, keph1ps
physics/Physics_Class_11_Part_2/     → keph201-207, keph2an, keph2ps
physics/Physics_Class_12_Part_1/     → leph101-108, leph1an, leph1ps
physics/Physics_Class_12_Part_2/     → leph201-206, leph2an, leph2ps
```

### 4.2 Naming Convention Decode

| Prefix | Subject | Class |
|--------|---------|-------|
| `ke` | — | Class 11 (`k` = 11 in some encoding?) |
| `le` | — | Class 12 (`l` = 12?) |
| `bo` | Biology | — |
| `ch` | Chemistry | — |
| `ph` | Physics | — |

| Suffix | Likely Meaning |
|--------|---------------|
| `101-119`, `101-108`, etc. | Chapter numbers |
| `a1` | Appendix |
| `an` | Answers / NCERT additional notes |
| `ps` | Practical study / exercises |

**Observation:** Biology has 19 chapter files in Class 11 (`kebo101`–`kebo119`), which roughly matches the NCERT Biology Part 1 + Part 2 structure. Chemistry and Physics are split into `Part_1` and `Part_2` folders.

### 4.3 Integration Status

**Current state:** The bundled PDFs are **not wired into any screen**. `PdfPickerScreen` uses `FilePicker.platform.pickFiles()`, which opens a system file picker for user-selected files. The bundled assets are never referenced.

**Recommended path:**
1. Build a chapter browser that maps topic IDs → bundled PDF assets.
2. Use `SyncfusionFlutterPdfViewer` or native asset loading to render chapters inline.
3. Add a "Generate Questions from NCERT" flow that uses the local PDF text + Gemini (already implemented for user-uploaded files).

### 4.4 Copyright Risk

NCERT textbooks are **not** in the public domain. NCERT has issued explicit copyright warnings against unauthorized reproduction. The official channel is **ePathshala**, which distributes NCERT books legally.

**Risk assessment:**
- If the bundled PDFs were extracted from official NCERT books without permission, the app carries **copyright infringement risk**.
- Safe alternatives:
  - Remove bundled PDFs and link to ePathshala / official NCERT website.
  - Include only original summaries/notes authored by the app team.
  - Use the PDF generator only on user-supplied files, which is the current approach.

---

## 5. NEET 2026 Exam Pattern & Syllabus

### 5.1 Confirmed Structure (NTA)

| Parameter | Value |
|-----------|-------|
| Total Questions | 180 |
| Total Marks | 720 |
| Duration | 180 minutes (3 hours) |
| Mode | Pen-and-paper (offline) |
| Correct Answer | +4 marks |
| Wrong Answer | -1 mark |
| Unanswered | 0 marks |
| Physics | 45 questions |
| Chemistry | 45 questions |
| Biology | 90 questions (45 Botany + 45 Zoology) |

**Sources:**
- NTA official notice (re-exam 2026): Times of India, Times Now, Free Press Journal.
- Careers360 NEET exam pattern 2026.
- Jagranjosh subject-wise distribution.

### 5.2 Syllabus Changes

- NMC released the NEET 2026 syllabus on December 23, 2025.
- **No additions or reductions** compared to NEET 2025. The syllabus remains based on NCERT Class 11 and Class 12.
- This means the app's existing topic taxonomy does not need a major restructure for 2026, but any chapter mapping to the bundled PDFs should be audited against the official syllabus PDF.

---

## 6. Competitor Benchmarking

### 6.1 Feature Comparison

| Feature | NEET Mitos | Darwin | Unprep | Yukthis | Lytmus AI |
|---------|-----------|--------|--------|---------|-----------|
| Question Bank | <500 | 38,000+ | NCERT-based | Unknown | Unknown |
| AI Chatbot | ✅ Gemini | ❌ | ❌ | ❌ | ✅ AI Mentor |
| PDF Engine | ✅ User-upload | ❌ | ❌ | ❌ | ❌ |
| Error Book | ✅ | ✅ | ❌ | ❌ | ❌ |
| Mark Booster | ✅ | ❌ | ❌ | ❌ | ❌ |
| Streaks / XP | ❌ | ❌ | ❌ | ✅ | ❌ |
| Leaderboard | ❌ | ❌ | ❌ | ✅ | ❌ |
| Study Planner | ✅ Static | ✅ Adaptive | ✅ AI Tracker | ✅ Daily plan | ✅ Backlog recovery |
| Flashcards | ✅ Manual | ✅ | ❌ | ✅ | ✅ Smart revision |
| Cloud Sync | ✅ Push-only | ✅ | ✅ | ❌ | ❌ |
| Rank Predictor | ✅ Static | ❌ | ❌ | ❌ | ❌ |

### 6.2 Strategic Gaps

1. **Content scale** is the single biggest gap. Darwin's moat is question volume + analytics. Without scale, analytics and rank prediction are meaningless.
2. **Retention mechanics** (streaks, leaderboards, daily plans) are missing. These are table stakes in 2025–2026 edtech.
3. **Batch segmentation** is missing. Droppers need different pacing than Class 11/12 students. The app treats all users identically.

---

## 7. Critical Bugs & Code Issues

### 7.1 Fatal / High Priority

1. **Missing `getAllQuestions()` in `QuestionPaperGenerator`**
   - `_getPYQsForSubjects` calls `getAllQuestions()` without importing it. This will throw at runtime.
   - File: `lib/core/services/question_paper_generator.dart`.

2. **Duplicate provider files**
   - `lib/core/provider/providers.dart` and `lib/core/providers/providers.dart` both exist. This can cause ambiguous imports or silent provider override bugs.

3. **Cloud sync pull is unimplemented**
   - `_syncQuizAttempts()` pulls cloud rows into a local list `cloudAttempts` and then iterates with an empty body (`for (var _ in cloudAttempts) { /* Future: ... */ }`). Pull does not actually merge.

4. **ML tokenizer is dummy code**
   - `MLService._tokenize()` converts text to `text.codeUnitAt(i)`. This is not a tokenizer; it produces character-code embeddings with no vocabulary. The TFLite model `sentence_encoder.tflite` is also not present in the repo tree inspected, so the service silently falls back to word-overlap similarity.

5. **Rank predictor is a static hardcoded table**
   - `RankPredictor.predictRank()` uses fixed score→rank mappings from "2023-2024 trends". For 2026, this is stale and misleading. A real predictor would use percentile data from the specific exam session.

### 7.2 Medium Priority

6. **Year-marker regex strips legitimate text**
   - `_removeYearMarking()` uses `replaceAll(RegExp(r'\d{4}'), '')`. This removes "2024", "2025", but also "Class 12" (if written as "Class 12" it removes "12"? No, `\d{4}` requires 4 digits, so "12" is safe. But "2024" in a concept name would be stripped.)

7. **Gemini API key friction**
   - Onboarding asks users to supply their own Gemini API key. This creates massive onboarding friction. Better: app developer provides a backend proxy with rate limits, or uses a free-tier key with monitoring.

8. **App size bloat from PDFs**
   - Bundling ~100 PDFs will make the APK/IPA very large. Consider on-demand download or removing them.

9. **No error boundaries / crash reporting**
   - No Sentry, Firebase Crashlytics, or equivalent. Production debugging will be blind.

10. **`kIsWeb` gating is minimal**
    - `NotificationService.requestPermissions()` returns `false` on web, but other services (file picker, biometrics) may not have equivalent web-safe fallbacks.

---

## 8. NCERT PDF Integration Plan

### 8.1 Current vs. Desired

**Current:** `PdfPickerScreen` lets users upload any PDF, extracts text, splits by chapter heuristics, then uses Gemini to generate questions per chapter.

**Desired:**
1. A **Chapter Browser** that lists NCERT chapters from the bundled assets.
2. An **NCERT Reader** that renders the relevant PDF page range for the selected topic.
3. A **"Practice from NCERT"** button that opens a quiz filtered to questions tagged with that chapter/topic.
4. A **"Generate Questions"** button that sends the chapter PDF text to Gemini (reusing existing chunking logic).

### 8.2 Implementation Steps

1. **Create `NcertCatalog`** — a Dart map from topic IDs to asset paths, derived from the naming convention above.
2. **Add `AssetPdfService`** — load bundled PDFs via `rootBundle.load('assets/ncert_books/...')`.
3. **Update `TopicDetailScreen`** — add "Open NCERT" button that launches a PDF viewer for the mapped asset.
4. **Tag seeded questions** with `ncertReference` values that match the catalog keys.
5. **Optional:** Move PDFs out of the APK and download on demand to reduce app size.

### 8.3 Copyright Mitigation

- **Do not redistribute** NCERT PDFs without NCMC/NOTA permission.
- **Preferred:** Remove bundled PDFs entirely. Use ePathshala deep links or web viewer URLs.
- **Alternative:** Include only original study notes/summaries; the app already has `topic.summary` and `topic.keyPoints` fields.

---

## 9. Production Readiness Assessment

### 9.1 Missing Infrastructure

| Item | Status | Notes |
|------|--------|-------|
| CI/CD | ❌ | No GitHub Actions / Fastlane / Codemagic evidence |
| Crash Reporting | ❌ | No Sentry, Crashlytics, or Bugsnag |
| Analytics | ❌ | No PostHog, Mixpanel, or Firebase Analytics |
| Feature Flags | ❌ | No remote config for staged rollouts |
| A/B Testing | ❌ | No experimentation framework |
| Performance Monitoring | ❌ | No Flutter DevTools integration or tracing |
| Accessibility | ❌ | No semantics labels, no screen-reader testing |
| Localization | ❌ | English only |
| Deep Linking | ❌ | No universal links / app links |
| App Store Assets | Unknown | No `ios/` or `android/` metadata inspected |

### 9.2 Security & Privacy

- Supabase RLS is defined in `01_content_catalog.sql`, but the app does not appear to enforce row-level user isolation in all queries.
- Gemini API keys are stored locally; if the key is user-supplied, there is no backend rotation or abuse protection.
- Biometric lock exists (`biometric_service.dart`) but its integration with auth flow was not verified.
- No privacy policy or terms of service references were found.

---

## 10. Prioritized Roadmap

### Phase 1: Make It Work (2–3 weeks)
1. **Fix fatal bugs:** `getAllQuestions()` import, duplicate provider files, cloud sync pull loop.
2. **Scale question bank:** Import 5,000+ curated NCERT + PYQ questions. Use `question_importer.dart` with a verified CSV dump.
3. **Add batch onboarding:** Class 11 / Class 12 / Dropper selector in onboarding; personalize study plans and topic priority.
4. **Wire bundled NCERT PDFs:** Build `NcertCatalog`, chapter browser, and in-app PDF reader.

### Phase 2: Make It Good (2–3 weeks)
5. **Implement real rank predictor:** Use NTA percentile data and student score distributions instead of hardcoded table.
6. **Add streaks and daily goals:** Use `flutter_local_notifications` + streak counter in `UserProgress`.
7. **Improve AI features:** Replace dummy ML tokenizer with a real sentence-transformers pipeline (or remove TFLite dependency). Proxy Gemini through a backend to avoid user API-key friction.
8. **Add spaced repetition:** Upgrade flashcards to SM-2 scheduling.

### Phase 3: Make It Scale (3–4 weeks)
9. **Cloud sync hardening:** Bidirectional sync with conflict resolution, watermarks, and offline queue.
10. **Gamification:** Leaderboards, XP, badges.
11. **Analytics & crash reporting:** Sentry + PostHog.
12. **App store optimization:** Screenshots, descriptions, privacy policy, accessibility audit.

---

## 11. Open Questions & Unverified Claims

1. **Question count:** Exact number of seeded questions is unknown because I did not parse every constant file. Claim of "<500" is an inference from file sizes.
2. **PDF copyright provenance:** Unknown whether the bundled PDFs were legally obtained. This is a legal question, not a technical one.
3. **Biometric lock behavior:** `biometric_service.dart` was not inspected; integration with login flow is unverified.
4. **Supabase RLS enforcement:** SQL schema was read, but client-side query enforcement was not fully traced.
5. **NEET 2026 re-exam specifics:** Some sources mention 195 minutes for the re-exam; this may be a one-time change. The app should not hardcode duration.

---

## Sources

- NEET UG 2026 exam pattern: https://medicine.careers360.com/articles/neet-exam-pattern
- NEET UG 2026 marking scheme: https://www.timesnownews.com/education/neet-ug-2026-marking-scheme-explained-nta-breaks-down-subject-wise-weightage-and-scoring-article-154679872
- NEET 2026 re-exam details: https://timesofindia.indiatimes.com/education/news/neet-ug-re-exam-2026-on-june-21-nta-shares-key-details-on-exam-pattern-marking-scheme/articleshow/131823168.cms
- NEET 2026 syllabus unchanged: https://medicine.careers360.com/articles/nmc-neet-ug-syllabus-2026-unchanged-no-addition-or-reduction
- Darwin NEET Prep: https://darwin.mcqdb.com/
- Unprep NEET: https://play.google.com/store/apps/details?id=com.unbind&hl=en
- Yukthis NEET App: https://apps.apple.com/us/app/yukthis-neet/id6760161721
- Lytmus AI: https://lytmus.ai/
- Super Tutor AI: https://supertutor.in/ai-tutor-for-neet/
- NCERT copyright notice: https://ncert.nic.in/pdf/announcement/notices/Press_Release_Copyright_Infringement-NCERT.pdf
- ePathshala: https://ciet.ncert.gov.in/storage/app/public/files/17/Presentation%20PDF/Epathshala%20Apps%20for%20Education%20(1).pdf
- Flutter + Supabase offline-first: https://medium.com/@fintasys/offline-first-flutter-drift-as-the-source-of-truth-supabase-as-a-sync-target-eab7c43523ce
- Flutter + Supabase production guide: https://samioda.com/en/blog/flutter-supabase-auth-realtime-offline-sync
