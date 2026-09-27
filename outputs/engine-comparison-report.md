# NEET Mitos Engine Comparison: Exam, Quiz & DPP vs Industry Standards

**Date:** 2025-01-15  
**Scope:** `lib/features/exam_engine/`, `lib/features/quiz/`, `lib/features/dpp/`, `lib/core/services/`  
**Methodology:** Code audit + industry research (Quizmill, iatroX, SATHEE, AdaptIQ, SchoolDeck, CAT spec)  
**Verdict:** App has **local question generation via Gemini AI**, but it's isolated to PDF import — not integrated into core engines.

---

## Executive Summary

| Engine | Current Level | Industry Gap | Question Generation |
|--------|--------------|--------------|---------------------|
| **Exam Engine** | L3 Persistent (75%) | Missing FLAG_SECURE, blueprint, instructions, mastery curves | ❌ No (samples from bank only) |
| **Quiz Engine** | L2 Interactive (55%) | Missing session persistence, adaptive difficulty, anti-repetition | ❌ No (samples from bank only) |
| **DPP Engine** | L2 Interactive (50%) | Missing chapter frequency, concept dedup, cooldown windows | ❌ No (samples from bank only) |
| **AI Generation** | Exists but isolated | Not integrated into any engine | ✅ Yes (Gemini via PDF picker) |

**Overall Assessment:** The three engines are **functional but siloed**. They share a common question bank but lack unified intelligence. The app has the **capability to generate questions via AI**, but this feature is buried in the Test Series PDF picker and not accessible to Quiz/Exam/DPP flows.

---

## 1. Side-by-Side Feature Matrix

### 1.1 Core Capabilities

| Feature | Exam Engine | Quiz Engine | DPP Engine | Industry Standard |
|---------|-------------|-------------|------------|-------------------|
| **Question Source** | Local Drift DB | Local Drift DB | Local Drift DB | Local + AI-generated |
| **Question Generation** | ❌ | ❌ | ❌ | ✅ (Gemini/LLM) |
| **State Management** | ✅ State machine | ✅ Riverpod | ✅ Service-based | ✅ Varies |
| **Timer/Auto-submit** | ✅ | ⚠️ Display only | ⚠️ Basic | ✅ Both |
| **Crash Recovery** | ✅ Checkpoints | ❌ | ❌ | ✅ Session save |
| **Scoring Accuracy** | ✅ NEET +4/-1 | ✅ NEET +4/-1 | ✅ NEET +4/-1 | ✅ Pattern-matched |
| **Session Persistence** | ✅ | ❌ | ❌ | ✅ Auto-save |

### 1.2 Question Selection Intelligence

| Feature | Exam Engine | Quiz Engine | DPP Engine | Industry Standard |
|---------|-------------|-------------|------------|-------------------|
| **Random Shuffle** | ✅ Seed-based | ✅ Seed-based | ✅ Seed-based | ✅ Baseline |
| **Difficulty Balance** | ⚠️ 40/40/20 | ❌ None | ✅ 30/50/20 | ✅ 30/50/20 NTA |
| **Anti-Repetition** | ❌ | ❌ | ⚠️ Last 20 only | ✅ Full history |
| **Cooldown Windows** | ❌ | ❌ | ❌ | ✅ 1d/3d/7d |
| **Weak Topic Bias** | ❌ | ❌ | ✅ MasteryService | ✅ Adaptive routing |
| **Chapter Frequency** | ❌ | ❌ | ⚠️ Hardcoded map | ✅ PYQ-weighted |
| **Concept Dedup** | ❌ | ❌ | ⚠️ Flag only | ✅ Tag-based |
| **Adaptive Difficulty** | ❌ | ❌ | ⚠️ Flag only | ✅ IRT/RL-based |

### 1.3 User Experience

| Feature | Exam Engine | Quiz Engine | DPP Engine | Industry Standard |
|---------|-------------|-------------|------------|-------------------|
| **Question Palette** | ✅ 5-state NTA style | ✅ Grid overlay | ❌ | ✅ Modal palette |
| **Flag/Review** | ✅ | ✅ | ❌ | ✅ |
| **Hints** | ❌ | ✅ AI + offline | ❌ | ✅ Context-aware |
| **Explanations** | ✅ | ✅ | ⚠️ Post-attempt | ✅ Immediate |
| **Animations** | ⚠️ Basic | ✅ Confetti + slide | ❌ | ✅ Polished |
| **Sound/Haptics** | ❌ | ❌ | ❌ | ✅ Feedback cues |
| **Accessibility** | ❌ | ❌ | ❌ | ✅ WCAG 2.1 |

