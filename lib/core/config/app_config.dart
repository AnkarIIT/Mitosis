import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get sharedPreferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static String? _env(String key) {
    try {
      return dotenv.env[key];
    } on Object {
      return null;
    }
  }

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

  // Cloud features remain optional. Auth auto-enables when credentials are
  // present in .env or supplied via dart-define.
  static bool get enableCloudAuth => isCloudAuthConfigured;
  static const bool enableCloudSync = false;
  static const bool enableAiProxy = false;

  static bool get googleSignInAvailable =>
      isCloudAuthConfigured && supabaseUrl.trim().isNotEmpty;

  static String? get googleServerClientId => _env('GOOGLE_SERVER_CLIENT_ID');
}
