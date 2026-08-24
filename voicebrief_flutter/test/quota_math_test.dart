import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/app/app_state.dart';
import 'package:voicebrief/core/utils/quota_math.dart';

void main() {
  test('new app state starts with all 10 free minutes', () {
    const state = AppState();
    expect(state.subscription.remainingMinutes, 10);
    expect(state.subscription.totalMinutes, 10);
  });

  group('quota math', () {
    test('rounds any partial minute up', () {
      expect(billedMinutesForDuration(const Duration(seconds: 1)), 1);
      expect(billedMinutesForDuration(const Duration(seconds: 60)), 1);
      expect(billedMinutesForDuration(const Duration(seconds: 61)), 2);
      expect(billedMinutesForDuration(Duration.zero), 0);
    });

    test('calculates the documented annual saving', () {
      expect(annualSaving(monthlyPrice: 29, annualPrice: 229), 119);
      expect(annualSavingPercent(monthlyPrice: 29, annualPrice: 229), 34);
    });
  });
}
