import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicebrief/core/storage/app_preferences.dart';
import 'package:voicebrief/features/subscription/domain/subscription_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('theme choice survives a new preferences instance', () async {
    final preferences = await DeviceAppPreferences.load();
    await preferences.setThemeMode(ThemeMode.light);

    final restored = await DeviceAppPreferences.load();

    expect(restored.themeMode, ThemeMode.light);
  });

  test('the last server quota survives an application restart', () async {
    final preferences = await DeviceAppPreferences.load();
    await preferences.cacheSubscription(
      'account-1',
      const SubscriptionStatus(
        tier: SubscriptionTier.pro,
        remainingMinutes: 299,
        totalMinutes: 300,
      ),
    );

    final restored = await DeviceAppPreferences.load();
    final subscription = restored.subscriptionFor('account-1');

    expect(subscription?.tier, SubscriptionTier.pro);
    expect(subscription?.remainingMinutes, 299);
    expect(subscription?.totalMinutes, 300);
    expect(restored.subscriptionFor('another-account'), isNull);
  });
}
