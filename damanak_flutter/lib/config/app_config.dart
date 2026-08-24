abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('DAMANAK_SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment(
    'DAMANAK_SUPABASE_PUBLISHABLE_KEY',
  );

  static bool get hasCloudBackend =>
      supabaseUrl.trim().isNotEmpty && supabaseKey.trim().isNotEmpty;
}
