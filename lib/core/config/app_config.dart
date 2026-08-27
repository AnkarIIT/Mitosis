import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String? get _env(String key) => dotenv.env[key];

  static String get supabaseUrl =>
      _env('SUPABASE_URL') ??
      const String.fromEnvironment('SUPABASE_URL', defaultValue: '');

  static String get supabaseAnonKey =>
      _env('SUPABASE_ANON_KEY') ??
      const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static bool get isCloudAuthConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static String get cloudAuthHelpText =>
      'Set SUPABASE_URL and SUPABASE_ANON_KEY in .env to enable free cloud sign-in. You can still continue as guest.';

  // ---------------------------------------------------------------------------
  // Local-first flags: cloud features are OPTIONAL.
  // enableCloudAuth auto-enables when credentials are present in .env or dart-define.
  // ---------------------------------------------------------------------------
  static bool get enableCloudAuth => isCloudAuthConfigured;
  static const bool enableCloudSync = false;
  static const bool enableAiProxy = false;
}

