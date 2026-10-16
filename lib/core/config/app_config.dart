import 'package:shared_preferences/shared_preferences.dart';

/// Build-time configuration.
///
/// ## Supplying values — use `--dart-define`, not a bundled `.env`
///
///     flutter build apk --release \
///       --dart-define=SUPABASE_URL=https://xxxx.supabase.co \
///       --dart-define=SUPABASE_ANON_KEY=... \
///       --dart-define=GOOGLE_SERVER_CLIENT_ID=...
///
/// Values arrive via `String.fromEnvironment`, so they are compiled into the
/// Dart program rather than shipped as a separate asset file.
///
/// ## Why `.env` is no longer an asset
///
/// `.env` used to be listed under `assets:` in pubspec.yaml, which copied it
/// verbatim into the APK/IPA bundle. Anything ever written there — including a
/// key added "just for testing" — shipped to every user and was trivially
/// extractable with `unzip app.apk`.
///
/// That is acceptable *only* for values that are public by design. The Supabase
/// project URL, the Supabase **anon** key, and the Google OAuth **web client
/// ID** are public: they are designed to ship in a client and are protected by
/// Row Level Security. They are not secrets.
///
/// The following must NEVER reach this file, `.env`, or `--dart-define`, because
/// a mobile or web client cannot keep an embedded value confidential:
///   * Supabase **service_role** key
///   * Gemini API key
///   * SMTP / email-provider credentials
///   * Any admin token
///
/// Those belong in `supabase secrets set`, and are read only inside Edge
/// Functions.
class AppConfig {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get sharedPreferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ── Supabase ──────────────────────────────────────────────────────────────

  /// Public project URL. Safe to ship.
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');

  /// Publishable/anon key. Safe to ship — RLS is the access control.
  ///
  /// ⚠️ Do NOT pass the service_role key here. It bypasses RLS entirely, and
  /// anything embedded in a shipped client is public.
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  /// Public OAuth **web** client ID. An Android client ID does not work here:
  /// the native SDK needs the server/web client for the ID-token exchange.
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  static bool get isCloudAuthConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static String get cloudAuthHelpText => isCloudAuthConfigured
      ? 'Cloud sign-in is configured for this build.'
      : 'This build has no cloud credentials compiled in, so it runs fully '
            'offline with local sign-in and guest mode. Rebuild with '
            '--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... '
            'to enable cloud sign-in.';

  // ── Feature gates ─────────────────────────────────────────────────────────

  /// Cloud auth auto-enables when credentials are compiled in.
  static bool get enableCloudAuth => isCloudAuthConfigured;

  /// Two-factor toggle. Supabase local sign-in handles its own 2FA; this gate
  /// exists so the feature can be pinned off per environment.
  static bool get enableTwoFactor =>
      const bool.fromEnvironment('ENABLE_TWO_FACTOR', defaultValue: true);

  /// ⚠️ Content sync is intentionally OFF for release builds.
  ///
  /// The catalog path had never been exercised against a real Supabase project,
  /// and the delta-cursor / soft-delete / option-decoding defects it carried
  /// (see ContentSyncService) meant an enable would have produced an ungradable
  /// question bank. Flip only after the staging sync matrix passes.
  static const bool enableCloudSync = bool.fromEnvironment(
    'ENABLE_CLOUD_SYNC',
    defaultValue: false,
  );

  /// ⚠️ AI proxy is intentionally OFF for release builds.
  ///
  /// The proxy spends a shared Gemini key on behalf of callers, so it needs the
  /// rate-limit and origin-allowlist configuration verified in staging first.
  static const bool enableAiProxy = bool.fromEnvironment(
    'ENABLE_AI_PROXY',
    defaultValue: false,
  );

  // ── Google sign-in ────────────────────────────────────────────────────────

  static bool get googleSignInAvailable =>
      isCloudAuthConfigured &&
      supabaseUrl.trim().isNotEmpty &&
      googleServerClientId.trim().isNotEmpty;
}
