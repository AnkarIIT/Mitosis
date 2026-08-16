# Research Notes: Revisable / Mitos Learning / MARKS Competitive Audit

**Date:** 2026-01-18  
**Scope:** Competitive audit for NEET UG prep app `neet_mitos`  
**Status:** Evidence gathered; ready for synthesis

---

## 1. Revisable (com.revio.revisable)

### Core Identity
- "#1 self study platform for medical exams" — claims 100K+ medical students, 10,000+ rankers in last 12 months
- Multi-exam: NEET UG, NEET PG, INICET, FMGE, AMC, USMLE, PLAB, UKMLA, MCAT, MRCP, CUET
- Positioning: "Expert-curated study material that evolves with how you learn, revise, forget and improve"

### Content Scale
- 200K+ flashcards
- 100K+ MCQs
- 5K+ educator-created notes & videos
- "Verified learning library"

### Key Features
1. **Ruby AI — 24×7 AI Tutor**
   - Context-aware answers grounded in trusted medical content
   - AI-powered test analysis: tracks weak subjects, silly mistakes, retention gaps, revision patterns
   - Generate content with AI: flashcards, summaries, rapid revision notes, custom quizzes from weak areas

2. **Smart Flashcards with Spaced Repetition**
   - "Adaptive learning using spaced repetition that personalizes to your memory curve"
   - No explicit algorithm name mentioned on site, but industry standard is SM-2 or FSRS

3. **AI-Powered MCQs**
   - "Don't just test — learn from detailed, conceptual explanations and instant analytics"
   - AI automatically creates targeted test modules based on weak areas

4. **Personalized Revision**
   - "Smart revision: Algorithm schedules content at the right intervals to improve retention"

### UX/Retention Mechanics
- Bite-sized learning: track weak topics, mistakes, confidence, revision patterns
- Personalized test prep based on weak areas
- Testimonials emphasize speed of revision and structured approach

### Monetization
- **Free:** Flashcards, QBanks, Mock Tests, Notes, Videos, basic AI tools (limited content access, limited AI, AI rate-limiting, no cloud sync, no personalized revision)
- **Pro Quarterly:** ₹999 / 3 months (full content, advance AI, unlimited AI, sync 2 devices, personalized revision modules)
- **Pro Annual:** ₹1,999 / 12 months (full content, advance AI, unlimited AI, sync 3 devices, personalized revision modules)
- Apple App Store: Monthly ₹199, Yearly ₹999 (India); Yearly USD 14.99–19.99 (other markets)

### Technical Observations
- App appears to be Flutter-based (Framer marketing site, cross-platform presence)
- AI tutor is a core differentiator, not a wrapper
- Cloud sync is paywalled — interesting monetization lever

---

## 2. Mitos Learning (com.mitoslearning)

### Core Identity
- Developer: Mitos Learning Exam Prep (mitoslearing@gmail.com)
- App size: 32.46 MB
- Latest version: 2.7 (last updated July 4, 2026)
- Available on Google Play since December 2025
- **Claim:** "90/90 questions match in NEET 2026 Biology"

### Content Scale
- 40,000+ NCERT core concept questions
- 35 Rank Booster test series
- 30+ years of previous year questions (PYQs)
- HD comprehensive study notes for all units

### Key Features
1. **Personalized Question Practice & Test Series**
   - Unlimited custom chapter-wise and full syllabus mock tests
   - NEET Rank Booster Test Series (35 tests)

2. **Score Improvement Program**
   - Personalized study plans tailored to individual needs

3. **Error Analysis Notes**
   - Same mistake prevention system (error book)

4. **Personalized Analytics**
   - Identify weak chapters and question types
   - Weekly and monthly accuracy trend analysis
   - High-accuracy NEET score predictor

5. **Study Notes**
   - HD comprehensive notes for all chapters

### Monetization
- Free to download (no pricing data found)
- Very small market footprint compared to competitors

### Critical Finding: Name Confusion with MemoNeet
- Web searches for "Mitos Learning NEET" frequently return MemoNeet (com.adithya.memoneet) results
- MemoNeet is a **completely different app** with:
  - 35,000+ NCERT MCQs
  - Brahmastra Test Series 2026 (20 part tests + 10 full-length)
  - AI-based NeuronZ revision system
  - 1.5M+ aspirants, 5000+ MBBS students secured
  - "97% of questions in NEET 2026 matched"
  - 7-level revision algorithm
  - Mistake Book with customized DPP
