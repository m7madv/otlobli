import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/core/errors/app_failure.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/features/history/data/history_repository.dart';
import 'package:voicebrief/features/subscription/data/subscription_repository.dart';
import 'package:voicebrief/features/subscription/domain/subscription_models.dart';

import 'helpers/test_harness.dart';

void main() {
  test(
    'fake authentication validates credentials and deletes account',
    () async {
      final repository = FakeAuthRepository();
      await expectLater(
        repository.signInWithEmail('bad', 'short'),
        throwsA(isA<AppFailure>()),
      );
      final user = await repository.signInWithEmail(
        'owner@example.com',
        'a-secure-password',
      );
      expect(user.emailVerified, isTrue);
      await repository.deleteAccount();
      expect(repository.currentUser, isNull);
    },
  );

  test('fake subscription supports purchase and restore', () async {
    final repository = FakeSubscriptionRepository();
    final free = await repository.load();
    expect(free.tier, SubscriptionTier.free);
    expect(free.remainingMinutes, 10);
    expect(
      (await repository.purchase('voicebrief_pro_annual')).tier,
      SubscriptionTier.pro,
    );
    expect((await repository.restore()).tier, SubscriptionTier.pro);
  });

  test(
    'memory history remains isolated by account and supports deletion',
    () async {
      final repository = MemoryHistoryRepository();
      final first = repository.watch('first').skip(1).first;
      await Future<void>.delayed(Duration.zero);
      await repository.save('first', sampleResult());
      expect((await first).single.savedLocally, isTrue);
      expect(await repository.watch('second').first, isEmpty);
      await repository.delete('first', sampleResult().id);
      expect(await repository.watch('first').first, isEmpty);
    },
  );
}
