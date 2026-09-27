# NEET Mitos — Local-First Proper App Plan

## Goal
Make the app behave like a proper production app: offline-first, zero server dependency, zero ongoing cost, optional cloud features.

## Principles
1. **Local-first**: All core features work without internet
2. **Cloud-optional**: Supabase is a bonus, not a requirement
3. **Zero ongoing cost**: No paid APIs, no servers, no infrastructure
4. **Production-ready**: Error boundaries, loading states, offline indicators

## Phase 1: Make Supabase Lazy (P0)
**Target**: App launches without Supabase initialization

### Changes
- `main.dart`: Remove `Supabase.initialize()` from startup
- `app_config.dart`: Add `enableCloudSync`, `enableAiProxy`, `enableCloudAuth` flags (all false)
- `auth_service.dart`: Keep local guest flow only, cloud methods become no-ops when disabled
- Settings screen: Add toggles for cloud features (off by default)

### Files to modify
- `lib/main.dart`
- `lib/core/config/app_config.dart`
- `lib/core/services/auth_service.dart`
- `lib/features/settings/settings_screen.dart`

## Phase 2: Remove Edge Function Dependency (P0)
**Target**: No Gemini proxy calls; app works fully offline

### Changes
- `ai_router_service.dart`: Remove `_searchLocalRag()` stub, replace with local TF-IDF
- `gemini_proxy_service.dart`: Make it optional — only instantiate when user enables AI
- `chatbot_screen.dart`: Show "AI requires cloud sync" when proxy unavailable
- `explanation_seeder.dart`: Delete entirely (explanations come from bundled JSON)

### Files to modify
- `lib/core/services/ai_router_service.dart`
- `lib/core/services/gemini_proxy_service.dart`
- `lib/features/chatbot/chatbot_screen.dart`
- DELETE: `lib/core/services/explanation_seeder.dart`

## Phase 3: Remove Cloud Sync Dependency (P0)
**Target**: No mandatory cloud sync; Drift is the single source of truth

### Changes
- `cloud_sync_service.dart`: Delete entirely OR make it a settings toggle
- `question_repository.dart`: Remove `importBundledQuestions` dependency on cloud
- `database_service.dart`: Remove sync triggers
- `app_router.dart`: Remove cloud-auth redirect logic

### Files to modify
- DELETE: `lib/core/services/cloud_sync_service.dart`
- `lib/core/database/question_repository.dart`
- `lib/core/services/database_service.dart`
- `lib/core/router/app_router.dart`

## Phase 4: Add Local AI (P1)
**Target**: Functional AI hints without any cloud API

### Changes
- Create `lib/core/services/local_ai_service.dart`
  - TF-IDF search on bundled NCERT text
  - Rule-based hint generation
  - Weak topic detection from quiz history
- Wire into chatbot screen as fallback when cloud AI unavailable
- Add "AI Hint" button to quiz screen using local AI

### Files to create
- `lib/core/services/local_ai_service.dart`
- `lib/core/services/ncert_search_service.dart`

## Phase 5: Add Offline Indicators (P1)
**Target**: User always knows network/cloud status

### Changes
- Add connectivity checker (`connectivity_plus` or `internet_connection_checker`)
- Show banner when offline
- Show "Cloud features unavailable" when Supabase not initialized
- Add retry logic for transient failures

### Files to modify
- `lib/core/widgets/offline_banner.dart` (create)
- `lib/core/services/connectivity_service.dart` (create)

## Phase 6: Error Boundaries (P2)
**Target**: App never crashes; shows graceful error states

### Changes
- Add `ErrorWidget.builder` override in `main.dart`
- Wrap screens in try-catch with fallback UI
- Add crash reporting (optional, local-only)

### Files to modify
- `lib/main.dart`
- `lib/core/error/app_error_widget.dart` (create)

## Phase 7: Cleanup Dead Code (P2)
**Target**: Remove Supabase dependencies entirely from pubspec

### Changes
- Remove `supabase_flutter` from `pubspec.yaml`
- Remove `supabase/` folder
- Remove dead imports across all files
- Delete backup files (`home_tab_backup.dart`, etc.)

### Files to modify
- `pubspec.yaml`
- DELETE: `supabase/` folder
- Various: remove dead imports

## Success Criteria
1. App launches without any network request
2. All core features (quiz, flashcards, CBT, progress) work offline
3. No Supabase dependency in release build
4. Zero debug crashes on cold start
5. Analyzer: 0 errors, <10 warnings
6. Tests: 130+ passing