- **Conclusion:** Mitos Learning appears to be a much smaller, newer entrant (Dec 2025) with limited visibility. If the user intended to benchmark against the major "Line by Line NCERT" player, they likely meant **MemoNeet**, not Mitos Learning.

---

## 3. MARKS by MathonGo (com.scoremarks.marks)

### Core Identity
- Developer: Scoremarks Technologies Pvt Ltd
- Tagline: "The IIT JEE & NEET Prep App"
- 1,000,000+ downloads, 2,000,000+ questions solved daily, 40,000+ reviews
- Web: getmarks.app, mathongo.com

### Content Scale
- Chapter-wise previous year questions (PYQs) for NEET, JEE Main, JEE Advanced, BITSAT, WBJEE, MHT CET, NDA, KVPY
- NTA Abhyas questions
- Top 500 Question Bank for JEE Main (hand-picked by MathonGo teachers)
- No explicit MCQ count stated, but "2M+ questions solved daily" implies massive volume

### Key Features
1. **Previous Year Questions (PYQ) Organization**
   - Chapter-wise PYQ download and practice
   - Multiple exam formats supported

2. **Custom Test Creation**
   - "Create Custom Tests" — unlimited custom tests for free (per YouTube video title)
   - "Practice in Quiz Mode"

3. **Formula Cards**
   - Quick reference for formulas

4. **Daily Practice Challenge**
   - Goal completion mechanics

5. **MathonGo Ecosystem Integration**
   - YouTube channel (free video lectures)
   - PYQ books (physical/digital)
   - Cross-platform presence (web.getmarks.app)

### UX/Design
- Clean, minimal UI with light/dark mode
- Device-frame marketing imagery suggests mobile-first design
- Focus on practice volume and accessibility

### Monetization
- Free app with no paywalls mentioned
- Revenue likely from YouTube ads, book sales, and potential enterprise/coaching partnerships

### Technical Observations
- No AI tutor or spaced repetition mentioned
- Strength is content curation and accessibility, not adaptive learning
- Low-friction entry: no login required for basic practice

---

## 4. Industry Benchmarks & Context

### Question Bank Sizes (NEET UG)
| App | Claimed MCQ Count | Source |
|-----|-------------------|--------|
| Darwin | 33,000–38,000+ | Play Store, darwin.mcqdb.com |
| MemoNeet | 35,000+ | memoneet.com |
| Mitos Learning | 40,000+ | AppBrain, APKPure |
| MedicNEET | 43,000+ | medicneet.com |
| PYQBank | Not specified | pyqbank.com |
| MARKS | Not specified (2M+ solves/day) | getmarks.app |
| **neet_mitos (ours)** | **~26–500** (seeded sample) | Code inspection |

### Retention Benchmarks
- Education apps: Day 1 retention ~14–15%, Day 30 retention ~2–3%
- High-retention apps use: streaks, daily challenges, spaced repetition, leaderboards, XP/gamification
- Revisable: personalized revision modules (paywalled)
- MemoNeet: NeuronZ AI-based auto-scheduled revision
- MedicNEET: daily streak + adaptive "Predicted Batch"
- Yukthis: XP rewards, streaks, live leaderboards
- Triveni: daily practice tournaments

### Spaced Repetition Algorithms
- **SM-2:** Legacy Anki algorithm; proven for medical exams
- **FSRS (Free Spaced Repetition Scheduler):** ML-optimized, v6 is latest; superior to SM-2 for scheduling efficiency
- Open-source implementations available in Kotlin, Ruby, TypeScript
- For NEET: SM-2 sufficient; FSRS better if data available for parameter optimization

### AI Tutoring Architectures
1. **RAG (Retrieval-Augmented Generation):**
   - Embed NCERT content + app questions
   - Retrieve context for each query
   - Examples: neet-live-buddy (Gemini + RAG), StudyOS (PostgreSQL + pgvector)
   - Cost: embedding storage + retrieval latency

2. **Fine-tuned LLM:**
   - Vidya-4B / Vidya-9B (Qwen-based, NCERT/NEET fine-tuned)
   - ANEETA (Gemma-3n via Ollama, offline)
   - Better domain accuracy but higher infra cost
   - Can run on-device for privacy/offline use

