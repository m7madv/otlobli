import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/app/config/app_config.dart';

void main() {
  const production = AppConfig(
    environment: 'production',
    useMocks: false,
    supabaseUrl: 'https://jyehqpdbayslhzebdycj.supabase.co',
    supabaseAnonKey: 'public-key',
    revenueCatIosKey: 'ios-public-key',
    revenueCatAndroidKey: 'android-public-key',
    googleIosClientId: 'ios-client-id',
    googleWebClientId: 'web-client-id',
    appleServiceId: '',
    appleRedirectUri: '',
  );

  test('release configuration accepts only the VoiceBrief backend', () {
    expect(production.releaseReadyFor(isIOS: true), isTrue);
    expect(production.releaseReadyFor(isIOS: false), isTrue);

    final wrongBackend = AppConfig(
      environment: production.environment,
      useMocks: production.useMocks,
      supabaseUrl: 'https://exxayzlklvgeyqhvtzgi.supabase.co',
      supabaseAnonKey: production.supabaseAnonKey,
      revenueCatIosKey: production.revenueCatIosKey,
      revenueCatAndroidKey: production.revenueCatAndroidKey,
      googleIosClientId: production.googleIosClientId,
      googleWebClientId: production.googleWebClientId,
      appleServiceId: production.appleServiceId,
      appleRedirectUri: production.appleRedirectUri,
    );
    expect(wrongBackend.releaseReadyFor(isIOS: true), isFalse);
  });

  test('release configuration rejects mocks and missing platform keys', () {
    const mockConfig = AppConfig(
      environment: 'production',
      useMocks: true,
      supabaseUrl: 'https://jyehqpdbayslhzebdycj.supabase.co',
      supabaseAnonKey: 'public-key',
      revenueCatIosKey: '',
      revenueCatAndroidKey: '',
      googleIosClientId: '',
      googleWebClientId: '',
      appleServiceId: '',
      appleRedirectUri: '',
    );
    expect(mockConfig.releaseReadyFor(isIOS: true), isFalse);
    expect(mockConfig.releaseReadyFor(isIOS: false), isFalse);
  });
}
