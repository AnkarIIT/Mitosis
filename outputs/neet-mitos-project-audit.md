# NEET Mitos — Project Folder Audit

**Date:** 2025-01-27  
**Scope:** Flutter mobile app codebase (`lib/`, `android/`, `pubspec.yaml`, `.env`)  
**Auditor:** Feynman  

---

## 1. Executive Summary

NEET Mitos is a local-first Flutter app for NEET exam preparation with optional Supabase cloud sync, Google Sign-In, spaced repetition, CBT mock tests, DPP generation, and an AI chatbot. The architecture is mature for a solo/small-team project: Riverpod state management, Drift SQLite, GoRouter, and a phased enhancement roadmap.

However, the current state has **critical security gaps**, **ASO metadata inconsistencies**, **design token fragmentation**, and **startup-performance risks** that should be addressed before a public Play Store release.

---

## 2. Security Audit

### 2.1 Critical — Secrets Bundled into APK

| Finding | Evidence | Risk |
|---------|----------|------|
| `.env` is listed as a Flutter asset in `pubspec.yaml` | `assets: - .env` | **HIGH** — `.env` is packaged into the APK and can be extracted with `unzip`. |
| Supabase anon key is present in `.env` | `SUPABASE_ANON_KEY=sb_publishable_...` | **HIGH** — Anyone can inspect the APK and read the key. |
| Google Server Client ID is present in `.env` | `GOOGLE_SERVER_CLIENT_ID=...` | **MEDIUM** — Client ID is semi-public by design, but bundling it with other secrets amplifies exposure. |

**Observation vs Inference:**  
- `.env` is gitignored (`.gitignore` includes `/.env`), so it will not leak via source control.  
- However, `pubspec.yaml` explicitly bundles `.env` into the app binary. This is a reproducible extraction risk.

**Fix:** Remove `.env` from `pubspec.yaml` assets. Use `--dart-define` for build-time config, or load secrets from a secure backend at runtime.

---

### 2.2 High — Client-Side Cloud Auth Without Backend

| Finding | Evidence | Risk |
|---------|----------|------|
| Supabase client initialized directly in the Flutter app | `Supabase.initialize(url: ..., publishableKey: ...)` in `main.dart` | **HIGH** — Anon key is public by design, but RLS policies are the only security layer. If RLS is misconfigured, data is exposed. |
| Cloud sync pushes local user data to Supabase | `CloudSyncService._pushAttempt`, `_pushProgress`, `_pushBookmark` | **MEDIUM** — All writes rely on `_userId` derived from `supabase.auth.currentUser?.id`. If the JWT is stolen, the attacker inherits the user’s sync context. |
| No certificate pinning for Supabase/Resend | Direct `http.post` and `Supabase.client.functions.invoke` calls | **MEDIUM** — MITM risk on untrusted networks. |

**Observation:** The code correctly uses `user_id = auth.currentUser.id` rather than trusting client-provided IDs. That is the correct Supabase pattern.

**Fix:** Add `network_security_config.xml` with certificate pinning for production domains. Consider a lightweight backend proxy for sensitive email/OTP flows.

---

### 2.3 Medium — Auth Flow Weaknesses

| Finding | Evidence | Risk |
|---------|----------|------|
| 2FA OTP stored in `FlutterSecureStorage` with 10-min expiry | `_secure2FACodeKey`, `_otpLifetime` | **LOW-MEDIUM** — SecureStorage is device-encrypted, but OTP is static for 10 minutes and has no rate limit. |
| Google Sign-In error 12500 exposes debug SHA-1 in user-facing message | `google_auth_service.dart` catch block | **LOW** — Debug SHA-1 is not a production secret, but exposing it in production error messages leaks build metadata. |
| Guest mode bypasses all auth checks | `continueAsGuest()` sets `isGuest: true` | **LOW** — Expected for local-first, but guest users lose cloud backup entirely. |
| Password reset flows directly through Supabase | `resetPasswordForEmail` | **LOW** — Standard pattern, but no CAPTCHA or rate-limit feedback. |

**Observation:** The auth state machine (`AuthStatus`) is well-structured with explicit transitions for OTP, 2FA, guest, and authenticated states.

