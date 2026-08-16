# Plan: Revisable / Mitos Learning / MARKS Competitive Audit + Gap Analysis

**Slug:** `revisable-mitos-marks-audit`  
**Date:** 2026-01-18  
**Mode:** Direct search (single lead) — competitive audit is bounded and can be answered with targeted web research plus existing codebase inspection notes.  
**Scale decision:** Direct search. Topic requires 3–5 web queries per competitor plus synthesis; researcher subagents would add overhead without proportional evidence gain.

---

## Key Questions

1. What are the defining features, UX patterns, and differentiators of **Revisable**, **Mitos Learning**, and **MARKS by MathonGo**?
2. How does **our app** (`neet_mitos`) compare against each on: content scale, AI/ML, analytics, UX, retention mechanics, and offline capability?
3. What **gaps** are fatal vs. nice-to-have for a “free, industry-level” NEET app?
4. Do we need a formal **product DNA**, **ML pipeline**, or **backend proxy** to reach parity or leadership?
5. What is the **prioritized roadmap** to close the gaps?

---

## Evidence Needed

| Source | What to extract |
|--------|-----------------|
| Web search: Revisable app | Core features, AI tutor mechanism, spaced repetition implementation, content scope, UX philosophy |
| Web search: Mitos Learning app | NCERT line-by-line methodology, question count, error book design, analytics depth |
| Web search: MARKS by MathonGo | PYQ organization, custom test creation, UI design principles, performance claims |
| Web search: NEET app competitive analysis 2025/2026 | Industry benchmarks, user expectations, monetization patterns, retention tactics |
| Web search: spaced repetition algorithms for NEET | SM-2, FSRS, Anki-style scheduling applicability |
| Web search: AI tutoring for medical entrance exams | Prompt engineering, RAG vs. fine-tuning, cost structures for free apps |
| Internal codebase notes | Existing feature matrix from `neet-mitos-app-deep-research.md` and prior session summary |

---

## Task Ledger

| ID | Task | Owner | Status |
|----|------|-------|--------|
| T1 | Research Revisable: features, AI, spaced repetition, UX | Lead | Pending |
| T2 | Research Mitos Learning: NCERT fidelity, error book, analytics | Lead | Pending |
| T3 | Research MARKS by MathonGo: PYQ database, test creation, UI | Lead | Pending |
| T4 | Synthesize competitor differentiators into comparison matrix | Lead | Pending |
| T5 | Audit our app against matrix; classify gaps as Fatal / Major / Minor | Lead | Pending |
| T6 | Draft recommendations: product DNA, ML/AI architecture, roadmap | Lead | Pending |
| T7 | Cite all claims; write `-cited.md` | Lead | Pending |
| T8 | Verification pass; write final artifacts + provenance | Lead | Pending |

---

## Verification Log

| Check | Method | Pass Criteria |
|-------|--------|---------------|
| Competitor features verified | Web search + fetch | Each app has ≥2 independent sources |
| Gap classification grounded | Cross-reference with prior audit | Every Fatal/Major/Minor gap maps to a competitor feature or our code inspection |
| Recommendations actionable | Synthesis | Each recommendation has owner, effort estimate, and success metric |
| Sources cited | Inline URLs | No unsupported benchmark or feature claim in final draft |

---

## Decision Log

| Decision | Rationale |
|----------|-----------|
| Direct search over subagents | Topic is a bounded 3-competitor audit; direct search reduces context pressure and avoids duplication. |
| Include product DNA + ML pipeline in scope | User explicitly requested “proper dna, ml, etc.” if needed; must assess whether this is required or over-engineering. |
| Free-first constraint | All recommendations must be implementable without paid user-facing locks; backend costs must be subsidized or minimized. |
