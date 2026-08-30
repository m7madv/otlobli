import 'package:flutter/foundation.dart';

/// Public, build-time configuration for the mobile client.
///
/// Private server credentials such as `OPENAI_API_KEY`, the Supabase service
/// role key, and webhook secrets must never be added here.
@immutable
class AppConfig {
  const AppConfig({
    required this.environment,
    required this.useMocks,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.revenueCatIosKey,
    required this.revenueCatAndroidKey,
    required this.googleIosClientId,
    required this.googleWebClientId,
    required this.appleServiceId,
    required this.appleRedirectUri,
  });

  factory AppConfig.fromEnvironment() {
    return const AppConfig(
      environment: String.fromEnvironment(
        'APP_ENV',
        defaultValue: 'development',
      ),
      useMocks: bool.fromEnvironment('USE_MOCK_SERVICES', defaultValue: true),
      supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
      supabaseAnonKey: String.fromEnvironment('SUPABASE_ANON_KEY'),
      revenueCatIosKey: String.fromEnvironment('REVENUECAT_IOS_PUBLIC_SDK_KEY'),
      revenueCatAndroidKey: String.fromEnvironment(
        'REVENUECAT_ANDROID_PUBLIC_SDK_KEY',
      ),
      googleIosClientId: String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      googleWebClientId: String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      appleServiceId: String.fromEnvironment('APPLE_SERVICE_ID'),
      appleRedirectUri: String.fromEnvironment('APPLE_REDIRECT_URI'),
    );
  }

  final String environment;
  final bool useMocks;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String revenueCatIosKey;
  final String revenueCatAndroidKey;
  final String googleIosClientId;
  final String googleWebClientId;
  final String appleServiceId;
  final String appleRedirectUri;

  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  bool releaseReadyFor({required bool isIOS}) {
    final uri = Uri.tryParse(supabaseUrl);
    final correctBackend =
        uri?.scheme == 'https' &&
        uri?.host == '${AppIdentity.supabaseProjectRef}.supabase.co';
    final revenueCatKey = isIOS ? revenueCatIosKey : revenueCatAndroidKey;
    return environment == 'production' &&
        !useMocks &&
        hasSupabase &&
        correctBackend &&
        revenueCatKey.isNotEmpty &&
        googleWebClientId.isNotEmpty &&
        (!isIOS || googleIosClientId.isNotEmpty);
  }
}

abstract final class AppIdentity {
  static const name = 'VoiceBrief';
  static const subtitle = 'Voice messages, made clear';
  static const androidApplicationId = 'app.voicebrief.mobile';
  static const iosBundleId = 'app.voicebrief.mobile';
  static const urlScheme = 'voicebrief';
  static const iosAppGroup = 'group.app.voicebrief.mobile';
  static const supabaseProjectRef = 'jyehqpdbayslhzebdycj';
  static const termsUrl = 'https://voicebrief-legal.vercel.app/terms';
  static const privacyUrl = 'https://voicebrief-legal.vercel.app/privacy';
  static const supportUrl = 'https://voicebrief-legal.vercel.app/support';
}

abstract final class ProductIds {
  static const monthly = 'voicebrief_pro_monthly';
  static const annual = 'voicebrief_pro_annual';
  static const entitlement = 'pro';
  static const offering = 'default';
}