### 1.4 Analytics & Personalization

| Feature | Exam Engine | Quiz Engine | DPP Engine | Industry Standard |
|---------|-------------|-------------|------------|-------------------|
| **Score Tracking** | ✅ | ✅ | ✅ | ✅ |
| **Subject Breakdown** | ✅ | ✅ | ✅ | ✅ |
| **Weak Topic ID** | ✅ | ❌ | ✅ | ✅ |
| **Mastery Curves** | ❌ | ❌ | ❌ | ✅ Progress over time |
| **Streak Tracking** | ❌ | ❌ | ❌ | ✅ Gamification |
| **Percentile/AIR** | ✅ | ❌ | ❌ | ✅ Multi-paper norm |
| **PDF Export** | ❌ | ❌ | ❌ | ✅ Printable reports |
| **History Trends** | ⚠️ Basic | ❌ | ❌ ✅ CSV | ✅ Dashboards |

---

## 2. Deep Dive: Exam Engine

### 2.1 What Works (75% Complete)

| Component | Status | Evidence |
|-----------|--------|----------|
| **CBT UI** | ✅ Solid | `CbtTestScreen` with section lock, breaks, palette |
| **Timer** | ✅ Strong | Wall-clock deadline, idempotent auto-submit |
| **Crash Recovery** | ✅ Good | `ExamCheckpointService` autosaves every 15s |
| **Grading** | ✅ Complete | N-of-M optional sections, +4/-1, per-section |
| **Calculator** | ✅ Done | NTA-style two-line display |
| **Proctoring** | ⚠️ Partial | Fullscreen + app-leave, missing FLAG_SECURE |
| **Results** | ✅ Basic | Score, percentile, AIR, weak topics, CSV export |

### 2.2 What Doesn't Work

| Gap | Impact | Fix Effort |
|-----|--------|------------|
| **FLAG_SECURE** | Medium | 1 line in AndroidManifest |
| **Instructions Page** | Medium | New screen, ~200 LOC |
| **Blueprint Enforcement** | Medium-High | Chapter quotas in `QuestionPaperGenerator` |
| **Checkpoint Versioning** | Low | Add `version` field + migration |
| **Topic Mastery Curves** | Medium | Track accuracy over time per topic |
| **Streak Tracking** | Low-Medium | Consecutive full-length mocks |
| **PDF Export** | Low | `pdf` package for report generation |
| **Font Scaling** | Medium | `MediaQuery.textScaleFactor` support |
| **Color-blind Mode** | Low | Alternate palette in theme |
| **Adaptive Difficulty** | Low (Phase 2) | IRT-lite or rule-based routing |

### 2.3 Verdict

**Production-ready for offline NEET practice.** The architecture is sound — immutable models, clean separation of concerns, idempotent guards. The 4 Phase 1 fixes (FLAG_SECURE, instructions, blueprint, versioning) would bring it to ~90% spec compliance.

---

## 3. Deep Dive: Quiz Engine

### 3.1 What Works (55% Complete)

| Component | Status | Evidence |
|-----------|--------|----------|
| **State Machine** | ✅ | `QuizState` with `copyWith`, undo support |
| **Riverpod Integration** | ✅ | `quizProvider` notifier |
| **Seed Randomization** | ✅ | `initializeQuiz(Random(seed))` |
| **Navigation** | ✅ | Next/Prev/GoTo, palette, flagging |
| **NEET Scoring** | ✅ | +4/-1 indicator, score calculation |
| **AI Hints** | ✅ | Gemini proxy + offline fallback |
| **Short Answer** | ✅ | ML-based evaluation, confetti |
| **Animations** | ✅ | `flutter_animate`, slideX, scale |

### 3.2 What Doesn't Work

