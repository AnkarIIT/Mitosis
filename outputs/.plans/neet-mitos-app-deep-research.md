# Deep Research Plan: NEET Mitos App Analysis & Launch Strategy

**Slug:** neet-mitos-app-deep-research  
**Date:** 2025-08-17  
**Mode:** Direct search (lead-owned) — single Flutter codebase audit + NEET edtech market research  
**Scale decision:** Narrow-to-moderate breadth. The core artifact is one concrete app repo, so decomposition into researcher subagents is not justified. All evidence gathering, synthesis, and drafting will be done directly.

---

## Key Questions

1. **Codebase health:** What is the current state of the NEET Mitos Flutter app (architecture, features, bugs, missing pieces)?
2. **NEET alignment:** How well does the app match actual NEET UG 2026 exam pattern, syllabus, and student needs for Class 11, Class 12, and Dropper batches?
3. **PDF assets utilization:** The `assets/ncert_books/` folder contains Physics, Chemistry, and Biology chapter PDFs for Class 11 and 12. How can these be used inside the app?
4. **Competitive positioning:** How does NEET Mitos compare to Darwin, Unprep, PYQBank, Aakash, and other NEET prep apps?
5. **Helpfulness score:** For a NEET aspirant, how valuable is this app in current state? What is the gap to "best possible"?
6. **Fixes & launch plan:** What are the critical fixes, feature gaps, and prioritized roadmap to launch a production-ready, student-helpful app?

---

## Evidence Needed

- **Code evidence:** Read `lib/` structure, `pubspec.yaml`, database schema, providers, key screens, services, and assets.
- **NEET official pattern:** 180 questions, 720 marks, 3 hours, Physics 45, Chemistry 45, Biology 90 (Botany 45 + Zoology 45), marking scheme (+4 / -1).
- **Competitor features:** Darwin (38K MCQs, flashcards, PYQs, analytics), Unprep (AI tracker), PYQBank (35K MCQs, mock tests), Aakash (live classes, test series).
- **PDF/legal constraints:** NCERT copyright status, ePathshala licensing, fair-use considerations for educational apps.
- **Edtech best practices:** Offline-first, performance, question bank size, analytics latency, monetization, vernacular support.

---

## Task Ledger

| Task | Owner | Status | Output |
|------|-------|--------|--------|
| T1. Audit Flutter project structure, dependencies, database, auth, and core services | Lead | In Progress | Code findings in research notes |
| T2. Audit all feature screens (quiz, test series, chatbot, study plan, booster, PDF engine) | Lead | Pending | Feature gap list |
| T3. Research NEET 2026 exam pattern, syllabus weightage, and student pain points | Lead | Pending | NEET requirements brief |
| T4. Research competitor NEET apps (Darwin, Unprep, PYQBank, Aakash) and feature benchmarks | Lead | Pending | Competitor matrix |
| T5. Research NCERT PDF usage, copyright, and integration patterns in edtech | Lead | Pending | Legal/usage notes |
| T6. Synthesize findings into draft report with executive summary, findings, fixes, roadmap | Lead | Pending | `outputs/.drafts/<slug>-draft.md` |
| T7. Add citations, verify URLs, write cited draft and provenance | Lead | Pending | `outputs/.drafts/<slug>-cited.md`, `<slug>.provenance.md` |
| T8. Review, fix any fatal issues, copy final to `outputs/<slug>.md` and `papers/<slug>.md` | Lead | Pending | Final deliverable |

---

## Verification Log

- [ ] T1: All `lib/` files enumerated and key files read
- [ ] T2: All screens mapped to feature list
- [ ] T3: NEET exam pattern confirmed from 2+ sources
- [ ] T4: Competitor data confirmed from official stores/websites
- [ ] T5: NCERT copyright status confirmed from official NCERT/epathshala sources
- [ ] T6: Draft written with all critical claims sourced
- [ ] T7: All URLs in cited draft verified reachable
- [ ] T8: Final artifacts exist on disk with correct structure

---

## Decision Log

- **2025-08-17:** Chose direct-search mode. Topic is a single concrete app + market analysis, not a broad multi-paper survey. Subagents would add overhead without proportional evidence gain.
- **2025-08-17:** Chose to treat PDF assets as a separate evidence stream. The folder structure is unusual (`kebo101.pdf`, `lebo101.pdf` etc.) and needs mapping before recommending usage.
- **2025-08-17:** Chose to include Class 11/12/Dropper segmentation as a first-class analysis axis because the user explicitly asked for it.
