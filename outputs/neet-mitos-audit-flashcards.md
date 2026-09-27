# NEET Mitos App — Broken Logic, Missing Features & Flashcards Overhaul

> Generated: 2025-08-17
> Scope: Full codebase audit + NotebookLM-style flashcards redesign

---

## 1. BROKEN LOGIC & MISSING CORE FUNCTIONS

### 1.1 Critical Production Blockers

| # | Issue | Severity | Location | Impact |
|---|-------|----------|----------|--------|
| 1 | **Direct Gemini API calls from client** | P0 | `gemini_chat_service.dart` | Every student with an API key hits Gemini directly. No caching, no rate limiting, no fallback. App will fail at scale. |
| 2 | **No AI response cache / proxy** | P0 | Missing | Same question asked 1000 times = 1000 API calls. Target should be <1% cache-miss rate. |
| 3 | **Tiny question bank (77 sample questions)** | P0 | `neet_sample_data.dart` | Not enough for a real NEET mock test. Need 5,000+ verified MCQs. |
| 4 | **No explanation pre-seeding pipeline** | P0 | Schema exists, data empty | `questions.explanation` column exists but 95% of rows have no explanation. AI tutor degrades to "Error: no explanation available." |
| 5 | **Syncfusion PDF trial watermark** | P0 | `pubspec.yaml` / `ncert_pdf_screen.dart` | Visible watermark on every PDF page until commercial license is purchased. |

### 1.2 High-Priority Logic Gaps

| # | Issue | Severity | Location | Impact |
|---|-------|----------|----------|--------|
| 6 | **Flashcards are hardcoded skeletons** | P1 | `flashcard_screen.dart`, `providers.dart` | Only 3 sample cards. No chapter linkage, no AI generation, no SM-2 scheduling for cards. |
| 7 | **No offline fallback for AI Tutor** | P1 | `gemini_chat_service.dart` | If API key missing + no cached explanation → returns error string. No graceful degradation. |
| 8 | **Spaced repetition only for questions, not flashcards** | P1 | `spaced_repetition_service.dart` | SM-2 engine exists but `SpacedRepetitionData` is keyed by `questionId`, not `flashcardId`. Flashcards don't get scheduled reviews. |
| 9 | **No NCERT citation / deep-link from AI responses** | P1 | `gemini_chat_service.dart` | Gemini prompt asks for NCERT reference but response is not parsed or stored. No "View in NCERT" action. |
| 10 | **No study plan persistence** | P1 | `gemini_chat_service.dart` | `generateStudyPlan()` returns text but isn't saved to DB or shown in a dedicated screen. |
| 11 | **No mock test history** | P1 | CBT engine complete | Results are computed and shown once, then lost. No history list, no trend analysis, no comparison. |
| 12 | **Profile screen is empty** | P1 | `profile_screen.dart` | No stats, no achievements, no activity timeline, no edit profile. |
| 13 | **No error boundaries / crash reporting** | P2 | `main.dart` | No Sentry/Firebase Crashlytics. Production crashes are silent. |
| 14 | **Notification service is minimal** | P2 | `notification_service.dart` | Only one daily reminder. No streak-save reminders, no test-schedule reminders, no topic-specific nudges. |
| 15 | **Auth UI exists without backend logic** | P2 | `auth_screen.dart`, `otp_screen.dart` | OTP/2FA screens exist but no actual Supabase email auth wiring visible in code. |
| 16 | **No data export for students** | P2 | Settings screen | GDPR/student-rights feature missing. Can't export progress, bookmarks, or flashcards. |
| 17 | **PDF service has no OCR / text quality metrics** | P2 | `pdf_service.dart` | Text extraction works but no fallback for scanned PDFs, no confidence scores. |
| 18 | **No accessibility support** | P2 | Global | No screen reader labels, no font scaling, no high-contrast mode. |
| 19 | **Zero widget test coverage for screens** | P2 | `test/` | 0 screen imports in tests. UI regressions are untested. |
| 20 | **Question importer lacks validation** | P3 | `question_importer.dart` | No schema validation, no duplicate detection, no NCERT reference validation. |

