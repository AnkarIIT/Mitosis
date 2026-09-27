# Provenance: revisable-mitos-marks-audit

**Generated:** 2026-01-18  
**Auditor:** Feynman (direct-search mode)  
**Canonical Artifact:** `outputs/revisable-mitos-marks-audit.md`

---

## Source Inventory

### Primary Web Sources (fetched)
1. `https://www.revisableapp.com/` — Revisable marketing site, pricing, feature claims
2. `https://play.google.com/store/apps/details?hl=en_IN&id=com.revio.revisable` — Revisable Google Play listing
3. `https://apps.apple.com/in/app/revisable-neet-usmle-amc/id6451157089` — Revisable Apple App Store listing
4. `https://www.appbrain.com/app/mitos-learning-neet-prep-app/com.mitoslearning` — Mitos Learning AppBrain listing
5. `https://apkpure.com/kr/mitos-learning-neet-prep-app/com.mitoslearning` — Mitos Learning APKPure listing (Korean)
6. `https://getmarks.app/` — MARKS marketing site
7. `https://play.google.com/store/apps/details?id=com.scoremarks.marks&hl=en_IN` — MARKS Google Play listing
8. `https://www.youtube.com/watch?v=GCa221rI9vE` — MARKS custom tests YouTube video
9. `https://www.memoneet.com/` — MemoNeet website (returned in Mitos Learning searches)
10. `https://play.google.com/store/apps/details?id=com.adithya.memoneet&hl=en_IN` — MemoNeet Google Play listing

### Secondary Web Sources (search results / citations)
11. `https://darwin.mcqdb.com/` — Darwin NEET Prep (competitor benchmark)
12. `https://play.google.com/store/apps/details?id=com.neet_darwin_mcqdb&hl=en` — Darwin Google Play
13. `https://www.medicneet.com/neet-app` — MedicNEET (retention benchmarks)
14. `https://apps.apple.com/us/app/yukthis-neet/id6760161721` — Yukthis (gamification benchmarks)
15. `https://www.edvaya.com/edvaya-target` — Edvaya (retention benchmarks)
16. `https://www.businessofapps.com/data/education-app-benchmarks/` — Retention benchmarks
17. `https://neetpgai.com/neet-pg-study-material/how-to-use-spaced-repetition-for-neet-pg` — SR benefits claim
18. `https://github.com/open-spaced-repetition/free-spaced-repetition-scheduler` — FSRS algorithm
19. `https://ai-study-platform.hashnode.dev/building-scholarnet-ai-lessons-from-creating-an-ai-study-platform-1-1-1-1-1-1-1-1-1-1-1` — AI cost optimization case study
20. `https://supabase.com/pricing` — Supabase pricing
21. `https://github.com/lkarthik76/neet-live-buddy` — NEET RAG architecture reference
22. `https://github.com/rohitkumarnaidu/StudyOS` — StudyOS architecture reference
23. `https://www.findmyguru.com/blog/best-neet-preparation-apps-in-india` — NEET CBT 2027 transition

### Internal Codebase Sources
24. `C:/Users/ankar/neet_mitos/lib/core/constants/neet_sample_data.dart` — Question count verification
25. `C:/Users/ankar/neet_mitos/lib/core/services/cloud_sync_service.dart` — Sync implementation gap
26. `C:/Users/ankar/neet_mitos/lib/core/utils/rank_predictor.dart` — Hardcoded data verification
27. `C:/Users/ankar/neet_mitos/lib/core/services/gemini_chat_service.dart` — Generic chat wrapper
28. `C:/Users/ankar/neet_mitos/lib/core/services/ml_service.dart` — Dummy tokenizer
29. `C:/Users/ankar/neet_mitos/lib/core/services/pdf_service.dart` — PDF handling
30. `C:/Users/ankar/neet_mitos/lib/features/test_series/pdf_picker_screen.dart` — file_picker usage
31. `C:/Users/ankar/neet_mitos/lib/core/provider/providers.dart` — Duplicate provider file
32. `C:/Users/ankar/neet_mitos/lib/core/providers/providers.dart` — Duplicate provider file
33. `C:/Users/ankar/neet_mitos/assets/ncert_books/` — Bundled PDF assets (structure inspected)

---

## Verification Log