| Gap | Impact | Fix Effort |
|-----|--------|------------|
| **Session Persistence** | **CRITICAL** | High — Drift `QuizSession` table, auto-save |
| **Auto-submit** | High | Low — add `timeLimitSeconds` + timer check |
| **Per-question Timing** | Medium | Low — record + persist `timeSpentPerQuestion` |
| **Anti-repetition** | High | Medium — exclude globally seen questions |
| **Adaptive Difficulty** | High | Medium — mastery-weighted selection |
| **Mastery Tracking** | Medium | Medium — compute + store per topic |
| **Multiple Modes** | Medium | Medium — Practice/Exam/Revision/Speed |
| **Streak Tracking** | Low | Low — consecutive correct counter |
| **Sound/Haptics** | Low | Low — `audioservices` + `HapticFeedback` |
| **Keyboard Nav** | Low | Low — `RawKeyboardListener` for 1-4, arrows |

### 3.3 Verdict

**Solid L2 Interactive platform.** The UX is polished (animations, palette, hints), but it's fragile — progress vanishes on app restart. Session persistence is the #1 fix needed. After that, adaptive difficulty and anti-repetition would make it competitive with SATHEE/Quizmill.

---

## 4. Deep Dive: DPP Engine

### 4.1 What Works (50% Complete)

| Component | Status | Evidence |
|-----------|--------|----------|
| **Generation** | ✅ | `DppEngine.generate()` samples from bank |
| **Weak Topic Bias** | ✅ | `MasteryService.weakTopicIds()` |
| **Difficulty Balance** | ✅ | 30/50/20 default |
| **Subject Weights** | ✅ | `DppConfig.subjectWeights` |
| **Persistence** | ✅ | `DppSet` + `DppQuestions` in Drift |
| **Today's DPP** | ✅ | `getTodayDppSet()` prevents duplicates per day |

### 4.2 What Doesn't Work

| Gap | Impact | Fix Effort |
|-----|--------|------------|
| **Full-history Anti-rep** | High | Low — replace `getRecentSeenQuestionIds` |
| **Cooldown Windows** | High | Low — 1d/3d/7d by difficulty |
| **Chapter Frequency** | High | Medium — PYQ-weighted selection |
| **Concept Dedup** | High | High — NLP or tag-based clustering |
| **Adaptive Difficulty** | Medium | Medium — adjust based on recent accuracy |
| **Streak Tracking** | Low | Low — daily completion streaks |
| **DPP Analytics** | Low | Medium — subject-wise trends |
| **Multi-day Series** | Low | Medium — 7-day DPP plan generation |

### 4.3 Verdict

**Usable but basic.** The DPP engine generates valid practice papers with weak-topic bias, but it's not intelligent. Questions repeat too often, high-yield chapters aren't prioritized, and there's no learning from performance. Phase 1 fixes (anti-repetition, cooldown, frequency) would make it competitive with MTG/NEETprep DPP systems.

---

## 5. Question Generation Capability

### 5.1 Current State: EXISTS BUT ISOLATED

**YES**, the app **can generate questions** using Gemini AI. The capability exists in:

```dart
// lib/core/services/gemini_chat_service.dart
Future<List<Map<String, dynamic>>> generateQuestionsFromText(
  String textChunk, 
  String subject
)
```

**How it works:**
1. Takes NCERT text chunk (from PDF)
2. Sends to Gemini 1.5 Flash with system prompt: "You are an expert NEET question setter"
3. Requests JSON array of 5 questions with: `questionText`, `correctAnswer`, `options`, `type`, `difficulty`, `explanation`, `ncertReference`
4. Parses response, validates structure, inserts into Drift DB

**Where it's used:**
- `lib/features/test_series/pdf_picker_screen.dart` — "AI PDF Engine"
- User uploads NCERT PDF → app extracts text by chapters → user clicks "GENERATE" → AI creates up to 15 questions per chapter
- Questions are saved to local DB with `gen_` prefix IDs

### 5.2 Why It's Not Integrated

| Engine | Integration Status | Reason |
|--------|-------------------|--------|
| **Quiz Engine** | ❌ | `quizProvider` only samples from existing `allQuestionsProvider` |
| **Exam Engine** | ❌ | `ExamEngineService.allocateQuestions()` uses static pool |
| **DPP Engine** | ❌ | `DppEngine._buildPool()` queries `QuestionRepository` only |

**The AI generation is treated as a "content import" feature, not a live engine capability.** It's a one-time PDF → questions pipeline, not an on-demand generator.

### 5.3 To Integrate, You Would Need:

1. **Quiz Engine**: Add `aiGenerateQuestions(topicId, count)` to `quizProvider` → call `GeminiChatService.generateQuestionsFromText()` → append to question pool before `initializeQuiz()`

