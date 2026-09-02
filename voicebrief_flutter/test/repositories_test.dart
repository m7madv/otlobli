import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:voicebrief/core/errors/app_failure.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/features/history/data/history_repository.dart';
import 'package:voicebrief/features/subscription/data/subscription_repository.dart';
import 'package:voicebrief/features/subscription/domain/subscription_models.dart';

import 'helpers/test_harness.dart';

void main() {
  test('Supabase auth errors preserve provider availability', () {
    expect(
      mapSupabaseAuthFailure(
        const AuthException(
          'Provider is not enabled',
          code: 'provider_disabled',
          statusCode: '400',
        ),
      ).code,
      AppFailureCode.identityProviderUnavailable,
    );
  });

  test('fake provider authentication signs in and deletes account', () async {
    final repository = FakeAuthRepository();
    final user = await repository.signInWithProvider(IdentityProvider.google);
    expect(user, isNotNull);
    expect(user.emailVerified, isTrue);
    await repository.deleteAccount();
    expect(repository.currentUser, isNull);
  });

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

  test('subscription sync waits until the webhook exposes Pro usage', () async {
    var reads = 0;
    final waits = <Duration>[];
    final status = await synchronizeSubscriptionStatus(
      storeStatus: _subscriptionStatus(SubscriptionTier.pro),
      retryDelays: const [
        Duration.zero,
        Duration(milliseconds: 10),
        Duration(milliseconds: 20),
      ],
      wait: (duration) async => waits.add(duration),
      loadServerStatus: (storeStatus) async {
        reads += 1;
        return _subscriptionStatus(
          reads < 3 ? SubscriptionTier.free : SubscriptionTier.pro,
        );
      },
    );

    expect(status.tier, SubscriptionTier.pro);
    expect(reads, 3);
    expect(waits, const [
      Duration(milliseconds: 10),
      Duration(milliseconds: 20),
    ]);
  });

  test(
    'successful server reconciliation runs before first status read',
    () async {
      var recovered = false;
      var reads = 0;
      final status = await synchronizeSubscriptionStatus(
        storeStatus: _subscriptionStatus(SubscriptionTier.pro),
        retryDelays: const [Duration.zero],
        requestServerSync: () async => recovered = true,
        loadServerStatus: (_) async {
          reads += 1;
          return _subscriptionStatus(
            recovered ? SubscriptionTier.pro : SubscriptionTier.free,
          );
        },
      );

      expect(status.tier, SubscriptionTier.pro);
      expect(reads, 1);
    },
  );

  test(
    'reconciliation uses 0/1s/3s retries without an extra success wait',
    () async {
      var syncAttempts = 0;
      final waits = <Duration>[];
      final status = await synchronizeSubscriptionStatus(
        storeStatus: _subscriptionStatus(SubscriptionTier.pro),
        retryDelays: const [Duration.zero],
        requestRetryDelays: subscriptionSyncRequestRetryDelays,
        wait: (duration) async => waits.add(duration),
        requestServerSync: () async {
          syncAttempts += 1;
          if (syncAttempts < 2) {
            throw const AppFailure(AppFailureCode.subscriptionUnavailable);
          }
        },
        loadServerStatus: (_) async =>
            _subscriptionStatus(SubscriptionTier.pro),
      );

      expect(status.tier, SubscriptionTier.pro);
      expect(syncAttempts, 2);
      expect(waits, const [Duration(seconds: 1)]);
    },
  );

  test(
    'subscription sync never returns a stale Free result after purchase',
    () async {
      await expectLater(
        synchronizeSubscriptionStatus(
          storeStatus: _subscriptionStatus(SubscriptionTier.pro),
          retryDelays: const [Duration.zero, Duration(milliseconds: 1)],
          wait: (_) async {},
          loadServerStatus: (_) async =>
              _subscriptionStatus(SubscriptionTier.free),
        ),
        throwsA(
          isA<AppFailure>().having(
            (failure) => failure.code,
            'code',
            AppFailureCode.subscriptionSyncPending,
          ),
        ),
      );
    },
  );

  test('subscription sync reads a Free account only once', () async {
    var reads = 0;
    final status = await synchronizeSubscriptionStatus(
      storeStatus: _subscriptionStatus(SubscriptionTier.free),
      retryDelays: const [
        Duration.zero,
        Duration(seconds: 1),
        Duration(seconds: 2),
      ],
      wait: (_) async => fail('Free status must not wait for a webhook.'),
      loadServerStatus: (_) async {
        reads += 1;
        return _subscriptionStatus(SubscriptionTier.free);
      },
    );

    expect(status.tier, SubscriptionTier.free);
    expect(reads, 1);
  });

  test('Free restore syncs first and returns the server Free state', () async {
    var syncRequested = false;
    var reads = 0;
    final status = await synchronizeSubscriptionStatus(
      storeStatus: _subscriptionStatus(SubscriptionTier.free),
      retryDelays: const [Duration.zero],
      requestServerSync: () async => syncRequested = true,
      loadServerStatus: (_) async {
        expect(syncRequested, isTrue);
        reads += 1;
        return _subscriptionStatus(SubscriptionTier.free);
      },
    );

    expect(status.tier, SubscriptionTier.free);
    expect(reads, 1);
  });

  test('failed Free restore sync never trusts stale server Pro', () async {
    await expectLater(
      synchronizeSubscriptionStatus(
        storeStatus: _subscriptionStatus(SubscriptionTier.free),
        retryDelays: const [Duration.zero],
        requestRetryDelays: const [Duration.zero],
        requestServerSync: () async =>
            throw const AppFailure(AppFailureCode.subscriptionUnavailable),
        loadServerStatus: (_) async =>
            _subscriptionStatus(SubscriptionTier.pro),
      ),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          AppFailureCode.subscriptionSyncPending,
        ),
      ),
    );
  });

  test('failed Pro sync never accepts an older server Pro period', () async {
    var syncAttempts = 0;
    var reads = 0;
    await expectLater(
      synchronizeSubscriptionStatus(
        storeStatus: _subscriptionStatus(SubscriptionTier.pro),
        retryDelays: const [Duration.zero, Duration(milliseconds: 1)],
        requestRetryDelays: const [Duration.zero, Duration(milliseconds: 1)],
        wait: (_) async {},
        requestServerSync: () async {
          syncAttempts += 1;
          throw const AppFailure(AppFailureCode.subscriptionUnavailable);
        },
        loadServerStatus: (_) async {
          reads += 1;
          return _subscriptionStatus(SubscriptionTier.pro);
        },
      ),
      throwsA(
        isA<AppFailure>().having(
          (failure) => failure.code,
          'code',
          AppFailureCode.subscriptionSyncPending,
        ),
      ),
    );

    expect(syncAttempts, 2);
    expect(reads, 0);
  });

  test(
    'server reconciliation retries are capped below the rate limit',
    () async {
      var syncAttempts = 0;
      await expectLater(
        synchronizeSubscriptionStatus(
          storeStatus: _subscriptionStatus(SubscriptionTier.pro),
          retryDelays: const [Duration.zero],
          requestRetryDelays: List<Duration>.filled(8, Duration.zero),
          requestServerSync: () async {
            syncAttempts += 1;
            throw const AppFailure(AppFailureCode.subscriptionUnavailable);
          },
          loadServerStatus: (_) async =>
              _subscriptionStatus(SubscriptionTier.pro),
        ),
        throwsA(isA<AppFailure>()),
      );

      expect(syncAttempts, maxSubscriptionSyncRequestAttempts);
    },
  );

  test(
    'early renewal bridge remains server-authoritative under clock skew',
    () {
      final status = subscriptionStatusFromServerSnapshot(
        _subscriptionStatus(SubscriptionTier.pro),
        <String, dynamic>{
          'tier': 'pro',
          'quotaMinutes': 300,
          'usedMinutes': 2,
          'reservedMinutes': 0,
          'periodKey': 'pro-month-old-generation-0',
          'periodStartsAt': '2098-12-01T00:00:00.000Z',
          'periodEndsAt': '2099-01-02T00:00:00.000Z',
          // Deliberately far from the test machine clock. The client validates
          // the shape but never decides access by comparing this timestamp.
          'serverNow': '2099-01-01T00:00:00.000Z',
        },
      );

      expect(status.tier, SubscriptionTier.pro);
      expect(status.remainingMinutes, 298);
      expect(status.totalMinutes, 300);
    },
  );

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

SubscriptionStatus _subscriptionStatus(SubscriptionTier tier) =>
    SubscriptionStatus(
      tier: tier,
      remainingMinutes: tier == SubscriptionTier.pro ? 300 : 10,
      totalMinutes: tier == SubscriptionTier.pro ? 300 : 10,
      offeringsLoaded: true,
    );