| Check | Method | Result |
|-------|--------|--------|
| Question bank size verified | Code inspection (`neet_sample_data.dart`, `neet_sample_data_phase2.dart`) | Confirmed: ~26 seeded questions, total <500 |
| Cloud sync pull gap verified | Code inspection (`cloud_sync_service.dart`) | Confirmed: empty loop body in pull logic |
| Rank predictor hardcoded verified | Code inspection (`rank_predictor.dart`) | Confirmed: 2023–2024 static table |
| ML service dummy verified | Code inspection (`ml_service.dart`) | Confirmed: character-code based tokenization |
| Duplicate providers verified | Filesystem inspection | Confirmed: two provider files with conflicting content |
| Bundled PDFs unused verified | Code inspection (`pdf_picker_screen.dart`, `pdf_service.dart`) | Confirmed: uses `file_picker`, not bundled assets |
| Revisable features verified | Web fetch + search | 2+ independent sources (website, Play Store, App Store) |
| Mitos Learning features verified | Web search | Limited sources (AppBrain, APKPure only); low confidence |
| MARKS features verified | Web fetch + search | 2+ independent sources (website, Play Store, YouTube) |
| MemoNeet conflation identified | Search result analysis | Confirmed: search results mix Mitos Learning and MemoNeet |
| NEET CBT 2027 claim verified | Web search | 1 source (Find My Guru); **unverified** — needs NTA official confirmation |
| Retention benchmarks verified | Web search | Business of Apps, Passion.io; general edtech benchmarks |
| Spaced repetition benefit claim verified | Web search | NEETPGAI blog; **inference** — claim is from a prep site, not peer-reviewed study |
| FSRS algorithm availability verified | GitHub source | Confirmed: open-source implementations in Kotlin, TypeScript, Ruby |
| AI cost optimization case study verified | Web fetch | ScholarNet AI article; **inference** — costs are self-reported by author |
| Supabase pricing verified | Web fetch | Confirmed: Free + Pro tiers |

---

## Confidence & Uncertainty Notes

### High Confidence
- Revisable feature set, pricing, and positioning (multiple official sources)
- MARKS app features and download metrics (official site + Play Store)
- neet_mitos codebase gaps (direct file inspection)
- Competitor question bank size claims (as stated by competitors; not independently audited)

### Medium Confidence
- Mitos Learning feature set (only two third-party app-store aggregator sources; no official website or Play Store listing inspected directly)
- MemoNeet vs. Mitos Learning distinction (search-engine conflation; requires manual app-store verification)
- NEET CBT 2027 transition (single secondary source; NTA has not issued formal notification per our search)

### Low Confidence / Inference
- Spaced repetition "200% retention improvement" claim (source is a commercial prep blog, not a randomized controlled trial)
- ScholarNet AI cost reduction "60%" (self-reported case study, not peer-reviewed)
- Revisable's "10,000+ rankers in 12 months" (marketing claim; no third-party verification)
- Darwin's "97% of NEET UG 2025 questions were from Darwin" (marketing claim; no independent audit)

### Blocked / Unverified
- **NTA official NEET 2027 CBT notification:** Not found in search. The Find My Guru article is the only source; treated as inference until NTA confirms.
- **Mitos Learning Play Store direct inspection:** We accessed AppBrain and APKPure, which aggregate Play Store data. We did not directly fetch the Google Play listing for `com.mitoslearning`.
- **MemoNeet exact question count:** MemoNeet claims 35,000+; not independently verified.
- **Revisable exact question/flashcard count:** Claims 100K+ MCQs / 200K+ flashcards; not independently verified.

---

## Known Limitations

1. **Mitos Learning is a low-visibility app.** Only two third-party sources were found. The audit relies heavily on these two listings. If the user intended to benchmark against MemoNeet (phonetically similar, much larger), the competitor analysis should be rerun with MemoNeet as the primary target.

2. **Competitor claims are self-reported.** Question counts, ranker counts, and match percentages come from marketing materials. This is standard for competitive audits but should be caveated in board-level presentations.

3. **No direct API access to competitors.** All data is from public-facing web sources. No reverse-engineering or unauthorized data collection was performed.

4. **NEET CBT 2027 claim is unverified.** If NTA reverses or delays the CBT transition, Phase 4 roadmap priority changes.

---

## Reproducibility

All web sources were fetched or searched on 2026-01-18 using `web_search` and `fetch_content`. Codebase inspection was performed on the `C:/Users/ankar/neet_mitos` working tree at the same date. Re-running web searches may yield different results if competitors update their listings or marketing copy.