2. **Exam Engine**: Add `AIEnhancedQuestionPaperGenerator` → after `QuestionPaperGenerator` runs, if pool < target, call Gemini to fill gaps with NCERT-grounded questions

3. **DPP Engine**: Add `aiBackfill` flag to `DppConfig` → if `_buildPool()` returns < `totalQuestions`, generate remaining via AI with weak-topic context

---

## 6. Industry Comparison: Where NEET Mitos Stands

### 6.1 Competitive Landscape

| Platform | Question Source | Adaptive | Offline | AI Generation | NEET-Specific |
|----------|----------------|----------|---------|---------------|---------------|
| **NEET Mitos** | Local DB + PDF import | ⚠️ Basic | ✅ | ✅ Isolated | ✅ |
| **Quizmill** | Import any bank | ✅ Unseen bias | ✅ | ❌ | ❌ |
| **iatroX** | Curated bank | ✅ Real-time routing | ❌ | ❌ | ❌ |
| **SATHEE** | PYQ + generated | ✅ SM-2 spaced rep | ✅ | ❌ | ✅ |
| **AdaptIQ** | RAG + generated | ✅ Granular mastery | ❌ | ✅ LLM explanations | ✅ Medical |
| **SchoolDeck** | AI-generated | ✅ Recursive loop | ✅ | ✅ Auto-generate | ❌ Generic |
| **NEETprep** | Curated bank | ✅ Weak-topic focus | ✅ | ❌ | ✅ |
| **MTG DPP** | Printed → digital | ❌ Fixed papers | ❌ | ❌ | ✅ |

### 6.2 Key Differentiators Missing

| Feature | Status | Competitive Impact |
|---------|--------|-------------------|
| **Unified Engine Architecture** | ❌ Siloed quiz/exam/DPP | High — users see fragmented experience |
| **Adaptive Question Routing** | ❌ Fixed shuffle | High — all students get same test |
| **Spaced Repetition in Quiz** | ❌ No SM-2 | Medium — retention science missing |
| **AI-Generated Practice Papers** | ❌ Not on-demand | Medium — requires manual PDF upload |
| **Real-time Analytics Dashboard** | ⚠️ Basic | Medium — no trend visualization |
| **Multi-device Sync** | ❌ Local-only | Low — family/shared device use case |

---

## 7. Recommended Architecture: Unified Intelligent Engine

### 7.1 Proposed Architecture

```
                    ┌──────────────────────┐
                    │   UnifiedQuizEngine   │
                    │  (replaces 3 silos)   │
                    └──────────┬───────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
    ┌──────▼──────┐   ┌──────▼──────┐   ┌──────▼──────┐
    │  Quiz Mode  │   │ Exam Mode   │   │  DPP Mode   │
    │ (practice,  │   │ (CBT, mock, │   │ (daily,     │
    │  adaptive)  │   │  full-length)│   │  chapter)   │
    └──────┬──────┘   └──────┬──────┘   └──────┬──────┘
           │                   │                   │
           └───────────────────┼───────────────────┘
                               │
                    ┌──────────▼───────────┐
                    │  QuestionPoolService │
                    │  ┌───────────────┐  │
                    │  │ Local DB (Drift) │  │
                    │  └───────────────┘  │
                    │  ┌───────────────┐  │
                    │  │ AI Generator  │  │
                    │  │ (Gemini/LLM)  │  │
                    │  └───────────────┘  │
                    └──────────┬───────────┘
                               │
                    ┌──────────▼───────────┐
                    │  Intelligence Layer  │
                    │  ┌────────────────┐  │
                    │  │ AntiRepetition │  │
                    │  │ MasteryTracker │  │
                    │  │ AdaptiveRouter │  │
                    │  │ SpacedRepetition│ │
                    │  └────────────────┘  │
                    └──────────────────────┘
```

### 7.2 Implementation Phases

#### Phase 1: Stabilize (Weeks 1-2)
- Add session persistence to Quiz + DPP
- Add auto-submit + per-question timing to Quiz
- Integrate FLAG_SECURE + instructions page to Exam

#### Phase 2: Unify (Weeks 3-4)
- Create `UnifiedQuizEngine` abstraction
- Share `QuestionPoolService` across all modes
- Add AI question generation as fallback when pool insufficient

