# NEET Mitos - Architecture Document

## 1. High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              FLUTTER APP (Client)                           │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │
│  │   Features   │  │  Providers   │  │  Core/Services│  │   Database   │   │
│  │  (UI Layer)  │──│  (State Mgmt)│──│  (Business   │──│  (Drift/SQLite)│  │
│  └──────────────┘  └──────────────┘  │   Logic)     │  └──────────────┘   │
│                                       └──────────────┘         │           │
│  ┌──────────────┐  ┌──────────────┐                           ▼           │
│  │   Router     │  │   Theme      │  ┌─────────────────────────────────┐  │
│  │  (go_router) │  │  (M3 + M3)   │  │        SUBASE (Backend)         │  │
│  └──────────────┘  └──────────────┘  │  ┌──────┐ ┌──────┐ ┌────────┐  │  │
│                                       │  │ Auth │ │ DB   │ │ Edge   │  │  │
│  ┌──────────────┐                     │  │      │ │(RLS) │ │ Funcs  │  │  │
│  │   Assets     │                     │  └──────┘ └──────┘ └────────┘  │  │
│  │  (Questions, │                     │         ▲          ▲           │  │
│  │   NCERT PDFs)│                     └─────────│──────────│───────────┘  │
│  └──────────────┘                       HTTPS/WS  │          │            │
└───────────────────────────────────────────────────│──────────│────────────┘
                                                    ▼          ▼
                                         ┌────────────────────────────┐
                                         │      EXTERNAL APIs         │
                                         │  • Gemini (AI)             │
                                         │  • Resend (Email)          │
                                         └────────────────────────────┘
```

### Key Architectural Decisions

| Decision | Rationale |
|----------|-----------|
| **Offline-First** | Core study features (quiz, DPP, exam) work 100% offline; Supabase sync is optional enhancement |
| **Riverpod for State** | Compile-safe DI, fine-grained reactivity, easy testing with `ProviderContainer` overrides |
| **Drift (SQLite)** | Type-safe queries, migrations, reactive streams, works on all platforms |
| **go_router + StatefulShellRoute** | Deep linking, tab state preservation, declarative routing |
| **Material 3 + AdaptiveColors** | Consistent theming, proper dark mode support via `ColorScheme` |
| **Edge Functions for AI** | Cost control via prompt-hash cache, rate limiting, secrets never on client |

---

## 2. Module Structure

```
lib/
├── core/
│   ├── config/           # AppConfig (env, feature flags)
│   ├── constants/        # Static data (sample questions, subjects)
│   ├── database/         # Drift schema, migrations, DAOs
│   ├── models/           # Pure Dart domain models (Question, Flashcard, etc.)
│   ├── providers/        # Riverpod providers (organized by domain)
│   ├── router/           # go_router configuration
│   ├── services/         # Business logic (Auth, Sync, DPP, Exam, Quiz)
│   ├── theme/            # M3 Theme, AdaptiveColors, tokens
│   ├── utils/            # Security, helpers, rank predictor
│   └── widgets/          # Design system (AppButton, AppCard, AppTextField)
├── features/
│   ├── auth/             # Login (email/password, Google OAuth), terms, privacy
│   ├── chatbot/          # AI tutor chat
│   ├── dpp/              # Daily Practice Paper (gen + attempt)
│   ├── error_book/       # Wrong question review
│   ├── exam_engine/      # Full-length CBT (NEET mock)
│   ├── flashcards/       # AI-gen + manual, SM-2 scheduler
│   ├── home/             # 5-tab shell (Home, Flashcards, Review, Progress, Profile)
│   ├── mark_booster/     # Targeted weak-topic drills
│   ├── pdf/              # NCERT PDF viewer
│   ├── quiz/             # Topic-wise MCQ practice
│   ├── review/           # Spaced repetition + error book
│   ├── settings/         # Preferences, biometric lock
│   ├── study_plan/       # Schedule generator
│   ├── test_series/      # Pre-built mock papers
│   └── topic_browser/    # Subject → Chapter → Topic hierarchy
└── main.dart             # App bootstrap, background init
```

---

## 3. Core Engines — Zero-Compromise Guarantees

### 3.1 Exam Engine (`exam_engine_service.dart`)

**Purpose**: Full-length NEET simulation with NTA-compliant scoring.

**Key Guarantees**:
- ✅ **Section-aware allocation**: Physics/Chemistry/Botany/Zoology sections with independent question pools
- ✅ **Optional Section-B support**: N-of-M grading (first N answered count, rest discarded with 0 penalty)
- ✅ **Per-section timing**: Optional per-section countdown with break support
- ✅ **Deterministic shuffle**: Seed-based allocation for reproducible reviews
- ✅ **Answer validation**: Pool sanitization (empty text, <2 options, correct not in options)
- ✅ **Accurate scoring**: `rawScore = Σ marks` where marks ∈ {+4, -1, 0}, respects `gradedCount` caps
- ✅ **Checkpoint/Resume**: Full state serialization (answers, flags, time, section) for app kill recovery

**Scoring Formula**:
```
maxScore = Σ(min(gradedCount, allocatedCount)) × marksPerCorrect
rawScore = Σ(marksPerCorrect if correct else marksPerWrong if answered else 0) for counted questions
accuracy = correct / (correct + incorrect) × 100
```

### 3.2 DPP Engine (`dpp_engine.dart`)

**Purpose**: Daily Practice Paper generation with smart sampling.

**Key Guarantees**:
- ✅ **Difficulty-normalized sampling**: Uses `_normalizeDifficulty()` to handle "Easy"/"Medium"/"Hard" variants
- ✅ **Subject-weighted allocation**: NEET pattern (Physics 45, Chemistry 45, Botany 45, Zoology 45)
- ✅ **Weak-topic bias**: Mastery service feeds weak topic IDs; weak questions prioritized in pool
- ✅ **Exclusion of recent questions**: `QuestionHistoryService` prevents repeat within window
- ✅ **Per-subject difficulty balance**: Maintains easy/medium/hard ratios within each subject
- ✅ **Deterministic daily seed**: Same config + same day = same paper (for review/comparison)
- ✅ **Persisted to DB**: `DppSet` + `DppQuestions` tables for offline attempt + analytics

**Sampling Algorithm**:
```
1. Build pool: all questions matching config.subjects
2. Exclude recently seen (last N sessions)
3. If pool < 50% target → relax exclusion
4. If includeWeakTopics: partition into weak/strong, shuffle weak first
5. If subjectWeights: _sampleBySubject (per-subject difficulty balance)
   Else: _sample (global difficulty balance)