### 1.3 Medium / Nice-to-Have Gaps

| # | Issue | Severity | Location | Impact |
|---|-------|----------|----------|--------|
| 21 | **No leaderboards or social features** | P3 | Missing | No peer comparison, no ranks, no study groups. |
| 22 | **No dark/light theme for PDF viewer** | P3 | `ncert_pdf_screen.dart` | Syncfusion viewer may not respect app theme. |
| 23 | **No biometric fallback** | P3 | `biometric_service.dart` | If biometric fails, app locks out. No PIN fallback. |
| 24 | **No background content sync** | P3 | `cloud_sync_service.dart` | Sync only happens on app open. No periodic background refresh. |
| 25 | **No onboarding progress tracking** | P3 | `onboarding_screen.dart` | Doesn't save which step user was on if they close app mid-onboarding. |

---

## 2. FLASHCARDS — CURRENT STATE vs. NOTEBOOKLM TARGET

### 2.1 What We Have Now (Broken / Skeletal)

```
Flashcard Model: { id, front, back, subject, topicId, imageUrl? }
  └── NO: chapterId, ncertReference, sourcePage, difficulty, deckId, isGenerated
  └── NO: spaced repetition fields (easeFactor, interval, dueAt, box)

Flashcard Screen: PageView + flip animation
  └── Shows 3 hardcoded cards from sampleFlashcards
  └── NO: chapter selector, quantity picker, AI generation button
  └── NO: self-assessment (Got it / Needs review)
  └── NO: "View in NCERT" deep link
  └── NO: progress tracking

Providers:
  └── flashcardsProvider → returns sampleFlashcards (static list)
  └── NO: flashcard generation provider
  └── NO: dueFlashcardsProvider (SM-2 driven)
  └── NO: flashcardStatsProvider

Services:
  └── NO: flashcard_generation_service.dart
  └── NO: flashcard_scheduler_service.dart
```

