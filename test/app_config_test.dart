import 'package:flutter_test/flutter_test.dart';
import 'package:neet_mitos/core/config/app_config.dart';

/// Configuration now arrives at BUILD time via `--dart-define` instead of from a
/// bundled `.env` asset.
///
/// These tests pin the *invariants* that matter for a release build rather than
/// any particular environment's values.
void main() {
  group('AppConfig build-time injection', () {
    test('all config values resolve without throwing', () {
      expect(AppConfig.supabaseUrl, isA<String>());
      expect(AppConfig.supabaseAnonKey, isA<String>());
      expect(AppConfig.googleServerClientId, isA<String>());
    });

    test('cloud auth is off when no credentials are compiled in', () {
      // The test suite never passes --dart-define, so this must be false.
      // It is what keeps CI from accidentally exercising a real project.
      expect(AppConfig.isCloudAuthConfigured, isFalse);
      expect(AppConfig.enableCloudAuth, isFalse);
      expect(AppConfig.googleSignInAvailable, isFalse);
    });

    test('a partial configuration does not enable cloud auth', () {
      // Both halves are required. A URL without a key (or vice versa) must not
      // flip the gate, or the app would attempt a call it cannot authorise.
      expect(
        AppConfig.isCloudAuthConfigured,
        AppConfig.supabaseUrl.trim().isNotEmpty &&
            AppConfig.supabaseAnonKey.trim().isNotEmpty,
      );
    });

    test('a supplied Supabase URL is well-formed', () {
      final url = AppConfig.supabaseUrl;
      expect(url.isEmpty || Uri.tryParse(url) != null, isTrue);
    });
  });

  group('Feature gates default to safe', () {
    test('cloud sync is off unless explicitly enabled at build time', () {
      // ⚠️ The catalog sync path had never run against a real project; enabling
      // it by default would ship a broken question bank. Default must stay off.
      expect(AppConfig.enableCloudSync, isFalse);
    });

    test('the AI proxy is off unless explicitly enabled at build time', () {
      // The proxy spends a shared Gemini key on callers' behalf, so it must be
      // an explicit opt-in after staging verification.
      expect(AppConfig.enableAiProxy, isFalse);
    });

    test('two-factor defaults to enabled', () {
      expect(AppConfig.enableTwoFactor, isTrue);
    });
  });

  group('Help text', () {
    test('explains the rebuild path when cloud auth is unavailable', () {
      final text = AppConfig.cloudAuthHelpText;
      // Must be actionable: name the flags, not just state the failure.
      if (!AppConfig.isCloudAuthConfigured) {
        expect(text, contains('--dart-define'));
      }
    });

    test('never instructs the user to put a secret in the client', () {
      final text = AppConfig.cloudAuthHelpText.toLowerCase();
      for (final forbidden in ['service_role', 'service role key', 'api key']) {
        expect(text.contains(forbidden), isFalse);
      }
    });
  });
}