#### Phase 3: Intelligize (Weeks 5-6)
- Add `IntelligenceLayer`: anti-repetition, cooldown, mastery tracking
- Implement adaptive difficulty routing
- Add spaced repetition integration (SM-2)

#### Phase 4: Polish (Weeks 7-8)
- Multiple quiz modes (Practice/Exam/Revision/Speed)
- Streaks, achievements, sound/haptics
- Accessibility: font scaling, color-blind mode, keyboard nav

---

## 8. Bottom Line: What's Working, What's Not

### ✅ What Works Well

| Area | Strength |
|------|----------|
| **Exam Engine** | Solid CBT simulation, crash recovery, NEET-accurate scoring |
| **Quiz UX** | Polished animations, palette, hints, NEET scoring |
| **DPP Generation** | Weak-topic bias, difficulty balance, subject weights |
| **AI Capability** | Gemini integration exists, can generate NCERT-grounded questions |
| **Local-First** | Fully offline, Drift persistence, no server dependency |
| **Code Quality** | Clean separation, immutable models, Riverpod state management |

### ❌ What Doesn't Work

| Area | Weakness |
|------|----------|
| **Session Persistence** | Quiz + DPP lose progress on app restart |
| **Adaptive Intelligence** | All engines use static random shuffle |
| **Anti-Repetition** | Questions repeat across sessions |
| **AI Integration** | Generation exists but not connected to engines |
| **Unified Experience** | Three separate engines, no shared intelligence |
| **Accessibility** | No font scaling, color-blind mode, keyboard nav |
| **Analytics Depth** | Basic scores, no trends, mastery curves, or predictions |

### 🤔 Can It Generate Questions?

**Short answer:** Yes, but not automatically.

**Long answer:**
- The app has `GeminiChatService.generateQuestionsFromText()` which can create NCERT-grounded MCQ/short-answer questions
- It's currently only used in the PDF picker screen (`pdf_picker_screen.dart`)
- To make it work in Quiz/Exam/DPP engines, you need to:
  1. Expose `generateQuestionsFromText` through a `QuestionGenerationService`
  2. Add AI fallback in `QuestionPoolService` when local pool is insufficient
  3. Add `aiBackfill` flag to `DppConfig` and `QuizState`
  4. Cache generated questions in Drift to avoid re-generating

**Estimated effort to integrate:** 2-3 days for basic integration, 1 week for robust caching + quality control.

---

## 9. Priority Roadmap

### Immediate (This Week)
1. **Quiz session persistence** — highest UX impact
2. **FLAG_SECURE** — 1 line, critical for exam integrity
3. **DPP anti-repetition** — replace recent-only with full history

### Short-term (Next 2 Weeks)
4. **Unified question pool service** — shared by all engines
5. **AI question generation integration** — connect Gemini to engines
6. **Quiz auto-submit** — enforce time limits

### Medium-term (Next Month)
7. **Adaptive difficulty** — mastery-weighted question selection
8. **Multiple quiz modes** — Practice/Exam/Revision/Speed
9. **Analytics dashboard** — trends, mastery curves, predictions

### Long-term (Next Quarter)
10. **Online mode** — server-authoritative timer, cloud sync
11. **Accessibility suite** — font scaling, color-blind, keyboard
12. **Social features** — leaderboards, shared papers, multiplayer

---

## 10. Final Scorecard

| Engine | Completeness | Production-Ready? | Intelligence | AI Generation |
|--------|-------------|-------------------|-------------|---------------|
| Exam | 75% (18/24) | ✅ For offline practice | ⭐⭐ | ❌ |
| Quiz | 55% (11/20) | ⚠️ Needs persistence | ⭐ | ❌ |
| DPP | 50% (9/18) | ⚠️ Needs anti-rep | ⭐ | ❌ |
| **Overall** | **~60%** | **⚠️ Partial** | **⭐½** | **✅ Available** |

**Recommendation:** Focus on **session persistence + AI integration** first. These two changes alone would:
- Save user progress (fixes #1 complaint)
- Enable infinite question supply (fixes content exhaustion)
- Differentiate from competitors (unique AI-powered practice)

---

*Generated via code audit of `lib/features/exam_engine/`, `lib/features/quiz/`, `lib/features/dpp/`, `lib/core/services/` and industry research on CAT engines, adaptive learning platforms, and NEET prep apps.*