3. **Hybrid (Recommended for free apps):**
   - Fine-tuned small model (4B) for common NCERT questions
   - RAG fallback for edge cases
   - Multi-provider routing (Gemini Flash for speed, Groq/DeepSeek for cost)
   - Deterministic components with zero LLM cost

### Backend Cost Structures
- Supabase Free Tier: $0/month (limited)
- Supabase Pro: ~$25/month + compute
- AI API costs:
  - Gemini Flash: ~$0.075/1M input tokens (very cheap)
  - Groq: 3x faster, 10x cheaper than GPT-4 for quiz generation
  - Claude Haiku: ~$0.003/background task
  - Multi-provider routing can reduce costs 60% (ScholarNet AI case study: $300/day → optimized)
- Offline-first architecture reduces server costs significantly

### CBT Transition Impact
- NEET UG shifting to Computer-Based Testing (CBT) from 2027
- Apps built around PDF notes/paper-style mocks will be at disadvantage
- Need CBT simulator with forced breaks, on-screen calculator, flag-for-review UX

---

## 5. neet_mitos Current State (from prior audit)

### Strengths
- Offline-first with Supabase sync
- Bundled NCERT PDFs (unusual asset naming scheme decoded)
- Topic browser, quiz engine, test series, AI chatbot, flashcards, study planner, error book, mark booster, progress dashboard, bookmarks
- Biometric lock, guest mode
- PDF question paper generator
- Riverpod + Drift + Supabase stack is modern and scalable

### Critical Gaps
1. **Question Bank:** ~26 seeded sample questions; well under 500 total
2. **PDF Assets:** `file_picker` for user-selected files; bundled NCERT PDFs unused
3. **Cloud Sync:** Pull is unimplemented (empty loop)
4. **ML Service:** Dummy tokenizer (character-code based)
5. **Rank Predictor:** Static 2023-2024 table
6. **No Batch Segmentation:** Class 11/12/Dropper onboarding missing
7. **No Retention Mechanics:** No streaks, leaderboards, spaced repetition
8. **Duplicate Providers:** `lib/core/provider/providers.dart` vs `lib/core/providers/providers.dart` conflict
9. **AI Chatbot:** Generic Gemini chat, not NCERT-grounded or exam-specific

---

## 6. Preliminary Gap Classification

### Fatal (Block competitive parity)
- Question bank <500 vs. competitors 33K–100K+
- No spaced repetition / retention engine
- No CBT-ready mock test simulator (NEET 2027 shift)
- AI chatbot not grounded in NCERT content

### Major (Significant UX/engagement deficit)
- No streaks, leaderboards, gamification
- No personalized study plans (static study plan screen only)
- Rank predictor is hardcoded/outdated
- Cloud sync incomplete
- No error analytics beyond basic error book

### Minor (Polish/retention)
- Duplicate provider files
- PDF asset naming scheme unused
- Biometric lock present but no per-topic lock for study plans
- No formula cards / quick revision notes

---

## 7. Product DNA Assessment

### Does neet_mitos need a formal Product DNA?
**Yes, but narrowly.** The app already has a clear implicit DNA:
- "Free, offline-first NCERT-anchored NEET prep"
- Missing: explicit batch segmentation (Class 11/12/Dropper), retention loop, and adaptive layer

### Proposed Product DNA Statement
> **neet_mitos** is a free, offline-first NEET preparation platform that turns every NCERT line into actionable practice. We believe rank comes from recall, not just coverage — so we combine line-by-line question fidelity with an AI-native revision engine that respects how a student's memory actually fades. No paywalls on core prep. No internet required to practice. No wasted study time on content the exam will never ask.

### Differentiation Levers
1. **NCERT Fidelity:** Bundled PDFs + line-by-line mapping (if question bank grows)
2. **Free-First:** No content paywalls; backend costs subsidized by efficient architecture
3. **Offline-First:** Built for tier-2/3 India where connectivity is unreliable
4. **AI-Native:** Gemini integration already exists; needs RAG grounding

---

## 8. ML/AI Architecture Assessment

