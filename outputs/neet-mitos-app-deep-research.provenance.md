# Provenance: NEET Mitos App Deep Research

**Artifact:** `outputs/neet-mitos-app-deep-research.md`  
**Generated:** 2026-01-18  
**Method:** Direct codebase inspection + web search

---

## 1. Evidence Gathered

### 1.1 Codebase Files Read (Direct Inspection)

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry, theme, providers setup |
| `lib/core/config/app_config.dart` | App configuration constants |
| `lib/core/constants/neet_sample_data.dart` | Seeded question bank (~919 lines) |
| `lib/core/constants/neet_sample_data_phase2.dart` | Additional seeded questions (~858 lines) |
| `lib/core/constants/sample_questions.dart` | Placeholder (4 lines) |
| `lib/core/database/drift_database.dart` | Drift schema, tables, DAO |
| `lib/core/database/question_repository.dart` | Question seeding + DB queries |
| `lib/core/models/question_model.dart` | Question data model |
| `lib/core/models/subject_model.dart` | Subject/chapter/topic model |
| `lib/core/models/user_progress_model.dart` | Progress tracking model |
| `lib/core/models/flashcard_model.dart` | Flashcard model |
| `lib/core/models/mark_booster_model.dart` | Mark booster diagnosis model |
| `lib/core/provider/providers.dart` | Riverpod providers (1 of 2 files) |
| `lib/core/providers/providers.dart` | Riverpod providers (2 of 2 files) |
| `lib/core/services/auth_service.dart` | Supabase auth + 2FA stub |
| `lib/core/services/gemini_chat_service.dart` | Gemini AI integration |
| `lib/core/services/pdf_service.dart` | PDF text extraction + chapter splitting |
| `lib/core/services/question_importer.dart` | JSON/CSV bulk import |
| `lib/core/services/database_service.dart` | Local DB wrapper |
| `lib/core/services/ml_service.dart` | TFLite similarity + fallback |
| `lib/core/services/cloud_sync_service.dart` | Supabase sync (push-only) |
| `lib/core/services/mark_booster_service.dart` | Drill builder logic |
| `lib/core/services/question_paper_generator.dart` | PYQ paper generation |
| `lib/core/services/notification_service.dart` | Local notifications |
| `lib/core/theme/app_colors.dart` | Color scheme |
| `lib/core/theme/app_theme.dart` | Material theme definitions |
| `lib/core/utils/rank_predictor.dart` | Static rank table |
| `lib/features/home/home_screen.dart` | Home dashboard |
| `lib/features/quiz/enhanced_quiz_screen.dart` | Main quiz UI |
| `lib/features/test_series/test_series_screen.dart` | Test series browser |
| `lib/features/test_series/pdf_picker_screen.dart` | PDF upload + AI question gen |
| `lib/features/test_series/question_paper_selector.dart` | Paper selection UI |
| `lib/features/test_series/test_result_screen.dart` | Results screen |
| `lib/features/topic_browser/topic_browser_screen.dart` | Chapter/topic tree |
| `lib/features/topic_browser/topic_detail_screen.dart` | Topic detail + NCERT summary |
| `lib/features/flashcards/flashcard_screen.dart` | Flashcard UI |
| `lib/features/progress/progress_dashboard.dart` | Analytics dashboard |
| `lib/features/error_book/error_book_screen.dart` | Error book + re-test |
| `lib/features/bookmarks/bookmarks_dashboard.dart` | Revision vault |
| `lib/features/mark_booster/mark_booster_screen.dart` | Mark booster UI |
| `lib/features/chatbot/chatbot_screen.dart` | AI chatbot UI |
| `lib/features/settings/settings_screen.dart` | Settings |
| `lib/features/settings/import_questions_screen.dart` | Bulk import UI |
| `lib/features/study_plan/study_plan_screen.dart` | Study planner |
| `lib/features/onboarding/onboarding_screen.dart` | Onboarding flow |
| `pubspec.yaml` | Dependencies |
| `supabase/01_content_catalog.sql` | Remote schema + RLS |
| `README.md` | Project overview |

**Verified via shell:**
- `find lib -type f -name "*.dart" | sort` — full file inventory
- `diff core/provider/providers.dart core/providers/providers.dart` — confirmed duplicate provider files
- `grep -n "getAllQuestions"` — verified function exists at `neet_sample_data.dart:911`
- `grep -E "^final List<Question>"` — confirmed 7 question lists across 2 files
- `find assets/ncert_books -type f | sort` — full PDF inventory

### 1.2 Web Sources

