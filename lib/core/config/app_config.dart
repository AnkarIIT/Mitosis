class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isCloudAuthConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  static String get cloudAuthHelpText =>
      'Add SUPABASE_URL and SUPABASE_ANON_KEY as --dart-define values to enable free cloud sign-in. You can still continue as guest.';
}
