abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('DAMANAK_SUPABASE_URL');
  static const supabaseKey = String.fromEnvironment(
    'DAMANAK_SUPABASE_PUBLISHABLE_KEY',
  );
  static const googleWebClientId = String.fromEnvironment(
    'DAMANAK_GOOGLE_WEB_CLIENT_ID',
    defaultValue:
        '521030062021-2k3ou0f5jcmn2afr4jrcu8bki4t7sgk6.apps.googleusercontent.com',
  );
  static const googleIosClientId = String.fromEnvironment(
    'DAMANAK_GOOGLE_IOS_CLIENT_ID',
    defaultValue:
        '521030062021-lupo3mel3si0nmu9tijcblo13d4sqg4d.apps.googleusercontent.com',
  );

  static bool get hasCloudBackend =>
      supabaseUrl.trim().isNotEmpty && supabaseKey.trim().isNotEmpty;
}