| Claim | Source | URL |
|-------|--------|-----|
| NEET 2026: 180 questions, 720 marks, 3 hrs, -1 neg marking | NTA notice, Careers360, Jagranjosh, Times Now, Shiksha, Vedantu | https://medicine.careers360.com/articles/neet-exam-pattern, https://www.timesnownews.com/education/neet-ug-2026-marking-scheme-explained-nta-breaks-down-subject-wise-weightage-and-scoring-article-154679872, https://timesofindia.indiatimes.com/education/news/neet-ug-re-exam-2026-on-june-21-nta-shares-key-details-on-exam-pattern-marking-scheme/articleshow/131823168.cms, https://www.jagranjosh.com/articles/neet-ug-2026-exam-pattern-total-marks-scheme-paper-questiondistribution-1800002705-1, https://www.shiksha.com/medicine-health-sciences/neet-exam-pattern, https://www.vedantu.com/neet/neet-exam-pattern |
| NEET 2026 syllabus unchanged from 2025 | NMC/UGMEB notice, Careers360 | https://medicine.careers360.com/articles/nmc-neet-ug-syllabus-2026-unchanged-no-addition-or-reduction, https://nta.ac.in/Download/Notice/Notice_20260108180635.pdf |
| Competitor feature sets | Darwin, Unprep, Yukthis, Lytmus AI, Super Tutor | https://darwin.mcqdb.com/, https://play.google.com/store/apps/details?id=com.unbind&hl=en, https://apps.apple.com/us/app/yukthis-neet/id6760161721, https://lytmus.ai/, https://supertutor.in/ai-tutor-for-neet/ |
| NCERT copyright policy | NCERT official press release | https://ncert.nic.in/pdf/announcement/notices/Press_Release_Copyright_Infringement-NCERT.pdf |
| ePathshala as legal NCERT distribution | NCERT/CIET | https://ciet.ncert.gov.in/storage/app/public/files/17/Presentation%20PDF/Epathshala%20Apps%20for%20Education%20(1).pdf |
| Flutter + Drift + Supabase offline-first patterns | Medium, Samioda blog | https://medium.com/@fintasys/offline-first-flutter-drift-as-the-source-of-truth-supabase-as-a-sync-target-eab7c43523ce, https://samioda.com/en/blog/flutter-supabase-auth-realtime-offline-sync |

---

## 2. Verification Log

| Check | Result | Notes |
|-------|--------|-------|
| `getAllQuestions()` existence | ✅ Verified | Found at `neet_sample_data.dart:911` |
| Duplicate provider files | ✅ Verified | `core/provider/` and `core/providers/` differ |
| PDF asset inventory | ✅ Verified | 96 files across 10 folders |
| Question list inventory | ✅ Verified | 7 lists across 2 files |
| Cloud sync pull implementation | ❌ Not implemented | Empty loop body confirmed |
| ML tokenizer logic | ⚠️ Fallback only | Character-code tokenization; no real vocab |
| Rank predictor data freshness | ⚠️ Stale | Hardcoded 2023-2024 table |
| Biometric service integration | ❌ Not verified | File not inspected |

---

## 3. Known Gaps & Limitations

1. **Exact question count:** Not enumerated; inferred "<500" from file sizes.
2. **Biometric lock:** `biometric_service.dart` exists but was not opened.
3. **Auth 2FA implementation:** `two_factor_screen.dart` exists but `auth_service.dart` shows no 2FA logic.
4. **Content sync service:** `content_sync_service.dart` exists but was not inspected.
5. **Question paper selector / test result screens:** UI files exist but were not fully traced.
6. **App store metadata:** `ios/`, `android/`, `macos/` folders not inspected.
7. **Test coverage:** No test directories were inspected; unit/integration test status unknown.
8. **CI/CD:** No `.github/workflows`, `fastlane`, or `codemagic` files were inspected.

---

## 4. Corrections

| Initial Claim | Correction | Source |
|---------------|-----------|--------|
| `getAllQuestions()` missing in `question_paper_generator.dart` | **Incorrect.** Function exists in `neet_sample_data.dart:911` and is imported. | Direct code inspection |

---

## 5. Reproducibility

All file paths and line numbers above can be re-verified by:
```bash
cd C:/Users/ankar/neet_mitos
grep -n "getAllQuestions" lib/core/constants/neet_sample_data.dart
diff lib/core/provider/providers.dart lib/core/providers/providers.dart
find lib -type f -name "*.dart" | sort
find assets/ncert_books -type f | sort
```

Web sources were fetched via `web_search` and `source_check` on 2026-01-18.
