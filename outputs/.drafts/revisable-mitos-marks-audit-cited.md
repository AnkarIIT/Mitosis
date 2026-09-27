# NEET Mitos — Competitive Audit: Revisable, Mitos Learning, MARKS by MathonGo

**Slug:** `revisable-mitos-marks-audit`  
**Date:** 2026-01-18  
**Status:** Draft — cited claims  

---

## Executive Summary

This competitive audit benchmarks **Revisable**, **Mitos Learning**, and **MARKS by MathonGo** against the `neet_mitos` Flutter codebase. The central finding is a **content-scale gap**: our app ships with ~26–500 sample questions, while competitors field 33K–100K+ MCQs. Beyond volume, the fatal gap is the absence of a **retention engine** (spaced repetition, streaks, adaptive revision) and a **CBT-ready mock simulator** ahead of NEET UG's 2027 computer-based transition. The good news: our offline-first Flutter + Riverpod + Drift + Supabase stack is the right foundation. The roadmap is about layering content, retention mechanics, and a lightweight AI tutor on top of it — without paywalling core prep.

---

## 1. Competitor Profiles

### 1.1 Revisable (com.revio.revisable)

**Positioning:** "#1 self study platform for medical exams" targeting NEET UG, NEET PG, INICET, FMGE, AMC, USMLE, PLAB, and others. Claims 100K+ medical students and 10,000+ rankers in the last 12 months [Revisable website](https://www.revisableapp.com/).

**Content Scale:** 200K+ flashcards, 100K+ MCQs, 5K+ educator-created notes & videos [Revisable website](https://www.revisableapp.com/).

**Differentiating Features:**
- **Ruby AI — 24×7 AI Tutor:** Context-aware answers grounded in trusted medical content, plus AI-powered test analysis that tracks weak subjects, silly mistakes, retention gaps, and revision patterns [Revisable website](https://www.revisableapp.com/), [Google Play](https://play.google.com/store/apps/details?hl=en_IN&id=com.revio.revisable).
- **Smart Flashcards with Spaced Repetition:** Adaptive scheduling that personalizes to the user's memory curve [Google Play](https://play.google.com/store/apps/details?hl=en_IN&id=com.revio.revisable).
- **AI-Generated Content:** Instantly generates flashcards, summaries, rapid revision notes, and custom quizzes from weak areas [Revisable website](https://www.revisableapp.com/).
- **Personalized Test Prep:** AI automatically creates targeted test modules based on weak areas [Revisable website](https://www.revisableapp.com/).

**UX/Retention:** Bite-sized learning tracks weak topics, mistakes, confidence, and revision patterns. Smart revision schedules content at optimal intervals [Revisable website](https://www.revisableapp.com/).

**Monetization:** Free tier includes flashcards, QBanks, mock tests, notes, videos, and basic AI tools with rate-limiting and no cloud sync. Pro tiers (₹999 quarterly, ₹1,999 annual) unlock unlimited AI, personalized revision modules, and multi-device sync [Revisable website](https://www.revisableapp.com/).

**Technical Note:** Revisable paywalls cloud sync and personalized revision — a deliberate freemium lever.

---

### 1.2 Mitos Learning (com.mitoslearning)

**Positioning:** Mitos Learning Exam Prep launched Mitos Learning NEET Prep App in December 2025. The developer's claim is that "90/90 questions match in NEET 2026 Biology" [AppBrain](https://www.appbrain.com/app/mitos-learning-neet-prep-app/com.mitoslearning).

**Content Scale:** 40,000+ NCERT core concept questions, 35 Rank Booster test series, 30+ years of PYQs, HD comprehensive study notes [APKPure](https://apkpure.com/kr/mitos-learning-neet-prep-app/com.mitoslearning).

**Differentiating Features:**
- Unlimited custom chapter-wise and full-syllabus mock tests
- Score Improvement Program with personalized study plans
- Error Analysis Notes (error book)
- Personalized analytics for weak chapters/question types
- Weekly and monthly accuracy trend analysis
- High-accuracy NEET score predictor [APKPure](https://apkpure.com/kr/mitos-learning-neet-prep-app/com.mitoslearning).

**Monetization:** Free to download. No paid tiers identified.

**Critical Caveat — Name Confusion with MemoNeet:** Web searches for "Mitos Learning NEET" frequently surface **MemoNeet** (com.adithya.memoneet), a separate, much larger app. MemoNeet claims 35,000+ NCERT MCQs, 1.5M+ aspirants, 97% NEET 2026 match, Brahmastra Test Series, and the "NeuronZ" AI-based revision system [MemoNeet website](https://www.memoneet.com/), [Google Play](https://play.google.com/store/apps/details?id=com.adithya.memoneet&hl=en_IN). If the intended competitor was the major "line-by-line NCERT" player, **MemoNeet** is the correct benchmark, not Mitos Learning.

---

### 1.3 MARKS by MathonGo (com.scoremarks.marks)

**Positioning:** "The IIT JEE & NEET Prep App" by Scoremarks Technologies Pvt Ltd. 1,000,000+ downloads, 2,000,000+ questions solved daily, 40,000+ reviews [getmarks.app](https://getmarks.app/), [Google Play](https://play.google.com/store/apps/details?id=com.scoremarks.marks&hl=en_IN).

**Content Scale:** Chapter-wise PYQs for NEET, JEE Main, JEE Advanced, BITSAT, WBJEE, MHT CET, NDA, KVPY, plus NTA Abhyas questions. No explicit total MCQ count, but daily solve volume implies massive catalog [getmarks.app](https://getmarks.app/), [Google Play](https://play.google.com/store/apps/details?id=com.scoremarks.marks&hl=en_IN).

**Differentiating Features:**
- **Chapter-wise Previous Year Questions:** Downloadable, organized by chapter and exam [Google Play](https://play.google.com/store/apps/details?id=com.scoremarks.marks&hl=en_IN).
- **Unlimited Custom Tests:** Create as many custom tests as desired for free [MARKS YouTube](https://www.youtube.com/watch?v=GCa221rI9vE).
- **Quiz Mode:** Timed practice with instant feedback [getmarks.app](https://getmarks.app/).
- **Formula Cards:** Quick-reference formula sheets [getmarks.app](https://getmarks.app/).
- **Daily Practice Challenge:** Goal completion mechanics [Google Play](https://play.google.com/store/apps/details?id=com.scoremarks.marks&hl=en_IN).

**UX/Design:** Clean, minimal UI with light/dark mode. Low-friction entry; no login required for basic practice [getmarks.app](https://getmarks.app/).

**Monetization:** Free with no identified paywalls. Revenue likely flows from YouTube ads, physical/digital book sales, and coaching partnerships.

**Technical Note:** MARKS is a content-utility app, not an adaptive-learning app. No AI tutor, no spaced repetition, no advanced analytics.

---

## 2. Comparison Matrix

| Dimension | Revisable | Mitos Learning | MARKS by MathonGo | neet_mitos (ours) |
|-----------|-----------|----------------|-------------------|-------------------|
| **Question Bank** | 100K+ MCQs | 40K+ MCQs | Not specified (2M+ solves/day) | ~26–500 (seeded) |
| **Flashcards** | 200K+ with SR | Not identified | Formula cards only | Basic flashcard screen |
| **Spaced Repetition** | Yes (adaptive) | Not identified | No | No |
| **AI Tutor** | Ruby AI (24×7) | Not identified | No | Gemini chat (generic) |
| **AI Test Analysis** | Yes | Basic analytics | No | No |
| **Error Book** | Implied via analytics | Yes | No | Yes (basic) |
| **Custom Tests** | AI-generated | Unlimited | Yes (free) | PDF-based generator only |
| **Mock Tests** | With AI analysis | Rank Booster 35 tests | Quiz mode | Test series screen |
| **Study Plans** | Personalized (paywalled) | Personalized | Daily challenge | Static study plan |
| **Streaks/Gamification** | Not identified | Not identified | Daily challenge | No |
| **Offline Support** | Not confirmed | Not confirmed | Not confirmed | Yes (offline-first) |
| **CBT Simulator** | Not identified | Not identified | No | No |
| **PYQ Database** | Implied | 30+ years | Yes (chapter-wise) | No |
| **NCERT Fidelity** | Content-aligned | NCERT core | PYQ-focused | Bundled PDFs (unused) |

---

## 3. Gap Analysis

### Fatal Gaps (Block competitive parity)

1. **Question Bank <1% of Competition**
   - **Evidence:** Darwin fields 33K–38K+ MCQs [Darwin website](https://darwin.mcqdb.com/), MemoNeet 35K+ [MemoNeet website](https://www.memoneet.com/), Mitos Learning 40K+ [APKPure](https://apkpure.com/kr/mitos-learning-neet-prep-app/com.mitoslearning). Our `neet_sample_data.dart` contains ~26 seeded questions; `neet_sample_data_phase2.dart` adds more but total remains well under 500.
   - **Impact:** Users cannot practice enough to build exam stamina or coverage.

2. **No Spaced Repetition / Retention Engine**
   - **Evidence:** Revisable's "smart revision" and MemoNeet's "NeuronZ" are core value props [Revisable website](https://www.revisableapp.com/), [MemoNeet website](https://www.memoneet.com/). Industry consensus: spaced repetition improves long-term retention by up to 200% vs. cramming [NEETPGAI](https://neetpgai.com/neet-pg-study-material/how-to-use-spaced-repetition-for-neet-pg).
   - **Impact:** Students forget what they study; retention is the #1 predictor of NEET rank.

3. **No CBT-Ready Mock Simulator**
   - **Evidence:** NEET UG is shifting to CBT from 2027 due to the 2026 paper-leak controversy [Find My Guru](https://www.findmyguru.com/blog/best-neet-preparation-apps-in-india). Apps without CBT simulation will be at a structural disadvantage.
   - **Impact:** Students need exam-day simulation with timer, section navigation, negative marking, and forced breaks.

4. **AI Chatbot Not NCERT-Grounded**
   - **Evidence:** Revisable's Ruby AI is "grounded in trusted medical content" [Revisable website](https://www.revisableapp.com/). Our `gemini_chat_service.dart` is a generic chat wrapper with no RAG over NCERT or question bank.
   - **Impact:** AI tutor risks hallucinations; students cannot trust answers for high-stakes prep.

### Major Gaps (Significant engagement deficit)

5. **No Streaks, Leaderboards, or Gamification**
   - **Evidence:** MedicNEET uses daily streaks + leaderboards [MedicNEET](https://www.medicneet.com/neet-app); Yukthis uses XP, streaks, achievements, live rankings [Apple App Store](https://apps.apple.com/us/app/yukthis-neet/id6760161721); Edvaya uses streaks and leaderboards [Edvaya](https://www.edvaya.com/edvaya-target).
   - **Impact:** Education app Day 30 retention is 2–3% without engagement mechanics [Business of Apps](https://www.businessofapps.com/data/education-app-benchmarks/).

6. **Rank Predictor is Static Hardcoded Table**
   - **Evidence:** `lib/core/utils/rank_predictor.dart` contains hardcoded 2023–2024 data. Revisable and Mitos Learning both claim "high-accuracy NEET score prediction" with trend analysis [Revisable website](https://www.revisableapp.com/), [APKPure](https://apkpure.com/kr/mitos-learning-neet-prep-app/com.mitoslearning).
   - **Impact:** Students cannot trust predictions; feature feels broken after one exam cycle.

7. **Cloud Sync Incomplete**
   - **Evidence:** `cloud_sync_service.dart` has pull logic with an empty loop body. Revisable paywalls sync as a premium feature [Revisable website](https://www.revisableapp.com/).
   - **Impact:** Multi-device users lose progress; backup/reinstall is data-destructive.

8. **No Batch Segmentation**
   - **Evidence:** No Class 11 / Class 12 / Dropper onboarding. Competitors tailor content and study plans to batch [MemoNeet](https://apps.apple.com/in/app/memoneet-neet-exam-prep-2026/id1664948488).
   - **Impact:** Generic experience fails to account for different syllabus coverage and exam timelines.

### Minor Gaps (Polish)

9. **Duplicate Provider Files**
   - `lib/core/provider/providers.dart` and `lib/core/providers/providers.dart` conflict. Source inspection shows they differ significantly.

10. **Bundled NCERT PDFs Unused**
    - `assets/ncert_books/` contains mapped PDFs (`kebo101.pdf` = Biology Class 11 Chapter 1, etc.), but `pdf_picker_screen.dart` uses `file_picker` for user-selected files rather than bundled assets.

11. **ML Service is Dummy Code**
    - `ml_service.dart` uses character-code based "tokenization" with no real model or embeddings.

12. **No Formula Cards / Quick Revision Notes**
    - MARKS offers formula cards [getmarks.app](https://getmarks.app/); Revisable offers "rapid revision notes" [Revisable website](https://www.revisableapp.com/). We have neither.

---

## 4. Product DNA

### Current Implicit DNA
- Free, offline-first NCERT-anchored NEET prep
- Strong technical foundation (Flutter + Riverpod + Drift + Supabase)
- Content-light but feature-rich skeleton

### Proposed Explicit DNA
> **neet_mitos** is a free, offline-first NEET preparation platform that turns every NCERT line into actionable practice. We believe rank comes from recall, not just coverage — so we combine line-by-line question fidelity with an AI-native revision engine that respects how a student's memory actually fades. No paywalls on core prep. No internet required to practice. No wasted study time on content the exam will never ask.

### Differentiation Levers
1. **NCERT Fidelity:** Bundled PDFs + line-by-line mapping (uniquely positioned if questions are tagged to exact lines)
2. **Free-First:** No content paywalls; backend costs subsidized by efficient architecture
3. **Offline-First:** Built for tier-2/3 India where connectivity is unreliable
4. **AI-Native:** Gemini integration already exists; needs RAG grounding to become trustworthy

---

## 5. ML / AI Architecture

### Current State
- Gemini chat service exists (`gemini_chat_service.dart`) but is generic
- ML service is dummy code (`ml_service.dart`)
- No embeddings, no vector store, no retrieval

### Recommended Architecture (Free-App Viable)

```
┌─────────────────────────────────────────────┐
│  Flutter App (Riverpod + Drift)             │
│  - Offline-first local DB                   │
│  - On-device flashcard scheduling (FSRS)    │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│  Backend Proxy (Supabase Edge Functions)    │
│  - Auth + RLS                               │
│  - Question catalog sync                    │
│  - Usage analytics (anonymized)             │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│  AI Layer (Multi-provider router)           │
│  - Gemini Flash (fast, cheap) for chat      │
│  - Groq/DeepSeek for batch generation       │
│  - Embedding cache (Redis/PostgreSQL)       │
│  - RAG over NCERT + question bank           │
└─────────────────────────────────────────────┘
```

### Key Components

1. **Spaced Repetition Engine**
   - Implement FSRS v6 or SM-2 in Dart
   - Local-only scheduling; no server round-trips
   - Track: stability, difficulty, retrievability
   - **Why FSRS:** ML-optimized scheduling outperforms SM-2; open-source Kotlin/TypeScript implementations exist for porting [open-spaced-repetition/FSRS](https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler).

2. **RAG Pipeline**
   - Chunk bundled NCERT PDFs + high-quality explanations
   - Embed with Gemini `embedContent` or open-source model
   - Store in Supabase PostgreSQL + pgvector
   - Retrieve top-k chunks per query
   - **Reference:** neet-live-buddy uses Gemini embeddings + cosine similarity for NCERT RAG [GitHub](https://github.com/lkarthik76/neet-live-buddy).

3. **AI Tutor**
   - System prompt: "You are a NEET UG tutor. Cite NCERT chapter/section. Explain step-by-step. Never hallucinate facts."
   - Guardrails: forbid answers to active exam questions, flag outdated content
   - Cost control: 80/20 rule — 80% queries handled by cached/RAG, 20% by LLM
   - **Cost Benchmark:** ScholarNet AI reduced costs 60% via multi-provider routing + caching; target <$0.01 per chat turn [ScholarNet AI](https://ai-study-platform.hashnode.dev/building-scholarnet-ai-lessons-from-creating-an-ai-study-platform-1-1-1-1-1-1-1-1-1-1-1).

4. **Analytics**
   - Local computation for privacy and cost
   - Sync anonymized aggregates to backend for benchmarking

---

## 6. Prioritized Roadmap

### Phase 1: Fix Foundations (Weeks 1–4) — *Fatal*
| # | Initiative | Effort | Success Metric |
|---|-----------|--------|----------------|
| 1 | Question Bank Expansion to 5,000 verified MCQs | High | 5,000 NCERT-tagged questions in Drift DB |
| 2 | Fix Cloud Sync (pull + push) | Medium | Sync completes in <5s; zero data loss on reinstall |
| 3 | Consolidate Duplicate Providers | Low | Single source of truth; `provider/` directory removed |
| 4 | Batch Onboarding (Class 11/12/Dropper) | Medium | 100% new users select batch; content filtered accordingly |

### Phase 2: Retention Engine (Weeks 5–8) — *Major*
| # | Initiative | Effort | Success Metric |
|---|-----------|--------|----------------|
| 5 | Spaced Repetition (FSRS/SM-2) | High | Cards reviewed within 10% of optimal interval; 7-day retention >60% |
| 6 | Streaks & Daily Goals | Medium | Day-30 retention improves from 2% to 8% |
| 7 | Rank Predictor V2 (data-driven) | Medium | Prediction MAE <50 rank points vs. actual NEET scores |

### Phase 3: AI Layer (Weeks 9–12) — *Major*
| # | Initiative | Effort | Success Metric |
|---|-----------|--------|----------------|
| 8 | NCERT-Grounded Chat (RAG) | High | 90%+ answer accuracy on NCERT factual queries; <2s latency |
| 9 | AI Test Analysis | Medium | Weak topic detection precision >80% |
| 10 | Smart Revision Notes | Medium | Auto-generated summary card usage >30% of active users |

### Phase 4: Exam Simulation (Weeks 13–16) — *Fatal/Major*
| # | Initiative | Effort | Success Metric |
|---|-----------|--------|----------------|
| 11 | CBT Mock Test Simulator | High | Supports 180Q/200Q mode, timer, negative marking, break simulation |
| 12 | Custom Test Builder | Medium | Users create 500+ custom tests/week |
| 13 | Performance Analytics Dashboard | Medium | Weekly active users increase 20% post-launch |

### Phase 5: Content Scale (Weeks 17–24) — *Ongoing*
| # | Initiative | Effort | Success Metric |
|---|-----------|--------|----------------|
| 14 | PYQ Database (30 years, chapter-wise) | High | 10,000+ PYQs indexed by chapter/topic/year |
| 15 | HD Study Notes | Medium | 90 chapters covered with 1-page summaries |
| 16 | Video Integration | Low | Curated YouTube playlists mapped to 90 chapters |

---

## 7. Monetization (Free-First Constraint)

### Backend Cost Optimization
- **Supabase:** Free Tier for first 500 MAU; Pro (~$25/month) for scaling [Supabase Pricing](https://supabase.com/pricing).
- **AI:** Gemini Flash + Groq free tier + semantic caching. Target <$50/month for first 1,000 active users.
- **Offline-first:** 90%+ features work without backend, minimizing server costs.

### Non-Paywall Revenue Options
- Affiliate links to coaching platforms (ethical disclosure)
- Sponsored content from edtech partners (maintains free UX)
- Donation/sponsorship model (OpenMedQ proves viability on Cloudflare Free Tier)
- White-label for schools/coaching classes

### What NOT to Paywall
- Question bank access
- Basic test series
- Flashcard scheduling
- Error book
- AI chat (rate-limited but available)

---

## 8. Key Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Question copyright / NCERT licensing | High | Fatal | Partner with ePathshala (official NCERT digital channel); user-generated content with moderation |
| AI API costs exceed budget | Medium | High | Multi-provider routing, caching, rate-limiting, on-device fallback |
| Competitor question-bank advantage is insurmountable | Medium | High | Differentiate on NCERT fidelity + offline-first + free access; grow via community contributions |
| CBT simulator not ready by 2027 | Low | High | Prioritize in Phase 4; start with MVP in Phase 1 |

---

## 9. Conclusion

`neet_mitos` has a technically sound foundation but a **content and engagement gap** measured in orders of magnitude. The path to parity is not a single feature — it is a sequence:

1. **Fill the question bank** (or die)
2. **Add a retention engine** (streaks + spaced repetition)
3. **Ground the AI tutor** in NCERT content
4. **Simulate the exam** in CBT format
5. **Scale content** (PYQs, notes, videos)

The stack choice (Flutter, Riverpod, Drift, Supabase, Gemini) is defensible. The constraint is execution velocity and content sourcing. If the team can reach 5,000 verified MCQs in Phase 1 and ship FSRS in Phase 2, the app moves from "nice demo" to "usable daily driver" — the threshold for word-of-mouth growth in NEET prep.

---

## Sources
- [Revisable website](https://www.revisableapp.com/)
- [Revisable Google Play](https://play.google.com/store/apps/details?hl=en_IN&id=com.revio.revisable)
- [Revisable Apple App Store](https://apps.apple.com/in/app/revisable-neet-usmle-amc/id6451157089)
- [Mitos Learning AppBrain](https://www.appbrain.com/app/mitos-learning-neet-prep-app/com.mitoslearning)
- [Mitos Learning APKPure](https://apkpure.com/kr/mitos-learning-neet-prep-app/com.mitoslearning)
- [MARKS getmarks.app](https://getmarks.app/)
- [MARKS Google Play](https://play.google.com/store/apps/details?id=com.scoremarks.marks&hl=en_IN)
- [MARKS YouTube](https://www.youtube.com/watch?v=GCa221rI9vE)
- [MemoNeet website](https://www.memoneet.com/)
- [MemoNeet Google Play](https://play.google.com/store/apps/details?id=com.adithya.memoneet&hl=en_IN)
- [Darwin NEET Prep](https://darwin.mcqdb.com/)
- [Darwin Google Play](https://play.google.com/store/apps/details?id=com.neet_darwin_mcqdb&hl=en)
- [MedicNEET](https://www.medicneet.com/neet-app)
- [Yukthis App Store](https://apps.apple.com/us/app/yukthis-neet/id6760161721)
- [Edvaya](https://www.edvaya.com/edvaya-target)
- [Find My Guru — NEET CBT 2027](https://www.findmyguru.com/blog/best-neet-preparation-apps-in-india)
- [Business of Apps — Education Benchmarks 2026](https://www.businessofapps.com/data/education-app-benchmarks/)
- [NEETPGAI — Spaced Repetition for NEET PG](https://neetpgai.com/neet-pg-study-material/how-to-use-spaced-repetition-for-neet-pg)
- [Open Spaced Repetition — FSRS](https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler)
- [ScholarNet AI — Cost Optimization](https://ai-study-platform.hashnode.dev/building-scholarnet-ai-lessons-from-creating-an-ai-study-platform-1-1-1-1-1-1-1-1-1-1-1)
- [Supabase Pricing](https://supabase.com/pricing)
- [neet-live-buddy GitHub](https://github.com/lkarthik76/neet-live-buddy)
- [StudyOS GitHub](https://github.com/rohitkumarnaidu/StudyOS)
