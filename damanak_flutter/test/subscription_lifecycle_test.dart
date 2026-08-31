import 'dart:async';

import 'package:damanak/core/app_theme.dart';
import 'package:damanak/data/damanak_repository.dart';
import 'package:damanak/data/demo_repository.dart';
import 'package:damanak/models/account.dart';
import 'package:damanak/models/store_billing.dart';
import 'package:damanak/models/subscription.dart';
import 'package:damanak/screens/account_screen.dart';
import 'package:damanak/screens/subscription_screen.dart';
import 'package:damanak/services/store_billing_service.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:damanak/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ar'));

  group('دورة الاشتراك داخل AppController', () {
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
      final restore = controller.restoreStorePurchases();
      await Future<void>.delayed(const Duration(milliseconds: 1));
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
      expect(repository.verifyCalls, 1);
      expect(controller.errorMessage, isNull);
      expect(controller.noticeMessage, isNull);
    });
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

StorePurchaseEvent _googlePurchasedEvent({required String key}) =>
    StorePurchaseEvent(
      key: key,
      status: StorePurchaseStatus.purchased,
      platform: StoreBillingPlatform.googlePlay,
      productId: 'com.damanak.subscription.growth',
      basePlanId: 'monthly',
      purchaseId: 'order-$key',
      transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
      verificationData: 'token-$key',
      verificationSource: 'google_play',
      needsCompletion: false,
      accountId: 'demo-owner',
      storeId: 'demo-store',
    );

StorePurchaseEvent _appleRestoredEvent({
  required String key,
  String? appAccountToken,
}) => StorePurchaseEvent(
  key: key,
  status: StorePurchaseStatus.restored,
  platform: StoreBillingPlatform.appStore,
  productId: 'com.damanak.subscription.growth.monthly',
  purchaseId: 'transaction-$key',
  transactionDate: DateTime.now().millisecondsSinceEpoch.toString(),
  verificationData: 'signed-$key',
  verificationSource: 'app_store',
  needsCompletion: false,
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

class _SubscriptionRepository extends DemoDamanakRepository {
  _SubscriptionRepository({
    required this.subscription,
    this.verifyDelay = Duration.zero,
    this.refreshError,
  });

  SubscriptionInfo subscription;
  final Duration verifyDelay;
  final Object? refreshError;
  int verifyCalls = 0;
  int refreshCalls = 0;

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
  Future<SubscriptionInfo> verifyStorePurchase({
    required String storeId,
    required StorePurchaseReceipt receipt,
  }) async {
    verifyCalls += 1;
    if (verifyDelay > Duration.zero) await Future<void>.delayed(verifyDelay);
    return subscription;
  }

  @override
  Future<SubscriptionInfo> refreshStoreSubscription(String storeId) async {
    refreshCalls += 1;
    final error = refreshError;
    if (error != null) throw error;
    return subscription;
  }
}

class _LifecycleBillingService implements StoreBillingService {
  _LifecycleBillingService({required this.platform, this.restoreResult});

  final StoreBillingPlatform platform;
  final StoreRestoreResult? restoreResult;
  final StreamController<List<StorePurchaseEvent>> _updates =
      StreamController<List<StorePurchaseEvent>>.broadcast();
  Object? catalogError;
  int purchaseCalls = 0;
  int restoreCalls = 0;
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
      offers: [
        _offer('growth', BillingCycle.monthly),
        _offer('growth', BillingCycle.yearly),
      ],
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
    requiredExistingSubscription = requireExistingSubscription;
  }

  @override
  Future<StoreRestoreResult> restorePurchases({
    required String accountId,
    required String storeId,
  }) async {
    restoreCalls += 1;
    return restoreResult ??
        StoreRestoreResult(platform: platform, restoredPurchases: 0);
  }

  @override
  Future<void> completePurchase(StorePurchaseEvent event) async {}

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
