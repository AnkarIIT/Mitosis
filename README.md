# NEET Mitos

A free, offline-first NEET preparation beta for Android and web, built with
Flutter. The current public-safe scope is local study: quizzes, DPPs, CBT
practice, flashcards, review, and NCERT content.

NEET Mitos helps you practice for the NEET-UG exam with Daily Practice Papers (DPPs), topic-wise mock tests, full-length CBT mocks, flashcards, an AI tutor, and a personalized daily study plan across Biology, Chemistry, and Physics.

## Features

- **Offline-first**: quizzes, DPPs, exams, and flashcards work 100% offline using a local Drift (SQLite) database.
- **Full-length NEET mocks**: NTA-compliant 180-question / 180-minute simulation with per-section timing, optional Section-B, and checkpoint/resume.
- **Daily Practice Papers**: difficulty-normalized, weak-topic-biased sampling with deterministic daily seeding.
- **Adaptive quiz engine**: option shuffling, visited/flagged palette, hint system, and short-answer AI evaluation.
- **Spaced repetition**: SM-2 based flashcards and error-book review.
- **AI tutor (experimental)**: local explanations are available where content
  exists; the remote proxy is disabled until its staging deployment and rate
  limits are verified.
- **Cloud sign-in (beta)**: Supabase email/password and Google OAuth are
  configuration-dependent; guest/local study remains the reliable path.
- **Biometric lock**: optional device-biometric app lock with device-credential fallback.

## Getting Started

Prerequisites: [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable, 3.x), Android SDK.

```bash
# Install dependencies
flutter pub get

# Run the app (choose a device)
flutter run

# Run the app on a connected Android phone
flutter run -d <device-id>
```

### Configuration

The Flutter app does **not** load `.env` at runtime. The ignored local file
`.dart-defines.local.json` supplies the public Supabase URL, anon/publishable key,
and Google Web client ID at compile time:

```bash
flutter run --dart-define-from-file=.dart-defines.local.json
```

You can instead pass `SUPABASE_URL`, `SUPABASE_ANON_KEY`, and
`GOOGLE_SERVER_CLIENT_ID` with individual `--dart-define` flags. These client
values are public by design. Never pass a Supabase `service_role` key, Gemini
key, or other server secret into a Flutter build.

Google Sign-In uses `google_sign_in` directly and sends Google's ID token to
Supabase. The Web client ID is supplied as `serverClientId`. This codebase does
not initialize Firebase or apply the Google Services Gradle plugin, so
`google-services.json` is not part of the current sign-in flow; the file is
updated for the registered Firebase Android app for possible future Firebase
use. Its `oauth_client` list is empty because Firebase Auth is not enabled; the
Android and Web OAuth clients are registered directly in Google Cloud.

The Android OAuth client is registered for package `com.neetmitos.app` and the
debug SHA-1. Add the release or Play App Signing SHA-1 before distributing a
release build. Google consent remains in External/Testing mode, so every tester
must be added to Google's test-user list (up to 100 users). Cloud sync and remote
AI remain disabled in this build until their backend contracts are deployed and
tested.

## Builds

```bash
# Debug APK
flutter build apk --debug --dart-define-from-file=.dart-defines.local.json

# Release APK (split by ABI)
flutter build apk --release --split-per-abi --dart-define-from-file=.dart-defines.local.json

# Web PWA shell
flutter build web --dart-define-from-file=.dart-defines.local.json
```

## Testing & Quality

```bash
dart analyze lib test      # application/test sources
flutter test               # 181 tests (unit + widget), all passing
dart format --set-exit-if-changed .
```

## Repository

- GitHub: [AnkarIIT/Mitosis](https://github.com/AnkarIIT/Mitosis)
- Package name: `com.neetmitos.app`

## Release status

This repository is in controlled-beta hardening, not a production launch.
Before public release, complete the account-deletion deployment, native OAuth
configuration, migration upgrade tests, full real-device exam-resume tests,
content QA, and cloud-sync rollout. Do not advertise cross-device sync or
remote AI as generally available until those gates pass.

## License

ISC