### 2.2 NotebookLM-Style Flashcard Flow (Target)

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: SOURCE SELECTION                                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ Subject     │  │ Chapter     │  │ Quantity Selector       │  │
│  │ Dropdown    │  │ Dropdown    │  │ [10] [20] [50] [100]   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
│                                                                  │
│  [✨ Generate NCERT Flashcards]                                  │
│  └── AI scans selected NCERT PDFs → extracts key concepts       │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: GENERATION (AI-POWERED)                                │
│  Input: NCERT chapter text (from bundled PDFs)                  │
│  Process:                                                       │
│    1. Paragraph segmentation                                     │
│    2. Key concept extraction (definitions, formulas, facts)     │
│    3. Q&A pair generation with source grounding                 │
│  Output: Flashcard[] with:                                       │
│    - front: concise question / key term                         │
│    - back: short, accurate answer (NCERT-grounded)              │
│    - ncertReference: "Class 11, Ch 1, p.7"                      │
│    - sourcePage: 7                                               │
│    - chapterId: "bio_c1"                                         │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: ACTIVE RECALL (Flip Card UI)                           │
│                                                                  │
│   ┌─────────────────────────────────────┐                        │
│   │                                     │                        │
│   │   FRONT: "What is mitochondria?"    │                        │
│   │                                     │                        │
│   │   [Tap to flip]                     │                        │
│   │                                     │                        │
│   └─────────────────────────────────────┘                        │
│                                                                  │
│   ┌─────────────────────────────────────┐                        │
│   │                                     │                        │
│   │   BACK: "Powerhouse of the cell..." │                        │
│   │                                     │                        │
│   │   [View in NCERT] [Got it] [Again]  │                        │
│   │                                     │                        │
│   └─────────────────────────────────────┘                        │
│                                                                  │
│  Self-Assessment:                                                │
│    • Got it → SM-2 interval increases (1→3→7→21 days)           │
│    • Needs Review → resets to day 1, moves to end of queue       │
└─────────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: REVISION LAYER (SM-2 + Leitner)                        │
│  • Due cards queue (driven by SpacedRepetitionService)           │
│  • New / Learning / Review / Mastered tabs                       │
│  • Per-chapter mastery stats                                     │
│  • Deck analytics: retention rate, average interval              │
└─────────────────────────────────────────────────────────────────┘
```

### 2.3 Required Files for NotebookLM-Style Flashcards

| File | Purpose | Status |
|------|---------|--------|
| `lib/core/models/flashcard_model.dart` | Extend with chapterId, ncertReference, sourcePage, difficulty, deckId, isGenerated, easeFactor, intervalDays, dueAt, box, lapses | 🔄 Needs update |
| `lib/core/database/tables/flashcards_table.dart` | Drift table for persistent flashcard storage | ❌ Missing |
| `lib/core/services/flashcard_generation_service.dart` | AI service: NCERT text → Q&A flashcards with citations | ❌ Missing |
| `lib/core/services/flashcard_scheduler_service.dart` | SM-2 + Leitner scheduler for flashcards (reuse spaced_repetition_service logic) | ❌ Missing |
| `lib/features/flashcards/flashcard_generate_screen.dart` | UI: Subject/Chapter/Quantity picker → Generate → Loading → Deck ready | ❌ Missing |
| `lib/features/flashcards/chapter_flashcard_screen.dart` | Study UI: Flip cards + self-assessment + NCERT deep-link | ❌ Missing |
| `lib/features/flashcards/flashcard_deck_screen.dart` | Deck management: Browse decks, view stats, continue studying | ❌ Missing |
| `lib/core/providers/flashcard_providers.dart` | Providers: flashcardDecksProvider, dueFlashcardsProvider, flashcardStatsProvider | 🔄 Needs update |

---

## 3. RECOMMENDED IMPLEMENTATION ORDER

### Phase 1: Fix Broken Core (P0)
1. **Edge Function proxy for Gemini** — 1 turn
2. **AI response cache table + migration** — 30 mins
3. **Wire client through proxy** — 30 mins
4. **Fix Syncfusion watermark** — purchase license or switch to open-source PDF viewer

### Phase 2: Flashcards Overhaul (P1)
5. **Extend Flashcard model** — add chapterId, ncertReference, SM-2 fields
6. **Create flashcards_table.dart** — Drift schema
7. **Build flashcard_generation_service.dart** — NCERT text → flashcards
8. **Build flashcard_scheduler_service.dart** — SM-2 for flashcards
9. **Build generate screen** — Subject/Chapter/Quantity picker
10. **Build study screen** — Flip + self-assessment + NCERT deep-link
11. **Wire into home screen** — Replace current FlashcardScreen tab

### Phase 3: Content & Polish (P1-P2)
12. **MCQ seeding pipeline** — 5K questions with explanations
13. **Explanation pre-seeding** — Batch generate + store in DB
14. **Mock test history** — Store CBT results, add history tab
15. **Profile screen** — Stats, achievements, activity
16. **Test coverage** — Add widget tests for all screens

---

## 4. NOTES

- **Spaced Repetition Service exists** (`spaced_repetition_service.dart`) but is **question-centric**. It needs to be generalized to support both `questionId` and `flashcardId` as entity keys.
- **Flashcard model has `topicId`** which can be mapped to chapters, but there's no `chapterId` field for direct NCERT linkage.
- **Gemini multimodal** (`sendMultimodalMessage`) already supports image-based question solving but isn't wired to any camera/image picker in the chatbot screen.
- **Syncfusion license** is the only paid dependency. Consider `flutter_pdfview` or `pdfx` for open-source alternative if budget is zero.

---

*End of audit.*