---

### 2.4 Medium — Data Storage & Privacy

| Finding | Evidence | Risk |
|---------|----------|------|
| Chat history stored locally without encryption | `insertChatMessage` in `drift_database.dart` | **MEDIUM** — Device theft or forensic extraction can read chat history. |
| Gemini API key stored in `FlutterSecureStorage` via Settings screen | `geminiServiceProvider.saveApiKey` | **LOW** — SecureStorage is appropriate, but the key is sent directly to Google from the client. |
| User progress, error book, and bookmarks stored in plain SQLite | Drift tables with no encryption | **MEDIUM** — Rooted device or backup extraction can read all progress data. |
| `deleteAccount` only clears local DB + Supabase sign-out | `_db.clearAllProgress()` | **LOW** — No cascade delete of remote rows via Supabase admin API; orphaned rows may remain in the cloud. |

**Observation:** The app explicitly states in `settings_screen.dart` privacy policy: *“We do not collect, sell, or share any personal data.”* This claim is broadly accurate for the local-only path, but cloud-enabled paths do transmit email, OTPs, and sync data to Supabase/Resend.

---

### 2.5 Low — Android Manifest & Permissions

| Finding | Evidence | Risk |
|---------|----------|------|
| Only `INTERNET` and `ACCESS_NETWORK_STATE` declared | `AndroidManifest.xml` | **LOW** — Minimal permissions is good. |
| No `network_security_config.xml` | File missing at `res/xml/` | **LOW** — Default cleartext and certificate behavior applies. |
| `android:taskAffinity=""` on MainActivity | `AndroidManifest.xml` | **LOW** — Unusual but not directly a vulnerability; affects task stacking. |
| No ProGuard/R8 rules visible for release | `build.gradle.kts` only shows debug signing fallback | **LOW** — Release builds may expose Dart symbols. |

---

## 3. ASO & Metadata Audit

### 3.1 App Title & Branding Inconsistencies

| Property | Current Value | Issue |
|----------|---------------|-------|
| `MaterialApp.title` | `NEET Mitos Free` | Generic; “Free” is a suffix that limits premium branding later. |
| Android `android:label` | `Mitosis` | **MISMATCH** — Brand name is “Mitosis” on Play Store but the app calls itself “NEET Mitos” everywhere in UI. |
| App bar titles | `NEET Mitos`, `NEET Mitos Free` | Inconsistent across screens. |
| `pubspec.yaml` description | `AI-Powered NEET Preparation App` | Acceptable but does not include primary keywords like “mock test”, “DPP”, “previous year questions”. |

**Fix:** Unify branding to `NEET Mitos` everywhere. Change Android label to match. Update Play Store listing to include NEET-specific keywords.

---

### 3.2 Package Name

Current: `com.neetmitosis.app`  
Issue: Contains “mitosis” (biology pun) but not the searchable keyword “neet” or “mitos”. Play Store package names are permanent and lightly weighted in search.

**Recommendation:** If the app has not been published, consider `com.neetmitos.app` or `com.mitosneet.app` for keyword relevance.

---

### 3.3 Keyword Presence

| Keyword | Present in metadata? | Notes |
|---------|----------------------|-------|
| NEET | Yes (title, description) | Strong |
| Mock Test | Partial | Present in UI but not in `pubspec.yaml` description |
| DPP / Daily Practice | No | Missing from all metadata |
| Previous Year Questions / PYQ | No | Missing |
| CBT | No | Missing |

**Observation:** Education apps on Play Store benefit from long-tail keywords in the short and long descriptions. The current metadata is brand-centric but not keyword-optimized.

---

### 3.4 Visual Assets

No screenshots, feature graphics, or app icon variants were audited here, but the Android project references `@mipmap/ic_launcher` only. For Play Store, you need:
- 512×512 icon
- Feature graphic (1024×500)
- 5–8 phone screenshots (1080×1920 minimum)
- Tablet screenshots optional but helpful

---

## 4. Design & UX Analysis

### 4.1 Component Architecture

