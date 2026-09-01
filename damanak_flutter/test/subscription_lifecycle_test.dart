import 'dart:async';

import 'package:damanak/core/app_theme.dart';
import 'package:damanak/data/damanak_repository.dart';
import 'package:damanak/data/demo_repository.dart';
import 'package:damanak/models/account.dart';
import 'package:damanak/models/branch.dart';
import 'package:damanak/models/store_billing.dart';
import 'package:damanak/models/subscription.dart';
import 'package:damanak/screens/account_screen.dart';
import 'package:damanak/screens/subscription_screen.dart';
import 'package:damanak/services/store_billing_service.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:damanak/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('دورة الاشتراك داخل AppController', () {
    test('يتيح توسع شهرياً وسنوياً بمعرفي App Store الدقيقين', () async {
      final monthly = _testOffer(
        StoreBillingPlatform.appStore,
        'scale',
        BillingCycle.monthly,
      );
      final yearly = _testOffer(
        StoreBillingPlatform.appStore,
        'scale',
        BillingCycle.yearly,
      );
      final repository = _SubscriptionRepository(
        subscription: _initialPaymentSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
        offers: [monthly, yearly],
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();

      expect(
        controller.storeOffer('scale', BillingCycle.monthly)?.productId,
        'com.damanak.subscription.scale.monthly',
      );
      expect(
        controller.storeOffer('scale', BillingCycle.yearly)?.productId,
        'com.damanak.subscription.scale.yearly',
      );

      await controller.purchaseSubscription(monthly);
      expect(billing.purchasedOffers.single.productId, monthly.productId);
      billing.emit(
        _appleRestoredEvent(
          key: 'cancel-scale-monthly',
          status: StorePurchaseStatus.canceled,
          productId: monthly.productId,
          appAccountToken: 'demo-store',
        ),
      );
      await _waitUntil(
        () => controller.storeBillingState == StoreBillingState.ready,
      );

      await controller.purchaseSubscription(yearly);
      expect(billing.purchasedOffers.last.productId, yearly.productId);
      expect(billing.purchaseCalls, 2);
    });

    test('يبقي توسع السنوي قابلاً للشراء عند غياب الشهري ويشخصه', () async {
      final yearly = _testOffer(
        StoreBillingPlatform.appStore,
        'scale',
        BillingCycle.yearly,
      );
      const missingMonthly = 'com.damanak.subscription.scale.monthly';
      final repository = _SubscriptionRepository(
        subscription: _initialPaymentSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
        offers: [yearly],
        missingProductIds: const [missingMonthly],
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();

      expect(controller.storeBillingState, StoreBillingState.ready);
      expect(controller.storeOffer('scale', BillingCycle.monthly), isNull);
      expect(controller.storeOffer('scale', BillingCycle.yearly), isNotNull);
      expect(controller.storeBillingMessage, contains('توسع — شهري'));
      expect(controller.storeBillingMessage, contains(missingMonthly));

      await controller.purchaseSubscription(yearly);
      expect(billing.purchasedOffers.single.productId, yearly.productId);
    });

    test('يمسح الخطأ القديم عند بدء شراء جديد لمتجر مقفول', () async {
      final repository = _SubscriptionRepository(
        subscription: _initialPaymentSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
        purchaseError: StateError('STORE_PURCHASE_NOT_LAUNCHED'),
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      final offer = controller.storeOffers.first;
      await controller.purchaseSubscription(offer);
      expect(controller.errorMessage, isNotNull);

      billing.purchaseError = null;
      await controller.purchaseSubscription(offer);

      expect(controller.errorMessage, isNull);
      expect(controller.storeBillingState, StoreBillingState.purchasing);
    });

    test('ينهي معاملة StoreKit غير المكتملة ويوجه إلى الاستعادة', () async {
      final repository = _SubscriptionRepository(
        subscription: _initialPaymentSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
        purchaseError: PlatformException(
          code: 'storekit_duplicate_product_object',
          message: 'unfinished transaction',
        ),
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await controller.purchaseSubscription(controller.storeOffers.first);

      expect(controller.storeBillingState, StoreBillingState.ready);
      expect(controller.storeBillingMessage, isNull);
      expect(controller.errorMessage, contains('عملية متجر سابقة'));
      expect(controller.errorMessage, contains('استعادة المشتريات'));

      await controller.restoreStorePurchases();
      expect(billing.restoreCalls, 1);
      expect(billing.restoreRecoveryRequests.single, isTrue);
    });

    test('ينهي انتظار Apple بعد العودة ويمكّن الاستعادة', () async {
      final repository = _SubscriptionRepository(
        subscription: _initialPaymentSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
        purchaseEventTimeout: const Duration(seconds: 1),
        purchaseResumeGracePeriod: const Duration(milliseconds: 15),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await controller.purchaseSubscription(controller.storeOffers.first);
      expect(controller.storeBillingState, StoreBillingState.purchasing);

      controller.handleAppResumed();
      await _waitUntil(
        () => controller.storeBillingState == StoreBillingState.ready,
      );

      expect(controller.storeBillingMessage, contains('استعادة المشتريات'));
      await controller.restoreStorePurchases();
      expect(billing.restoreCalls, 1);
    });

    test('لا ينهي intent أثناء تحقق أبطأ من مهلة العودة', () async {
      final repository = _SubscriptionRepository(
        subscription: _initialPaymentSubscription(),
        verifiedSubscription: _subscription(provider: 'app_store'),
        verifyDelay: const Duration(milliseconds: 80),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
        purchaseEventTimeout: const Duration(seconds: 1),
        purchaseResumeGracePeriod: const Duration(milliseconds: 15),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      final offer = controller.storeOffers.first;
      await controller.purchaseSubscription(offer);
      controller.handleAppResumed();
      billing.emit(
        _appleRestoredEvent(
          key: 'slow-purchase-verification',
          status: StorePurchaseStatus.purchased,
          productId: offer.productId,
          appAccountToken: 'demo-store',
        ),
      );
      await _waitUntil(() => repository.verifyCalls == 1);
      await Future<void>.delayed(const Duration(milliseconds: 35));

      expect(controller.storeBillingState, StoreBillingState.purchasing);
      expect(controller.errorMessage, isNull);
      expect(controller.storeBillingMessage, contains('التحقق من إيصال'));
      expect(billing.purchaseCalls, 1);

      await _waitUntil(
        () => controller.storeBillingState == StoreBillingState.ready,
      );
      expect(controller.subscription?.isUsable, isTrue);
      expect(controller.errorMessage, isNull);
      expect(controller.noticeMessage, contains('تم التحقق من الاشتراك'));
    });

    test('يعيد حراسة الشراء بعد preflight خادمي بطيء', () async {
      final repository = _SubscriptionRepository(
        subscription: _subscription(provider: 'app_store'),
        verifiedSubscription: _subscription(provider: 'app_store'),
        refreshDelay: const Duration(milliseconds: 120),
        verifyDelay: const Duration(milliseconds: 20),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      final purchase = controller.purchaseSubscription(
        controller.storeOffers.first,
      );
      await _waitUntil(() => repository.refreshCalls == 1);
      billing.emit(
        _appleRestoredEvent(
          key: 'late-during-purchase-preflight',
          appAccountToken: 'demo-store',
        ),
      );
      await _waitUntil(() => repository.verifyCalls == 1);
      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      expect(controller.subscription?.isUsable, isTrue);
      await purchase;

      expect(billing.purchaseCalls, 0);
      expect(controller.storeBillingState, StoreBillingState.ready);
      expect(controller.errorMessage, contains('تغيّرت حالة الاشتراك'));
    });

    for (final mismatch in ['product', 'token']) {
      test('ينهي intent Apple عند اختلاف $mismatch بدلاً من التعليق', () async {
        final scale = _testOffer(
          StoreBillingPlatform.appStore,
          'scale',
          BillingCycle.monthly,
        );
        final repository = _SubscriptionRepository(
          subscription: _initialPaymentSubscription(),
        );
        final billing = _LifecycleBillingService(
          platform: StoreBillingPlatform.appStore,
          offers: [scale],
        );
        final controller = AppController.withRepository(
          repository,
          billingService: billing,
          purchaseEventTimeout: const Duration(seconds: 1),
        );
        addTearDown(controller.dispose);

        await controller.initialize();
        await controller.refreshStoreProducts();
        await controller.purchaseSubscription(scale);
        billing.emit(
          _appleRestoredEvent(
            key: 'old-apple-$mismatch',
            status: StorePurchaseStatus.purchased,
            productId: mismatch == 'product'
                ? 'com.damanak.subscription.growth.monthly'
                : scale.productId,
            appAccountToken: mismatch == 'token'
                ? '11111111-1111-4111-8111-111111111111'
                : 'demo-store',
          ),
        );
        await _waitUntil(
          () => controller.storeBillingState == StoreBillingState.ready,
        );

        expect(repository.verifyCalls, 0);
        expect(controller.errorMessage, contains('استعادة المشتريات'));
        await controller.restoreStorePurchases();
        expect(billing.restoreCalls, 1);
      });
    }

    test('يمرر ربط Apple القديم للاسترداد الصريح بعلامة recovery', () async {
      final repository = _SubscriptionRepository(
        subscription: _initialPaymentSubscription(),
        verifiedSubscription: _subscription(provider: 'app_store'),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
        restoreResult: const StoreRestoreResult(
          platform: StoreBillingPlatform.appStore,
          restoredPurchases: 1,
        ),
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      final restore = controller.restoreStorePurchases();
      await _waitUntil(() => billing.restoreCalls == 1);
      billing.emit(
        _appleRestoredEvent(
          key: 'deleted-apple-store',
          appAccountToken: '11111111-1111-4111-8111-111111111111',
        ),
      );
      await restore;

      expect(repository.receipts.single.recoveryRequested, isTrue);
      expect(billing.restoreRecoveryRequests.single, isTrue);
      expect(controller.subscription?.isUsable, isTrue);
    });

    test('ينتظر تحقق الاستعادة بعد انتهاء مهلة طلب StoreKit', () async {
      final restoreCompleter = Completer<StoreRestoreResult>();
      final repository = _SubscriptionRepository(
        subscription: _initialPaymentSubscription(),
        verifiedSubscription: _subscription(provider: 'app_store'),
        verifyDelay: const Duration(milliseconds: 20),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
        restoreCompleter: restoreCompleter,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
        storeRestoreTimeout: const Duration(milliseconds: 10),
        storeRestoreVerificationTimeout: const Duration(milliseconds: 100),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      final restore = controller.restoreStorePurchases();
      await _waitUntil(() => billing.restoreCalls == 1);
      await Future<void>.delayed(const Duration(milliseconds: 25));

      expect(controller.storeBillingState, StoreBillingState.restoring);
      expect(controller.storeBillingMessage, contains('استغرق طلب App Store'));
      billing.emit(
        _appleRestoredEvent(
          key: 'slow-restore-verification',
          appAccountToken: '11111111-1111-4111-8111-111111111111',
        ),
      );
      await _waitUntil(() => repository.verifyCalls == 1);

      await restore;
      restoreCompleter.complete(
        const StoreRestoreResult(platform: StoreBillingPlatform.appStore),
      );
      expect(repository.receipts.single.recoveryRequested, isTrue);
      expect(controller.subscription?.isUsable, isTrue);
      expect(controller.noticeMessage, contains('تمت استعادة الاشتراك'));
      expect(controller.storeBillingMessage, isNull);
    });

    test('يمنع شراء أو استعادة أثناء تحقق Apple المتأخر', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
        verifiedSubscription: _subscription(provider: 'app_store'),
        verifyDelay: const Duration(milliseconds: 80),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      billing.emit(
        _appleRestoredEvent(
          key: 'late-apple-slow-verification',
          appAccountToken: 'demo-store',
        ),
      );
      await _waitUntil(() => repository.verifyCalls == 1);

      expect(controller.storeBillingOperationInProgress, isTrue);
      await controller.restoreStorePurchases();
      expect(billing.restoreCalls, 0);
      expect(controller.errorMessage, contains('جارٍ التحقق من إيصال'));

      await controller.purchaseSubscription(controller.storeOffers.first);
      expect(billing.purchaseCalls, 0);
      expect(controller.errorMessage, contains('جارٍ التحقق من إيصال'));

      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      expect(controller.subscription?.isUsable, isTrue);
      expect(controller.errorMessage, isNull);
    });

    test('يمسح خطأ الفوترة بعد نجاح إيصال متأخر فقط', () async {
      final repository = _SubscriptionRepository(
        subscription: _inactiveStoreReceiptSubscription(),
        verifiedSubscription: _subscription(provider: 'app_store'),
        verifyError: StateError('PURCHASE_PROVIDER_UNAVAILABLE'),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      const transactionId = 'transaction-retried-receipt';
      const signedReceipt = 'signed-retried-receipt';

      billing.emit(
        _appleRestoredEvent(
          key: 'failed-receipt-delivery',
          purchaseId: transactionId,
          verificationData: signedReceipt,
          appAccountToken: 'demo-store',
        ),
      );
      await _waitUntil(() => repository.verifyCalls == 1);
      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      expect(controller.errorMessage, contains('غير متاحة مؤقتاً'));

      repository.verifyError = null;
      billing.emit(
        _appleRestoredEvent(
          key: 'successful-receipt-redelivery',
          purchaseId: transactionId,
          verificationData: signedReceipt,
          appAccountToken: 'demo-store',
        ),
      );
      await _waitUntil(() => repository.verifyCalls == 2);
      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      expect(controller.subscription?.isUsable, isTrue);
      expect(controller.errorMessage, isNull);

      repository.verifyError = StateError('STORE_VERIFICATION_TIMEOUT');
      billing.emit(
        _appleRestoredEvent(
          key: 'second-failed-receipt-delivery',
          purchaseId: transactionId,
          verificationData: signedReceipt,
          appAccountToken: 'demo-store',
        ),
      );
      await _waitUntil(() => repository.verifyCalls == 3);
      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      expect(controller.errorMessage, contains('التحقق لم يكتمل'));

      controller.handleIncomingUri(
        Uri.parse('com.damanak.damanak://join?code=invalid'),
      );
      expect(controller.errorMessage, contains('رابط الدعوة غير مكتمل'));
      repository.verifyError = null;
      billing.emit(
        _appleRestoredEvent(
          key: 'success-after-unrelated-error',
          purchaseId: transactionId,
          verificationData: signedReceipt,
          appAccountToken: 'demo-store',
        ),
      );
      await _waitUntil(() => repository.verifyCalls == 4);
      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      expect(controller.errorMessage, contains('رابط الدعوة غير مكتمل'));
    });

    test('يمنع شراء جديد أثناء تحقق Google الصامت', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
        verifiedSubscription: _subscription(provider: 'google_play'),
        verifyDelay: const Duration(milliseconds: 80),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.googlePlay,
        restoreResult: const StoreRestoreResult(
          platform: StoreBillingPlatform.googlePlay,
          restoredPurchases: 1,
        ),
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await _waitUntil(() => billing.restoreCalls == 1);
      expect(controller.storeBillingOperationInProgress, isTrue);
      billing.emit(
        _googlePurchasedEvent(
          key: 'silent-google-slow-verification',
          status: StorePurchaseStatus.restored,
          accountId: null,
          storeId: null,
        ),
      );
      await _waitUntil(() => repository.verifyCalls == 1);

      await controller.purchaseSubscription(controller.storeOffers.first);
      expect(billing.purchaseCalls, 0);
      expect(controller.errorMessage, contains('جارٍ التحقق من إيصال'));

      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      expect(controller.subscription?.isUsable, isTrue);
      expect(controller.errorMessage, isNull);
      expect(repository.receipts.single.recoveryRequested, isFalse);
    });

    test('يمرر ربط Google القديم فقط في الاسترداد الصريح', () async {
      final repository = _SubscriptionRepository(
        subscription: _initialPaymentSubscription(),
        verifiedSubscription: _subscription(provider: 'google_play'),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.googlePlay,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await _waitUntil(() => billing.restoreCalls == 1);
      expect(billing.restoreRecoveryRequests.single, isFalse);
      billing.restoreResult = const StoreRestoreResult(
        platform: StoreBillingPlatform.googlePlay,
        restoredPurchases: 1,
      );

      final restore = controller.restoreStorePurchases();
      await _waitUntil(() => billing.restoreCalls == 2);
      billing.emit(
        _googlePurchasedEvent(
          key: 'deleted-google-store',
          status: StorePurchaseStatus.restored,
          accountId: '11111111-1111-4111-8111-111111111111',
          storeId: '22222222-2222-4222-8222-222222222222',
        ),
      );
      await restore;

      expect(repository.receipts.single.recoveryRequested, isTrue);
      expect(billing.restoreRecoveryRequests, [isFalse, isTrue]);
      expect(controller.subscription?.isUsable, isTrue);
    });

    test('يمنع شراء مزود ثانٍ أثناء سريان الفترة الحالية', () async {
      final repository = _SubscriptionRepository(
        subscription: _subscription(provider: 'app_store'),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.googlePlay,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await controller.purchaseSubscription(controller.storeOffers.first);

      expect(billing.purchaseCalls, 0);
      expect(repository.refreshCalls, 1);
      expect(controller.errorMessage, contains('لتجنب اشتراكين'));
    });

    test('يفشل مغلقًا إذا تعذر فحص الاشتراك الخادمي قبل الدفع', () async {
      final repository = _SubscriptionRepository(
        subscription: _subscription(provider: 'app_store'),
        refreshError: StateError('STORE_REFRESH_FAILED'),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await controller.purchaseSubscription(controller.storeOffers.last);

      expect(billing.purchaseCalls, 0);
      expect(controller.errorMessage, contains('لم يبدأ أي اشتراك جديد'));
      expect(controller.storeBillingState, StoreBillingState.ready);
    });

    test('يكمل الشراء ثم يحمل الفرع قبل فتح المتجر الأول', () async {
      final activationBranches = Completer<List<StoreBranch>>();
      final repository = _SubscriptionRepository(
        subscription: _initialPaymentSubscription(),
        verifiedSubscription: _subscription(provider: 'google_play'),
        activationBranches: activationBranches,
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.googlePlay,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      expect(controller.branches, isEmpty);
      await controller.refreshStoreProducts();
      await controller.purchaseSubscription(controller.storeOffers.first);
      billing.emit(
        _googlePurchasedEvent(key: 'initial-purchase', needsCompletion: true),
      );
      await _waitUntil(() => repository.loadBranchesCalls == 2);

      expect(billing.completeCalls, 1);
      expect(repository.receipts.single.recoveryRequested, isFalse);
      expect(controller.subscription!.isAwaitingSubscription, isTrue);
      expect(controller.branches, isEmpty);

      activationBranches.complete([_mainBranch()]);
      await _waitUntil(() => controller.subscription?.isUsable == true);

      expect(controller.branches.single.code, 'MAIN');
      expect(controller.activeBranch?.code, 'MAIN');

      final relaunched = AppController.withRepository(
        repository,
        billingService: _LifecycleBillingService(
          platform: StoreBillingPlatform.googlePlay,
        ),
      );
      addTearDown(relaunched.dispose);
      await relaunched.initialize();
      expect(relaunched.subscription!.isUsable, isTrue);
      expect(relaunched.branches.single.code, 'MAIN');
    });

    test('تحمل الاستعادة الفرع قبل إزالة بوابة الدفع الأول', () async {
      final activationBranches = Completer<List<StoreBranch>>();
      final repository = _SubscriptionRepository(
        subscription: _inactiveStoreReceiptSubscription(),
        verifiedSubscription: _subscription(provider: 'app_store'),
        activationBranches: activationBranches,
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
        restoreResult: const StoreRestoreResult(
          platform: StoreBillingPlatform.appStore,
          restoredPurchases: 1,
        ),
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      final restore = controller.restoreStorePurchases();
      await _waitUntil(() => billing.restoreCalls == 1);
      billing.emit(
        _appleRestoredEvent(
          key: 'initial-restore',
          appAccountToken: 'demo-store',
          needsCompletion: true,
        ),
      );
      await _waitUntil(() => repository.loadBranchesCalls == 2);

      expect(billing.completeCalls, 1);
      expect(controller.subscription!.isAwaitingSubscription, isFalse);
      expect(controller.subscription!.isUsable, isFalse);
      expect(controller.branches, isEmpty);

      activationBranches.complete([_mainBranch()]);
      await restore;

      expect(controller.subscription!.isUsable, isTrue);
      expect(controller.branches.single.code, 'MAIN');
      expect(controller.noticeMessage, contains('تمت استعادة الاشتراك'));
    });

    test('يحد انتظار تحقق الاستعادة وتهيئة المتجر المعلقة', () async {
      final activationBranches = Completer<List<StoreBranch>>();
      final repository = _SubscriptionRepository(
        subscription: _inactiveStoreReceiptSubscription(),
        verifiedSubscription: _subscription(provider: 'app_store'),
        activationBranches: activationBranches,
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
        restoreResult: const StoreRestoreResult(
          platform: StoreBillingPlatform.appStore,
          restoredPurchases: 1,
        ),
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
        storeRestoreVerificationTimeout: const Duration(milliseconds: 10),
        storeRestoreVerificationSettleTimeout: const Duration(milliseconds: 20),
        initialActivationWorkspaceTimeout: const Duration(milliseconds: 60),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      final restore = controller.restoreStorePurchases();
      await _waitUntil(() => billing.restoreCalls == 1);
      billing.emit(
        _appleRestoredEvent(
          key: 'hanging-activation-restore',
          appAccountToken: 'demo-store',
        ),
      );
      await _waitUntil(() => repository.loadBranchesCalls == 2);

      await restore.timeout(const Duration(milliseconds: 150));
      expect(controller.storeBillingState, StoreBillingState.ready);
      expect(controller.errorMessage, contains('الدفع محفوظ'));

      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      expect(controller.errorMessage, contains('تعذّر تهيئة بيانات المتجر'));
      activationBranches.complete([_mainBranch()]);
      await Future<void>.delayed(const Duration(milliseconds: 5));
    });

    test('يمسح عروض الأسعار القديمة إذا فشل تحديث الكتالوج', () async {
      final repository = _SubscriptionRepository(
        subscription: _subscription(provider: 'app_store'),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      expect(controller.storeOffers, isNotEmpty);

      billing.catalogError = StateError('STORE_UNAVAILABLE');
      await controller.refreshStoreProducts();

      expect(controller.storeOffers, isEmpty);
      expect(controller.storeBillingState, StoreBillingState.unavailable);
    });

    test('لا يعلن نجاح الاستعادة عند عدم وجود مشتريات', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
        restoreResult: const StoreRestoreResult(
          platform: StoreBillingPlatform.appStore,
          restoredPurchases: 0,
        ),
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await controller.restoreStorePurchases();

      expect(controller.noticeMessage, isNull);
      expect(controller.storeBillingMessage, contains('لم نجد مشتريات'));
      expect(controller.storeBillingState, StoreBillingState.ready);
    });

    test(
      'تُبقي الاستعادة دفعة المتجر المطابقة معلّقة رغم سجل حساب آخر',
      () async {
        final repository = _SubscriptionRepository(
          subscription: _trialSubscription(),
        );
        final billing = _LifecycleBillingService(
          platform: StoreBillingPlatform.googlePlay,
          restoreResult: const StoreRestoreResult(
            platform: StoreBillingPlatform.googlePlay,
            restoredPurchases: 0,
            pendingPurchases: 1,
            accountMismatchDetected: true,
          ),
        );
        final controller = AppController.withRepository(
          repository,
          billingService: billing,
        );
        addTearDown(controller.dispose);

        await controller.initialize();
        await controller.refreshStoreProducts();
        await _waitUntil(() => !controller.storeBillingOperationInProgress);
        await controller.restoreStorePurchases();

        expect(controller.errorMessage, isNull);
        expect(controller.storeBillingState, StoreBillingState.pending);
        expect(controller.storeBillingMessage, contains('دفعة معلّقة'));
      },
    );

    test('يفتح إدارة الاشتراك وفق المزود المحفوظ لا متجر الجهاز', () async {
      final repository = _SubscriptionRepository(
        subscription: _subscription(provider: 'app_store'),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.googlePlay,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.openStoreSubscriptionManagement();

      expect(billing.managedProvider, StoreBillingPlatform.appStore);
      expect(
        billing.managedProductId,
        'com.damanak.subscription.growth.monthly',
      );
    });

    test('يربط حدث تخفيض Google المؤجل حتى إذا أعاد المنتج القديم', () async {
      final repository = _SubscriptionRepository(
        subscription: _subscription(
          provider: 'google_play',
          plan: _scalePlan,
          productId: 'com.damanak.subscription.scale',
        ),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.googlePlay,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
        purchaseEventTimeout: const Duration(milliseconds: 200),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      final downgrade = controller.storeOffers.firstWhere(
        (offer) => offer.planId == 'growth',
      );
      await controller.purchaseSubscription(downgrade);
      expect(billing.requiredExistingSubscription, isTrue);

      billing.emit(
        StorePurchaseEvent(
          key: 'deferred-token',
          status: StorePurchaseStatus.pending,
          platform: StoreBillingPlatform.googlePlay,
          productId: 'com.damanak.subscription.scale',
          basePlanId: 'monthly',
          purchaseId: 'order-deferred',
          transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
          verificationData: 'deferred-token',
          verificationSource: 'google_play',
          needsCompletion: false,
          accountId: 'demo-owner',
          storeId: 'demo-store',
          pendingProductIds: ['com.damanak.subscription.growth'],
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.verifyCalls, 0);
      expect(controller.storeBillingState, StoreBillingState.pending);

      billing.emit(
        StorePurchaseEvent(
          key: 'committed-deferred-token',
          status: StorePurchaseStatus.purchased,
          platform: StoreBillingPlatform.googlePlay,
          productId: 'com.damanak.subscription.growth',
          basePlanId: 'monthly',
          purchaseId: 'order-committed-deferred',
          transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
          verificationData: 'committed-deferred-token',
          verificationSource: 'google_play',
          needsCompletion: false,
          accountId: 'demo-owner',
          storeId: 'demo-store',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.verifyCalls, 1);
      expect(controller.storeBillingState, StoreBillingState.ready);
      expect(controller.noticeMessage, contains('قبل المتجر طلب التغيير'));
    });

    test('يخرج من pending عند وصول تأكيد متأخر بعد الاستعادة', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.googlePlay,
        restoreResult: const StoreRestoreResult(
          platform: StoreBillingPlatform.googlePlay,
          restoredPurchases: 0,
          pendingPurchases: 1,
        ),
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      await controller.restoreStorePurchases();
      expect(controller.storeBillingState, StoreBillingState.pending);

      billing.emit(_googlePurchasedEvent(key: 'late-pending-confirmation'));
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.verifyCalls, 1);
      expect(controller.storeBillingState, StoreBillingState.ready);
    });

    test('لا يتحقق من حدث المتجر نفسه مرتين بعد نجاحه', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.googlePlay,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      final event = _googlePurchasedEvent(key: 'duplicate-purchase');
      billing.emit(event);
      billing.emit(event);
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(repository.verifyCalls, 1);
    });

    test('لا تكتب نتيجة استعادة قديمة فوق شراء أحدث', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
        verifyDelay: const Duration(milliseconds: 60),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
        restoreResult: const StoreRestoreResult(
          platform: StoreBillingPlatform.appStore,
          restoredPurchases: 1,
        ),
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
        storeRestoreTimeout: const Duration(milliseconds: 10),
        purchaseEventTimeout: const Duration(milliseconds: 250),
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      final restore = controller.restoreStorePurchases();
      await Future<void>.delayed(const Duration(milliseconds: 1));
      billing.emit(_appleRestoredEvent(key: 'slow-restore'));
      await restore;

      await controller.purchaseSubscription(controller.storeOffers.last);
      expect(controller.storeBillingState, StoreBillingState.purchasing);
      await Future<void>.delayed(const Duration(milliseconds: 80));

      expect(repository.verifyCalls, 1);
      expect(controller.storeBillingState, StoreBillingState.purchasing);
    });

    test('يرفض حدث Apple المصطف غير المربوط بعد تحميل المتجر', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      billing.emit(_appleRestoredEvent(key: 'previous-account'));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await controller.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(repository.verifyCalls, 0);
    });

    test('يتحقق من حدث Apple الموثوق الذي يصل أثناء الإقلاع', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      billing.emit(
        _appleRestoredEvent(
          key: 'cold-start-current-store',
          appAccountToken: 'DEMO-STORE',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await controller.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.verifyCalls, 1);
    });

    test('لا يربط حدث Apple متأخراً بلا شراء أو استعادة نشطين', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      billing.emit(
        _appleRestoredEvent(
          key: 'late-other-workspace',
          appAccountToken: 'demo-owner',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.verifyCalls, 0);
    });

    test('يتحقق من حدث Apple المتأخر إذا حمل رمز المتجر الدقيق', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      billing.emit(
        _appleRestoredEvent(
          key: 'late-current-workspace',
          appAccountToken: 'DEMO-STORE',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.verifyCalls, 1);
    });

    test('يمرر Google غير المربوط للخادم داخل الاستعادة فقط', () async {
      final repository = _SubscriptionRepository(
        subscription: _subscription(provider: 'google_play'),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.googlePlay,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await _waitUntil(() => billing.restoreCalls == 1);
      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      billing.restoreResult = const StoreRestoreResult(
        platform: StoreBillingPlatform.googlePlay,
        restoredPurchases: 1,
      );
      final restore = controller.restoreStorePurchases();
      await _waitUntil(() => billing.restoreCalls == 2);
      billing.emit(
        StorePurchaseEvent(
          key: 'out-of-app-token',
          status: StorePurchaseStatus.restored,
          platform: StoreBillingPlatform.googlePlay,
          productId: 'com.damanak.subscription.growth',
          basePlanId: 'monthly',
          purchaseId: 'order-out-of-app',
          transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
          verificationData: 'out-of-app-token-with-enough-length',
          verificationSource: 'google_play',
          needsCompletion: false,
        ),
      );
      await restore;

      expect(repository.verifyCalls, 1);
      expect(controller.noticeMessage, contains('تمت استعادة الاشتراك'));
    });

    test('يرفض استعادة Google التي تخص حساب ضمانك آخر', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.googlePlay,
        restoreResult: const StoreRestoreResult(
          platform: StoreBillingPlatform.googlePlay,
          restoredPurchases: 0,
          accountMismatchDetected: true,
        ),
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await _waitUntil(() => !controller.storeBillingOperationInProgress);
      await controller.restoreStorePurchases();

      expect(controller.errorMessage, contains('حساب ضمانك آخر'));
      expect(repository.verifyCalls, 0);
    });

    test('يحدّث الاستحقاق بعد العودة من إدارة الاشتراك', () async {
      final repository = _SubscriptionRepository(
        subscription: _subscription(provider: 'app_store'),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.appStore,
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.openStoreSubscriptionManagement();
      controller.handleAppResumed();
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(repository.refreshCalls, 1);
    });

    test('يكتشف إعادة اشتراك Google خارج التطبيق بعد تحميل الكتالوج', () async {
      final repository = _SubscriptionRepository(
        subscription: _trialSubscription(),
      );
      final billing = _LifecycleBillingService(
        platform: StoreBillingPlatform.googlePlay,
        restoreResult: const StoreRestoreResult(
          platform: StoreBillingPlatform.googlePlay,
          restoredPurchases: 1,
        ),
      );
      final controller = AppController.withRepository(
        repository,
        billingService: billing,
      );
      addTearDown(controller.dispose);

      await controller.initialize();
      await controller.refreshStoreProducts();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      billing.emit(
        StorePurchaseEvent(
          key: 'silent-out-of-app',
          status: StorePurchaseStatus.restored,
          platform: StoreBillingPlatform.googlePlay,
          productId: 'com.damanak.subscription.growth',
          basePlanId: 'monthly',
          purchaseId: 'order-silent-out-of-app',
          transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
          verificationData: 'silent-out-of-app-token-with-safe-length',
          verificationSource: 'google_play',
          needsCompletion: false,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      controller.handleAppResumed();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(billing.restoreCalls, 1);
      expect(billing.restoreRecoveryRequests.single, isFalse);
      expect(repository.verifyCalls, 1);
      expect(repository.receipts.single.recoveryRequested, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.noticeMessage, isNull);
    });
  });

  testWidgets('يعرض إعادة المحاولة مع كتالوج جزئي دون تعطيل توسع السنوي', (
    tester,
  ) async {
    final yearly = _testOffer(
      StoreBillingPlatform.appStore,
      'scale',
      BillingCycle.yearly,
    );
    final repository = _SubscriptionRepository(
      subscription: _initialPaymentSubscription(),
    );
    final billing = _LifecycleBillingService(
      platform: StoreBillingPlatform.appStore,
      offers: [yearly],
      missingProductIds: const ['com.damanak.subscription.scale.monthly'],
    );
    final controller = AppController.withRepository(
      repository,
      billingService: billing,
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.refreshStoreProducts();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AppScope(
            controller: controller,
            child: const SubscriptionScreen(requiredActivation: true),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(controller.storeOffer('scale', BillingCycle.yearly), isNotNull);
    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('subscription-plan-picker')),
      240,
      scrollable: scrollable,
    );
    final scalePicker = find.descendant(
      of: find.byKey(const ValueKey('subscription-plan-picker')),
      matching: find.text('توسع'),
    );
    await tester.tap(scalePicker);
    await tester.pumpAndSettle();
    final scaleCard = find.byKey(const ValueKey('subscription-plan-scale'));
    final buyButton = find.descendant(
      of: scaleCard,
      matching: find.widgetWithText(FilledButton, 'اختيار توسع'),
    );
    expect(buyButton, findsOneWidget);
    expect(tester.widget<FilledButton>(buyButton).onPressed, isNotNull);
  });

  testWidgets('تعرض الدورة والمزود وروابط المستندات القانونية', (tester) async {
    final repository = _SubscriptionRepository(
      subscription: _subscription(provider: 'app_store'),
    );
    final billing = _LifecycleBillingService(
      platform: StoreBillingPlatform.appStore,
    );
    final controller = AppController.withRepository(
      repository,
      billingService: billing,
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.refreshStoreProducts();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AppScope(
            controller: controller,
            child: const SubscriptionScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('شهري • App Store'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('شروط الاستخدام'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('شروط الاستخدام'), findsOneWidget);
    expect(find.text('سياسة الخصوصية'), findsOneWidget);
  });

  testWidgets('يبقي حذف الحساب فورياً ويحذر من استمرار فوترة المتجر', (
    tester,
  ) async {
    final repository = _SubscriptionRepository(
      subscription: _subscription(provider: 'app_store'),
    );
    final billing = _LifecycleBillingService(
      platform: StoreBillingPlatform.appStore,
    );
    final controller = AppController.withRepository(
      repository,
      billingService: billing,
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AppScope(controller: controller, child: const AccountScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final verticalScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.text('حذف الحساب نهائياً'),
      400,
      scrollable: verticalScrollable,
    );
    if (find.text('حذف الحساب نهائياً').hitTestable().evaluate().isEmpty) {
      await tester.drag(verticalScrollable, const Offset(0, -80));
      await tester.pumpAndSettle();
    }
    expect(find.text('حذف الحساب نهائياً').hitTestable(), findsOneWidget);
    await tester.tap(find.text('حذف الحساب نهائياً').hitTestable());
    await tester.pumpAndSettle();

    expect(
      find.textContaining('حذف حساب ضمانك لا يلغي الاشتراك'),
      findsOneWidget,
    );
    expect(find.text('إدارة الاشتراك'), findsOneWidget);
    expect(find.text('حذف نهائي'), findsOneWidget);
  });

  testWidgets('يبقى تأكيد تغيير الاشتراك قابلاً للاستخدام عند تكبير 200%', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repository = _SubscriptionRepository(
      subscription: _subscription(provider: 'app_store'),
    );
    final billing = _LifecycleBillingService(
      platform: StoreBillingPlatform.appStore,
    );
    final controller = AppController.withRepository(
      repository,
      billingService: billing,
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.refreshStoreProducts();

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: AppScope(
            controller: controller,
            child: const SubscriptionScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final verticalScrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    expect(verticalScrollable, findsOneWidget);
    final scrollPosition = tester
        .state<ScrollableState>(verticalScrollable)
        .position;
    Future<void> reveal(Finder target, String description) async {
      var offset = 0.0;
      while (true) {
        scrollPosition.jumpTo(offset);
        await tester.pump();
        if (target.hitTestable().evaluate().isNotEmpty) return;
        final maxOffset = scrollPosition.maxScrollExtent;
        if (offset >= maxOffset) break;
        offset = (offset + 25).clamp(0, maxOffset).toDouble();
      }
      fail('تعذر إظهار عنصر الاشتراك: $description');
    }

    await reveal(find.text('سنوي'), 'دورة الفوترة السنوية');
    await tester.tap(find.text('سنوي').hitTestable());
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SegmentedButton<BillingCycle>>(
            find.byType(SegmentedButton<BillingCycle>),
          )
          .selected,
      {BillingCycle.yearly},
    );
    final planAction = find.descendant(
      of: find.byKey(const ValueKey('subscription-plan-growth')),
      matching: find.byType(OutlinedButton),
    );
    await reveal(planAction, 'زر تغيير دورة الفوترة');
    final planActionLabels = tester
        .widgetList<Text>(
          find.descendant(of: planAction, matching: find.byType(Text)),
        )
        .map((text) => text.data)
        .toList(growable: false);
    expect(planActionLabels, contains('اختيار الفوترة سنوي'));
    await tester.tap(planAction.hitTestable());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('تأكيد اختيار الاشتراك'), findsOneWidget);
    expect(find.text('المتابعة إلى المتجر'), findsOneWidget);
  });
}

StoreProductOffer _testOffer(
  StoreBillingPlatform platform,
  String planId,
  BillingCycle cycle,
) {
  final isGoogle = platform == StoreBillingPlatform.googlePlay;
  return StoreProductOffer(
    key: '$planId:${cycle.value}',
    planId: planId,
    cycle: cycle,
    productId: isGoogle
        ? DamanakStoreCatalog.googleProductId(planId)
        : DamanakStoreCatalog.appleProductId(planId, cycle),
    basePlanId: isGoogle ? cycle.value : null,
    title: planId,
    description: cycle.value,
    localizedPrice: cycle == BillingCycle.monthly
        ? '199.99 ر.ق'
        : '1999.99 ر.ق',
    rawPrice: cycle == BillingCycle.monthly ? 199.99 : 1999.99,
    currencyCode: 'QAR',
  );
}

StorePurchaseEvent _googlePurchasedEvent({
  required String key,
  StorePurchaseStatus status = StorePurchaseStatus.purchased,
  bool needsCompletion = false,
  String productId = 'com.damanak.subscription.growth',
  String? accountId = 'demo-owner',
  String? storeId = 'demo-store',
}) => StorePurchaseEvent(
  key: key,
  status: status,
  platform: StoreBillingPlatform.googlePlay,
  productId: productId,
  basePlanId: 'monthly',
  purchaseId: 'order-$key',
  transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
  verificationData: 'token-$key',
  verificationSource: 'google_play',
  needsCompletion: needsCompletion,
  accountId: accountId,
  storeId: storeId,
);

StorePurchaseEvent _appleRestoredEvent({
  required String key,
  String? appAccountToken,
  bool needsCompletion = false,
  StorePurchaseStatus status = StorePurchaseStatus.restored,
  String productId = 'com.damanak.subscription.growth.monthly',
  String? purchaseId,
  String? verificationData,
  String? errorCode,
  String? errorMessage,
}) => StorePurchaseEvent(
  key: key,
  status: status,
  platform: StoreBillingPlatform.appStore,
  productId: productId,
  purchaseId: purchaseId ?? 'transaction-$key',
  transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
  verificationData: verificationData ?? 'signed-$key',
  verificationSource: 'app_store',
  needsCompletion: needsCompletion,
  errorCode: errorCode,
  errorMessage: errorMessage,
  appAccountToken: appAccountToken,
);

const _growthPlan = PlanInfo(
  id: 'growth',
  name: 'نمو',
  monthlyPrice: 0,
  yearlyPrice: 0,
  maxMembers: 5,
  monthlyWarranties: 600,
  maxBranches: 3,
);

const _scalePlan = PlanInfo(
  id: 'scale',
  name: 'توسع',
  monthlyPrice: 0,
  yearlyPrice: 0,
  maxMembers: 15,
  monthlyWarranties: 3000,
  maxBranches: 20,
);

SubscriptionInfo _subscription({
  required String provider,
  PlanInfo plan = _growthPlan,
  String? productId,
}) => SubscriptionInfo(
  id: 'subscription-store',
  status: 'active',
  plan: plan,
  trialEndsAt: null,
  periodEndsAt: DateTime.now().add(const Duration(days: 30)),
  usedWarranties: 12,
  source: 'store',
  billingProvider: provider,
  storeProductId: productId ?? 'com.damanak.subscription.growth.monthly',
  billingCycle: 'monthly',
  autoRenews: true,
  lastVerifiedAt: DateTime.now(),
);

SubscriptionInfo _trialSubscription() => SubscriptionInfo(
  id: 'subscription-trial',
  status: 'trialing',
  plan: _growthPlan,
  trialEndsAt: DateTime.now().add(const Duration(days: 7)),
  periodEndsAt: DateTime.now().add(const Duration(days: 7)),
  usedWarranties: 0,
);

SubscriptionInfo _initialPaymentSubscription() => const SubscriptionInfo(
  id: 'subscription-initial-payment',
  status: 'canceled',
  plan: _growthPlan,
  trialEndsAt: null,
  periodEndsAt: null,
  usedWarranties: 0,
  source: 'trial',
);

SubscriptionInfo _inactiveStoreReceiptSubscription() => const SubscriptionInfo(
  id: 'subscription-inactive-store-receipt',
  status: 'canceled',
  plan: _growthPlan,
  trialEndsAt: null,
  periodEndsAt: null,
  usedWarranties: 0,
  source: 'store',
  billingProvider: 'app_store',
  storeProductId: 'com.damanak.subscription.growth.monthly',
  billingCycle: 'monthly',
);

StoreBranch _mainBranch() => StoreBranch(
  id: 'main-branch',
  storeId: 'demo-store',
  name: 'الفرع الرئيسي',
  code: 'MAIN',
  city: 'الدوحة',
  address: '',
  phone: '',
  isMain: true,
  isActive: true,
  createdAt: DateTime(2026, 9),
);

Future<void> _waitUntil(bool Function() predicate) async {
  for (var attempt = 0; attempt < 100 && !predicate(); attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  expect(predicate(), isTrue);
}

class _SubscriptionRepository extends DemoDamanakRepository {
  _SubscriptionRepository({
    required this.subscription,
    this.verifyDelay = Duration.zero,
    this.verifyError,
    this.refreshDelay = Duration.zero,
    this.refreshError,
    this.verifiedSubscription,
    this.activationBranches,
  });

  SubscriptionInfo subscription;
  final Duration verifyDelay;
  Object? verifyError;
  final Duration refreshDelay;
  final Object? refreshError;
  final SubscriptionInfo? verifiedSubscription;
  final Completer<List<StoreBranch>>? activationBranches;
  int verifyCalls = 0;
  int refreshCalls = 0;
  int loadBranchesCalls = 0;
  final List<StorePurchaseReceipt> receipts = [];

  @override
  bool get isDemo => false;

  @override
  Future<WorkspaceSnapshot?> loadWorkspace() async => WorkspaceSnapshot(
    store: const StoreWorkspace(
      id: 'demo-store',
      name: 'متجر الاختبار',
      phone: '',
      city: 'الدوحة',
      countryCode: 'QA',
    ),
    membership: const StoreMembership(
      storeId: 'demo-store',
      userId: 'demo-owner',
      role: MemberRole.owner,
      status: 'active',
    ),
    subscription: subscription,
  );

  @override
  Future<List<StoreBranch>> loadBranches(String storeId) async {
    loadBranchesCalls += 1;
    final pendingBranches = activationBranches;
    if (pendingBranches == null) return super.loadBranches(storeId);
    if (loadBranchesCalls == 1) return const <StoreBranch>[];
    return pendingBranches.future;
  }

  @override
  Future<SubscriptionInfo> verifyStorePurchase({
    required String storeId,
    required StorePurchaseReceipt receipt,
  }) async {
    verifyCalls += 1;
    receipts.add(receipt);
    if (verifyDelay > Duration.zero) await Future<void>.delayed(verifyDelay);
    final error = verifyError;
    if (error != null) throw error;
    final result = verifiedSubscription ?? subscription;
    subscription = result;
    return result;
  }

  @override
  Future<SubscriptionInfo> refreshStoreSubscription(String storeId) async {
    refreshCalls += 1;
    if (refreshDelay > Duration.zero) {
      await Future<void>.delayed(refreshDelay);
    }
    final error = refreshError;
    if (error != null) throw error;
    return subscription;
  }
}

class _LifecycleBillingService implements StoreBillingService {
  _LifecycleBillingService({
    required this.platform,
    this.restoreResult,
    this.restoreCompleter,
    this.offers,
    this.missingProductIds = const [],
    this.purchaseError,
  });

  final StoreBillingPlatform platform;
  StoreRestoreResult? restoreResult;
  final Completer<StoreRestoreResult>? restoreCompleter;
  final List<StoreProductOffer>? offers;
  final List<String> missingProductIds;
  Object? purchaseError;
  final StreamController<List<StorePurchaseEvent>> _updates =
      StreamController<List<StorePurchaseEvent>>.broadcast();
  Object? catalogError;
  int purchaseCalls = 0;
  int restoreCalls = 0;
  int completeCalls = 0;
  final List<StoreProductOffer> purchasedOffers = [];
  final List<bool> restoreRecoveryRequests = [];
  bool? requiredExistingSubscription;
  StoreBillingPlatform? managedProvider;
  String? managedProductId;

  @override
  Stream<List<StorePurchaseEvent>> get purchaseUpdates => _updates.stream;

  @override
  Future<StoreProductLoadResult> loadProducts({
    required String accountId,
  }) async {
    final error = catalogError;
    if (error != null) throw error;
    return StoreProductLoadResult(
      available: true,
      platform: platform,
      offers:
          offers ??
          [
            _offer('growth', BillingCycle.monthly),
            _offer('growth', BillingCycle.yearly),
          ],
      missingProductIds: missingProductIds,
    );
  }

  StoreProductOffer _offer(String planId, BillingCycle cycle) {
    final isGoogle = platform == StoreBillingPlatform.googlePlay;
    return StoreProductOffer(
      key: '$planId:${cycle.value}',
      planId: planId,
      cycle: cycle,
      productId: isGoogle
          ? DamanakStoreCatalog.googleProductId(planId)
          : DamanakStoreCatalog.appleProductId(planId, cycle),
      basePlanId: isGoogle ? cycle.value : null,
      title: planId,
      description: cycle.value,
      localizedPrice: '39.99 ر.ق',
      rawPrice: 39.99,
      currencyCode: 'QAR',
    );
  }

  @override
  Future<void> purchase(
    StoreProductOffer offer, {
    required String accountId,
    required String storeId,
    required BillingCycle? currentCycle,
    required bool requireExistingSubscription,
  }) async {
    purchaseCalls += 1;
    purchasedOffers.add(offer);
    requiredExistingSubscription = requireExistingSubscription;
    final error = purchaseError;
    if (error != null) throw error;
  }

  @override
  Future<StoreRestoreResult> restorePurchases({
    required String accountId,
    required String storeId,
    bool recoveryRequested = false,
  }) async {
    restoreCalls += 1;
    restoreRecoveryRequests.add(recoveryRequested);
    final pendingRestore = restoreCompleter;
    if (pendingRestore != null) return pendingRestore.future;
    return restoreResult ??
        StoreRestoreResult(platform: platform, restoredPurchases: 0);
  }

  @override
  Future<void> completePurchase(StorePurchaseEvent event) async {
    completeCalls += 1;
  }

  @override
  Future<bool> openSubscriptionManagement(
    StoreBillingPlatform provider, {
    String? productId,
  }) async {
    managedProvider = provider;
    managedProductId = productId;
    return true;
  }

  void emit(StorePurchaseEvent event) => _updates.add([event]);

  @override
  Future<void> dispose() => _updates.close();
}