6. Backfill if short → return exactly config.totalQuestions
```

### 3.3 Quiz Engine (`quiz_providers.dart` + `enhanced_quiz_screen.dart`)

**Purpose**: Topic-wise adaptive MCQ practice with instant feedback.

**Key Guarantees**:
- ✅ **Option shuffling**: Per-session deterministic shuffle (seed stored in state)
- ✅ **Visited/Flagged tracking**: Palette shows answered/unanswered/flagged/current
- ✅ **Hint system**: Offline explanation first → AI proxy fallback (cached)
- ✅ **Short-answer AI eval**: ML service scores free-text (0-100), threshold at 65%
- ✅ **Time tracking**: Per-question + total elapsed, persisted in attempt
- ✅ **Bookmark/Error-book integration**: One-tap add to review systems
- ✅ **Subject score breakdown**: Per-subject correct count for analytics

---

## 4. Data Layer

### 4.1 Drift Schema (v25)

| Table | Purpose | Key Columns |
|-------|---------|-------------|
| `questions` | Local question bank | `id`, `subject`, `topicId`, `remoteId`, `updatedAt`, `isActive`, `source` |
| `quiz_attempts` | Practice history | `topicId`, `subject`, `score`, `incorrectCount`, `selectedAnswers`, `questionIds`, `seed`, `updatedAt` |
| `topic_progress` | Mastery tracking | `topicId`, `questionsAttempted`, `questionsCorrect`, `averageTimeSeconds`, `isCompleted` |
| `bookmarks` | User bookmarks | `questionId` (unique), `subject`, `topicId`, `bookmarkedAt` |
| `spaced_repetition` | SM-2 scheduler | `questionId`, `box`, `easeFactor`, `intervalDays`, `dueAt` |
| `flashcards` | AI/manual cards | `front`, `back`, `subject`, `box`, `dueAt`, `isGenerated` |
| `dpp_sets` | Daily papers | `date`, `subject`, `totalQuestions`, `durationMinutes` |
| `dpp_questions` | DPP questions | `dppSetId`, `questionId`, `difficulty`, `options` (JSON) |
| `users` | Local user + auth | `email`, `username`, `passwordHash`, `isTwoFactorEnabled` (legacy), `batch`, `targetYear`, `passwordResetCode`, `passwordResetExpiresAt` |
| `sync_watermarks` | Delta sync cursors | `remoteTable`, `lastSyncedAt` |

### 4.2 Supabase Schema (RLS Enabled)

| Table | RLS Policy | Notes |
|-------|------------|-------|
| `questions` | Public read `is_active=true`; Admin write | Content catalog |
| `tests` | Public read `is_published=true`; Admin write | Mock paper manifests |
| `quiz_attempts` | User owns `(user_id, attempted_at)` | `updatedAt` for conflict resolution |
| `topic_progress` | User owns `(user_id, topic_id)` | Timestamp-first sync |
| `bookmarks` | User owns `(user_id, question_id)` | Unique index prevents dupes |
| `ai_response_cache` | Service-role only | Prompt-hash cache for AI |
| `ai_usage_log` | Service-role only | Rate limiting (30/hr/user) |

---

## 5. Security Architecture

| Layer | Implementation |
|-------|----------------|
| **Auth** | Local email/password (PBKDF2) + optional Supabase Auth (Google OAuth, email/password) when configured; guest mode otherwise |
| **Secrets** | `.env` in `.gitignore`; Supabase keys via `flutter_dotenv`; Edge function secrets via `supabase secrets set` |
| **Password Hashing** | PBKDF2-HMAC-SHA256 (10k iterations, 16-byte salt) with legacy SHA-256 migration |
| **Biometric** | `local_auth` with `FlutterSecureStorage` for enabled flag |
| **Network** | `network_security_config.xml` with cert pinning (Supabase, Resend) |
| **Rate Limiting** | Client-side (auth attempts) + Server-side (AI proxy 30/hr) |
| **Data Sync** | Timestamp-first conflict resolution; `updatedAt` on all mutable tables |
| **RLS** | All user tables: `user_id = auth.uid()`; Catalog: public read active only |

---

## 6. AI / LLM Integration

**3-Tier Strategy**:
| Tier | Name | Cost | Latency | Implementation |
|------|------|------|---------|----------------|
| T1 | Local Explanations | $0 | <1ms | `question.explanation` from Drift |
| T2 | Cached AI | $0 | ~200ms | `gemini-proxy` edge function: prompt-hash → `ai_response_cache` |
| T3 | Live AI | API cost | ~2-3s | `gemini-proxy` calls Gemini Flash, writes to cache |

**Prompt Engineering**: Context-aware system prompt includes batch, chapter, weak topics, days to exam, accuracy, study mode.

---

## 7. Build & Release

### Debug/Profile/Release
```bash
flutter run --debug      # Hot reload, asserts, checked mode
flutter run --profile    # Performance profiling, no asserts
flutter build apk --release --split-per-abi  # Production
```

### CI/CD (GitHub Actions — recommended, not yet committed)
```yaml
# .github/workflows/ci.yml
- flutter analyze
- flutter test --coverage
- genhtml coverage/lcov.info -o coverage/html
- flutter build apk --release
- flutter build web
- upload artifact
```

### Versioning
- `pubspec.yaml`: `version: 1.0.0+1` (semver + build number)
- Android: `versionCode` = build number, `versionName` = semver

---

## 8. Testing Strategy

| Type | Location | Coverage Target |
|------|----------|-----------------|
| Unit | `test/*.dart` | Services, engines, utils ≥ 80% |
| Widget | `test/widget_test.dart` | Critical UI flows |
| Integration | `integration_test/` | Auth → Quiz → Sync → Results |
| Golden | `test/golden/` | Theme, dark mode, key screens |

### Critical Test Scenarios
1. **Exam Engine**: NEET config → allocate → grade → score matches manual calc
2. **DPP Engine**: Generate → persist → reload → same questions (deterministic)
3. **Quiz Engine**: Answer → flag → palette → submit → attempt recorded
4. **Sync**: Offline changes → online → merge (newer `updatedAt` wins)
5. **Auth**: Guest → OTP → 2FA → cloud sync trigger
6. **Dark Mode**: All screens render with proper contrast (AA/AAA)

---

## 9. Performance Budgets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Cold Start | < 1.5s | `flutter run --profile` + DevTools Timeline |
| Home Tab Interactive | < 800ms | `addPostFrameCallback` |
| Quiz Screen Load | < 300ms | 20 questions, shuffled |
| DB Query (1000 Qs) | < 50ms | Drift `explainQueryPlan` |
| Incremental Sync | < 2s | `debugPrint` in `CloudSyncService` |
| AI Proxy (cache hit) | < 200ms | Edge function logs |
| Frame Jank (p90) | < 16ms | `PerformanceOverlay` |

---

## 10. Feature Flags (`AppConfig`)

| Flag | Default | Description |
|------|---------|-------------|
| `enableCloudAuth` | `isCloudAuthConfigured` | Supabase Auth (email/password, Google OAuth) when credentials present |
| `enableCloudSync` | `false` | User data sync (attempts, progress, bookmarks) |
| `enableAiProxy` | `false` | AI tutor via edge function |
| `googleSignInAvailable` | `isCloudAuthConfigured` | Google OAuth button |

---

## 11. Migration Checklist (v25 → v26+)

- [ ] Add `lastSyncedAt` to `dpp_sets` / `dpp_questions` for DPP sync
- [ ] Add `deviceId` to `users` for multi-device conflict detection
- [ ] Migrate `flashcards.box` to full SM-2 fields (already done in v20)
- [ ] Add `questionIds` JSON to `quiz_attempts` for exact replay (v23+)
- [ ] Ensure all new tables have `updatedAt` + unique conflict target

---

## 12. Future Roadmap

| Priority | Feature | Effort |
|----------|---------|--------|
| P0 | Deploy web PWA shell + App Indexing / Universal Links | Medium |
| P0 | Sentry crash reporting + performance monitoring | Low |
| P1 | Parent/Teacher dashboard (read-only progress) | Medium |
| P1 | Offline NCERT PDF search (SQLite FTS5) | Medium |
| P2 | Collaborative study rooms (Supabase Realtime) | High |
| P2 | Adaptive difficulty (IRT-based) | High |
| P3 | Voice notes for explanations | Medium |

---

## 13. Code Quality Gates

```bash
# Pre-commit / CI
flutter analyze --no-fatal-infos
flutter test --coverage
dart format --set-exit-if-changed .
```

**No merge without**: Clean analyze, passing tests, coverage ≥ 70% on engines.

---

*Generated: 2026-08-30 | NEET Mitos v1.0.0+1*