**Strengths:**
- Consistent theming via `AppColors`, `AdaptiveColors`, and design tokens.
- Reusable cards: `_buildSettingsCard`, subject cards, DPP banner.
- Animation orchestration with `flutter_animate` applied systematically.

**Weaknesses:**
- `home_tab.dart` is a single 1,397-line file with nested private widget classes. This is a maintenance liability.
- `settings_screen.dart` similarly mixes business logic (`_downloadPyqs`, `_showDeleteAccountConfirmation`) with UI.

**Fix:** Extract `_buildDppBanner`, `_buildResumeMockCard`, and search delegate into separate files.

---

### 4.2 Loading & Empty States

| Screen | Skeleton Loader | Empty State | Error State |
|--------|-----------------|-------------|-------------|
| Home | ✅ Shimmer skeleton | ✅ “Start a quiz...” card | ❌ No generic error retry |
| Settings | ❌ None | ❌ None | ✅ SnackBar feedback |
| Chatbot | ❌ None | ✅ Suggested prompts | ✅ Error bubbles |

**Observation:** The home tab has excellent skeleton loading, but screens like Settings and Chatbot lack skeleton loaders for async operations.

---

### 4.3 Accessibility

| Check | Status |
|-------|--------|
| Semantic icons + text labels | ✅ Mostly present |
| Touch target size (48×48 dp) | ⚠️ Some `IconButton` padding constraints are tight |
| Contrast ratios | ❌ Not verified; `AppColors` lacks documented contrast ratios |
| Screen reader support | ⚠️ No `Semantics` widgets observed in sampled screens |
| Dynamic type scaling | ❌ No `MediaQuery.textScaleFactor` handling observed |

---

### 4.4 Responsive Behavior

- `home_tab.dart` adjusts card height based on `screenHeight < 600`.
- No tablet/large-screen layout adaptations observed.
- No landscape orientation handling for CBT/DPP screens (important for mock tests).

**Fix:** Add `OrientationBuilder` or `LayoutBuilder` breakpoints for tablets. Lock portrait for CBT/DPP attempt screens to prevent accidental rotation during timed tests.

---

## 5. Performance Audit

### 5.1 Startup Path

```text
main()
├── dotenv.load()                     ← blocks startup
├── Supabase.initialize()             ← network call, blocks if unreachable
├── NotificationService.init()        ← 5s timeout (good)
├── SharedPreferences.getInstance()   ← blocks startup
├── ProviderContainer()               ← creates entire graph
└── _backgroundInit()                 ← runs after runApp
    ├── importBundledQuestions()      ← disk I/O
    ├── insertSampleQuestions()       ← DB writes
    └── contentSyncService.syncCatalog() ← network, OFF by default
```

**Issues:**
1. `dotenv.load()` and `Supabase.initialize()` run synchronously before `runApp`. On a slow network, this delays splash screen disappearance.
2. `ProviderContainer()` is created manually instead of using `ProviderScope` widget tree. This is valid but makes hot-reload less reliable.
3. `_backgroundInit` is fire-and-forget after `runApp`. If it throws, the error is logged but the user never knows seeding failed.

**Metrics:**
- No startup-time instrumentation observed.
- No `flutter run --profile` traces available.

**Fix:** Move Supabase init into a splash-screen future with a timeout. Show an error state if init fails rather than hanging.

---

### 5.2 Memory & Timer Leaks

| Service | Status |
|---------|--------|
| `ConnectivityService` | ✅ `_statusSubscription` cancelled in `dispose()` |
| `NotificationService` | ✅ Singleton, no stream |
| `BiometricService` | ✅ Wraps `LocalAuthentication` |
| `AnimationController` in `HomeTab` | ✅ Disposed |
| `TextEditingController`s | ✅ Mostly disposed in screens |

**Observation:** No obvious memory leaks in sampled screens. Timer leaks were previously fixed per the conversation summary.

---

### 5.3 Bundle Size Risks