### Current State
- Gemini chat service exists but is generic
- ML service is dummy code
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
│  - Usage analytics ( anonymized )           │
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
1. **Spaced Repetition Engine:**
   - Implement FSRS v6 in Dart (or SM-2 for simplicity)
   - Local-only scheduling; no server round-trips
   - Track: stability, difficulty, retrievability

2. **RAG Pipeline:**
   - Chunk NCERT PDFs + high-quality explanations
   - Embed with Gemini `embedContent` or open-source model
   - Store in Supabase PostgreSQL + pgvector
   - Retrieve top-k chunks per query

3. **AI Tutor:**
   - System prompt: "You are a NEET UG tutor. Cite NCERT chapter/section. Explain step-by-step. Never hallucinate facts."
   - Guardrails: forbid answers to active exam questions, flag outdated content
   - Cost control: 80/20 rule — 80% queries handled by cached/RAG, 20% by LLM

4. **Analytics:**
   - Local computation for privacy and cost
   - Sync anonymized aggregates to backend for benchmarking

---

## 9. Prioritized Roadmap

### Phase 1: Fix Foundations (Weeks 1–4) — *Fatal*
1. **Question Bank Expansion** — Target 5,000 verified NCERT MCQs (Biology first, then Chem/Phy)
   - Source: open NCERT Exemplar + PYQ + community curation
   - Effort: High; consider partnership/import pipeline
2. **Fix Cloud Sync** — Implement pull + push for progress/bookmarks
3. **Fix Duplicate Providers** — Consolidate to single provider file
4. **Batch Onboarding** — Class 11 / Class 12 / Dropper selection at launch

### Phase 2: Retention Engine (Weeks 5–8) — *Major*
5. **Spaced Repetition** — Implement FSRS/SM-2 for flashcards + missed questions
6. **Streaks & Daily Goals** — Daily practice streak with streak-freeze mechanic
7. **Rank Predictor V2** — Data-driven model using historical NEET cutoffs + user accuracy

### Phase 3: AI Layer (Weeks 9–12) — *Major*
8. **NCERT-Grounded Chat** — RAG over bundled PDFs + question bank
9. **AI Test Analysis** — Weak topic detection, mistake pattern recognition
10. **Smart Revision Notes** — Auto-generate summary cards from weak areas

### Phase 4: Exam Simulation (Weeks 13–16) — *Fatal/Major*
11. **CBT Mock Test Simulator** — Timer, negative marking, section jumping, break simulation
12. **Custom Test Builder** — Chapter/topic/difficulty selection
13. **Performance Analytics Dashboard** — Subject-wise accuracy trends, time-per-question, peer benchmarking

### Phase 5: Content Scale (Weeks 17–24) — *Ongoing*
14. **PYQ Database** — 30 years NEET PYQs chapter-wise
15. **HD Study Notes** — Per-chapter consolidated notes
16. **Video Integration** — Embed/link to curated free YouTube content (NCERT mapping)

---

## 10. Monetization (Free-First Constraint)

### Backend Cost Optimization
- Supabase Free Tier for first 500 MAU
- AI: Gemini Flash + Groq free tier + caching
- Offline-first = 90%+ features work without backend
- Target: <$50/month for first 1,000 active users

### Non-Paywall Revenue Options
- Affiliate links to coaching platforms (ethical disclosure)
- Sponsored content from edtech partners (maintains free UX)
- Donation/ sponsorship model (OpenMedQ proves viability)
- White-label for schools/coaching classes

### What NOT to Paywall
- Question bank access
- Basic test series
- Flashcard scheduling
- Error book
- AI chat (rate-limited but available)

---

## Sources
- Revisable: https://www.revisableapp.com/, Google Play, Apple App Store
- Mitos Learning: AppBrain, APKPure
- MARKS: getmarks.app, Google Play, mathongo.com
- MemoNeet: memoneet.com, Google Play, Apple App Store
- Darwin: darwin.mcqdb.com, Google Play
- Spaced Repetition: open-spaced-repetition/FSRS, neetpgai.com
- AI Architecture: neet-live-buddy (GitHub), StudyOS (GitHub), ScholarNet AI (Hashnode), Studeia docs
- Benchmarks: Business of Apps, AcademyCheck, AiMedStudy
- NEET CBT: Find My Guru blog
- Supabase: supabase.com/pricing