| Asset/Dependency | Risk |
|------------------|------|
| `.env` bundled as asset | **+1–2 KB** (small but contains secrets) |
| `assets/questions/` | Unknown size; sample questions are bundled |
| `syncfusion_flutter_pdf` | **Large** — proprietary PDF SDK adds ~10–20 MB |
| `google_generative_ai` + `groq` + `tflite_flutter` | **Medium** — multiple AI SDKs increase method count and dex size |
| `flutter_animate` | **Low** — code-based animations, no native libs |
| `flutter_local_notifications` | **Medium** — native Android/iOS notification libs |

**Observation:** The app is currently 98 MB release / 31 MB debug per prior notes. The large size is driven by PDF and AI SDKs.

---

## 6. Other Findings

### 6.1 Local-First Compliance

The `outputs/.plans/local-first-app-plan.md` outlines an aggressive local-first migration. Current state:
- ✅ Core quiz, flashcards, CBT, DPP work offline.
- ✅ `enableCloudSync` is `false` by default.
- ❌ `Supabase.initialize()` still runs on every cold start even when cloud is unused.
- ❌ `GeminiProxyService` requires `enableAiProxy = false` currently, but `chatbot_screen.dart` still calls it directly, making the AI feature a dead end unless manually toggled.

**Fix:** Guard `Supabase.initialize()` with `if (AppConfig.enableCloudAuth)`. Make chatbot gracefully degrade to offline hints when AI is disabled.

---

### 6.2 Code Quality & Compilation

- ✅ `flutter analyze` reports 0 errors.
- ✅ `flutter test` reports 147 passed.
- ✅ Schema version is 25 with incremental migrations.
- ⚠️ Some files exceed 1,000 lines (`home_tab.dart`, `settings_screen.dart`, `drift_database.dart`).
- ⚠️ Mixed import styles: some files use `import 'x' hide y`, others use prefixes.

---

### 6.3 Web / SEO Presence

No web assets, landing page, or `web/` folder were found. For a mobile-only app:
- **Traditional SEO** is not applicable unless a marketing site is built.
- **App indexing** on Play Store is the primary discovery channel.
- **Deep linking** is handled via GoRouter but no `app_links` / `firebase_dynamic_links` configuration was observed.

**Recommendation:** If web presence is desired, add a minimal landing page with structured data (`SoftwareApplication` schema) and Play Store / App Store badges.

---

## 7. Prioritized Remediation Roadmap

| Priority | Item | Owner | Effort |
|----------|------|-------|--------|
| P0 | Remove `.env` from `pubspec.yaml` assets | Dev | 5 min |
| P0 | Add `network_security_config.xml` with production pinning | Dev | 30 min |
| P0 | Unify app branding: `Mitosis` → `NEET Mitos` | Dev/Design | 15 min |
| P1 | Move Supabase init off critical startup path | Dev | 1 hour |
| P1 | Add skeleton loaders to Settings/Chatbot screens | Dev | 1 hour |
| P1 | Lock CBT/DPP attempts to portrait orientation | Dev | 15 min |
| P1 | Optimize Play Store metadata with NEET keywords | Marketing | 1 hour |
| P2 | Extract `home_tab.dart` into smaller widgets | Dev | 2 hours |
| P2 | Add contrast-ratio validation to `AppColors` | Dev/Design | 30 min |
| P2 | Add `Semantics` widgets for TalkBack/VoiceOver | Dev | 2 hours |
| P3 | Build marketing landing page with structured data | Marketing | 4 hours |

---

## 8. Sources

- SnapMonk. *Google Play ASO for Education Apps — Play Store Keyword Guide*. https://snapmonk.com/aso-google-play/education-apps
- vmobify. *Google Play Algorithm 2026 — Ranking Factors*. https://vmobify.com/blog/google-play-algorithm-2026/
- AppVector Blog. *App Store Optimization (ASO) Guide for Education Apps on Google Play Store*. https://blog.appvector.io/app-store-optimization-aso-guide-for-education-apps-on-google-play-store/
- ASOMobile. *How to optimize app metadata for Google Play*. https://asomobile.net/en/blog/how-to-optimize-app-metadata-for-google-play/
- Flutter. *Security best practices for Flutter apps*. https://docs.flutter.dev/security
- Supabase. *Row Level Security (RLS)*. https://supabase.com/docs/guides/auth/row-level-security
