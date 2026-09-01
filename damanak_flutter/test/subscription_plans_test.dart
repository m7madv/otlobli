import 'dart:async';
import 'dart:io';

import 'package:damanak/app.dart';
import 'package:damanak/data/damanak_repository.dart';
import 'package:damanak/data/demo_repository.dart';
import 'package:damanak/models/branch.dart';
import 'package:damanak/models/subscription.dart';
import 'package:damanak/screens/subscription_screen.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:damanak/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('يربط نموذج العرض المحلي كل باقة بقيمتها من دون منح صلاحيات', () {
    final starter = PlanInfo.fromJson({
      'id': 'starter',
      'name_ar': 'بداية',
      'monthly_price': 39,
      'yearly_price': 390,
      'max_members': 2,
      'monthly_warranties': 100,
      'monthly_ai_imports': 10,
      'max_branches': 1,
    });
    final growth = PlanInfo.fromJson({
      'id': 'growth',
      'name_ar': 'نمو',
      'monthly_price': 99,
      'yearly_price': 990,
      'max_members': 5,
      'monthly_warranties': 600,
      'monthly_ai_imports': 100,
      'max_branches': 3,
      'custom_branding': true,
    });
    final scale = PlanInfo.fromJson({
      'id': 'scale',
      'name_ar': 'توسع',
      'monthly_price': 199,
      'yearly_price': 1990,
      'max_members': 15,
      'monthly_warranties': 3000,
      'monthly_ai_imports': 500,
      'max_branches': 20,
      'custom_branding': true,
      'api_access': true,
      'webhook_access': true,
    });

    expect(starter.branchLabel, 'مناسب لفرع واحد');
    expect(starter.suggestedBranches, 1);
    expect(starter.features, contains('بطاقة ضمان رقمية برمز QR'));
    expect(starter.features, contains('رابط مشاركة آمن للضمان'));

    expect(growth.isRecommended, isTrue);
    expect(growth.suggestedBranches, 3);
    expect(growth.features, contains('فريق بأدوار مستقلة'));
    expect(growth.features, contains('الفروع والمخزون ونقطة البيع'));

    expect(scale.branchLabel, 'حتى 20 فرعاً');
    expect(scale.suggestedBranches, 20);
    expect(scale.features, contains('سجل نشاط للمالك والمدير'));
    expect(scale.features, contains('API بصلاحيات قابلة للتحديد'));
    expect(scale.features, contains('Webhooks موقعة للمطالبات'));

    final visibleFeatures = [
      ...starter.features,
      ...growth.features,
      ...scale.features,
    ].join(' ');
    for (final unavailableFeature in ['إصدار ضمانات بدفعات', 'دعم بأولوية']) {
      expect(visibleFeatures, isNot(contains(unavailableFeature)));
    }
  });

  test('يستخدم Demo الحصص الجديدة ويبقي حدود الفريق ثابتة', () async {
    final controller = AppController.unconfigured();
    addTearDown(controller.dispose);
    await controller.startDemo();

    expect(
      {
        for (final plan in controller.plans)
          plan.id: (plan.monthlyWarranties, plan.maxMembers),
      },
      {'starter': (100, 2), 'growth': (600, 5), 'scale': (3000, 15)},
    );
    expect(controller.subscription!.plan.monthlyWarranties, 600);
    expect(controller.subscription!.warrantyGraceAllowance, 60);
  });

  test('ترحيل الحصص idempotent ولا يغير الأسعار أو تحقق الاشتراك', () {
    final migration = File(
      'supabase/migrations/20260827120000_damanak_plan_value_quotas.sql',
    ).readAsStringSync();

    for (final token in [
      "when 'starter' then 100",
      "when 'growth' then 600",
      "when 'scale' then 3000",
      'create or replace function public.enforce_warranty_entitlement()',
      'public.subscription_is_usable(new.store_id)',
      'pg_catalog.pg_advisory_xact_lock',
      'voided_at is null',
      'included_limit::numeric * 0.10',
      "raise exception 'WARRANTY_LIMIT_REACHED'",
    ]) {
      expect(migration, contains(token));
    }

    expect(migration, isNot(contains('monthly_price')));
    expect(migration, isNot(contains('yearly_price')));
    expect(migration, isNot(contains('max_members =')));
    expect(migration, isNot(contains("interval '7 days'")));
  });

  test('المتجر الجديد يبدأ بتجربة بداية ويصحح التجارب الآمنة الحالية', () {
    final migration = File(
      'supabase/migrations/20260830130000_damanak_starter_trial_consistency.sql',
    ).readAsStringSync();

    expect(migration, contains("subscription.source = 'trial'"));
    expect(migration, contains("set plan_id = 'starter'"));
    expect(migration, contains("created_store_id,\n    'starter',"));
    expect(migration, contains("member.status = 'active'"));
    expect(migration, contains(') <= 2'));
    expect(migration, contains(') <= 100'));
    expect(migration, isNot(contains("created_store_id,\n    'growth',")));
  });

  testWidgets('تعرض الباقات الثلاث ومصدر السعر ومسارات الإدارة بوضوح', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final controller = AppController.unconfigured();
    addTearDown(controller.dispose);
    await controller.startDemo();

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: const DamanakAppFrame(home: SubscriptionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      Directionality.of(
        tester.element(
          find.byKey(const ValueKey('subscription-current-summary')),
        ),
      ),
      TextDirection.rtl,
    );
    expect(
      find.byKey(const ValueKey('subscription-restore-action')),
      findsOneWidget,
    );
    expect(find.text('باقتك الحالية'), findsOneWidget);
    expect(find.textContaining('تبقى الضمانات السابقة'), findsNothing);

    final scrollable = find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable && widget.axisDirection == AxisDirection.down,
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('subscription-plan-picker')),
      240,
      scrollable: scrollable,
    );
    expect(find.text('الباقات والترقية'), findsOneWidget);
    expect(find.textContaining('الأسعار والعملات من'), findsOneWidget);

    final picker = find.byKey(const ValueKey('subscription-plan-picker'));
    expect(picker, findsOneWidget);

    for (final (id, name, quota) in [
      ('starter', 'بداية', '100 ضمان شهرياً'),
      ('growth', 'نمو', '600 ضمان شهرياً'),
      ('scale', 'توسع', '3000 ضمان شهرياً'),
    ]) {
      final tile = find.byKey(ValueKey('subscription-plan-$id'));
      expect(tile, findsOneWidget);
      expect(
        find.descendant(of: tile, matching: find.text(name)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: tile, matching: find.text(quota)),
        findsOneWidget,
      );
    }
    expect(find.text('موصى بها'), findsNothing);
    expect(find.text('السعر غير متاح'), findsWidgets);
    expect(find.text('39'), findsNothing);
    expect(
      find.byKey(const ValueKey('subscription-primary-action')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('تبقى شاشة الباقات سليمة عند 320×568 وتكبير النص 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final controller = AppController.unconfigured();
    addTearDown(controller.dispose);
    await controller.startDemo();

    await tester.pumpWidget(
      AppScope(
        controller: controller,
        child: const DamanakAppFrame(home: SubscriptionScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('subscription-primary-action')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('subscription-restore-action')),
      findsOneWidget,
    );
    expect(
      Directionality.of(
        tester.element(
          find.byKey(const ValueKey('subscription-primary-action')),
        ),
      ),
      TextDirection.rtl,
    );
    final scrollable = find.byType(Scrollable).first;
    for (var attempt = 0; attempt < 12; attempt++) {
      if (find
          .byKey(const ValueKey('subscription-plan-scale'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.drag(scrollable, const Offset(0, -180));
      await tester.pump();
    }
    for (final id in ['starter', 'growth', 'scale']) {
      expect(find.byKey(ValueKey('subscription-plan-$id')), findsOneWidget);
    }
    expect(tester.takeException(), isNull);

    final scaleTile = find.byKey(const ValueKey('subscription-plan-scale'));
    await tester.scrollUntilVisible(scaleTile, 160, scrollable: scrollable);
    await tester.pump();
    final scaleTileRect = tester.getRect(scaleTile);
    expect(scaleTileRect.top, lessThan(tester.view.physicalSize.height));
    expect(scaleTileRect.bottom, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('يوجه المتجر المنشأ بلا تجربة إلى الاشتراك ويقيّد مسار الحساب', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final repository = _InactiveStoreRepository();
    final controller = AppController.withRepository(repository);
    addTearDown(controller.dispose);
    await controller.initialize();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('تفعيل المتجر'), findsOneWidget);
    expect(find.text('ابدأ باشتراك مدفوع'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('لا توجد باقة مفعّلة'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('لا توجد باقة مفعّلة'), findsOneWidget);
    expect(find.textContaining('اختر باقة أدناه'), findsOneWidget);
    expect(find.textContaining('0 ضمان'), findsNothing);
    expect(find.byTooltip('الحساب'), findsOneWidget);
    expect(find.text('الرئيسية'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('الحساب'));
    await tester.pumpAndSettle();

    expect(find.text('بيانات الحساب'), findsOneWidget);
    expect(find.text('محمد صاحب المتجر'), findsOneWidget);
    expect(find.text('owner@demo.damanak.app'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.text('المنتجات'), findsNothing);
    expect(find.text('الفريق والصلاحيات'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('تسجيل الخروج'),
      160,
      scrollable: find.byType(Scrollable).first,
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.platformDispatcher.textScaleFactorTestValue = 1;
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();

    expect(repository.signOutCalls, 1);
    expect(find.text('الدخول إلى ضمانك'), findsOneWidget);
    expect(find.text('تفعيل المتجر'), findsNothing);
  });

  testWidgets('يفرغ مسار الحساب قبل انتظار الحذف', (tester) async {
    final deletion = Completer<void>();
    final repository = _InactiveStoreRepository(deleteCompleter: deletion);
    final controller = AppController.withRepository(repository);
    addTearDown(controller.dispose);
    await controller.initialize();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('الحساب'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('حذف الحساب نهائياً'));
    await tester.tap(find.text('حذف الحساب نهائياً'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('حذف حساب ضمانك لا يلغي أي اشتراك قائم'),
      findsOneWidget,
    );
    await tester.tap(find.text('حذف نهائي'));
    await tester.pumpAndSettle();

    expect(repository.deleteAccountCalls, 1);
    expect(find.text('بيانات الحساب'), findsNothing);
    expect(find.text('تفعيل المتجر'), findsOneWidget);

    deletion.complete();
    await tester.pumpAndSettle();
    expect(find.text('الدخول إلى ضمانك'), findsOneWidget);
  });

  testWidgets('لا يحجب التطبيق لتجربة منتهية ذات تاريخ معروف', (tester) async {
    final controller = AppController.withRepository(
      _InactiveStoreRepository(expiredTrial: true),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('تفعيل المتجر'), findsNothing);
  });

  testWidgets('يبقي إيصال متجر غير فعال بلا فرع خلف البوابة', (tester) async {
    final controller = AppController.withRepository(
      _InactiveStoreRepository(inactiveStoreReceipt: true),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    expect(controller.subscription!.isAwaitingSubscription, isFalse);
    expect(controller.subscription!.isUsable, isFalse);
    expect(controller.branches, isEmpty);

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('تفعيل المتجر'), findsOneWidget);
    expect(find.text('ابدأ باشتراك مدفوع'), findsOneWidget);
    expect(find.text('الرئيسية'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('لا توجد باقة مفعّلة'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('ابدأ باشتراك مدفوع'), findsOneWidget);
    expect(find.textContaining('ضماناتك السابقة محفوظة'), findsOneWidget);
    expect(find.textContaining('0 ضمان'), findsNothing);
    expect(find.text('الخطة الحالية'), findsNothing);
  });
}

class _InactiveStoreRepository extends DemoDamanakRepository {
  _InactiveStoreRepository({
    this.expiredTrial = false,
    this.inactiveStoreReceipt = false,
    this.deleteCompleter,
  });

  final bool expiredTrial;
  final bool inactiveStoreReceipt;
  final Completer<void>? deleteCompleter;
  int signOutCalls = 0;
  int deleteAccountCalls = 0;

  @override
  bool get isDemo => false;

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
  }

  @override
  Future<void> deleteAccount() {
    deleteAccountCalls += 1;
    return deleteCompleter?.future ?? Future<void>.value();
  }

  @override
  Future<List<StoreBranch>> loadBranches(String storeId) {
    if (inactiveStoreReceipt) return Future.value(const <StoreBranch>[]);
    return super.loadBranches(storeId);
  }

  @override
  Future<WorkspaceSnapshot?> loadWorkspace() async {
    final snapshot = await super.loadWorkspace();
    return WorkspaceSnapshot(
      store: snapshot!.store,
      membership: snapshot.membership,
      subscription: SubscriptionInfo(
        id: 'inactive-subscription',
        status: 'canceled',
        plan: snapshot.subscription.plan,
        trialEndsAt: expiredTrial
            ? DateTime.now().subtract(const Duration(days: 1))
            : null,
        periodEndsAt: null,
        usedWarranties: 0,
        source: inactiveStoreReceipt ? 'store' : 'trial',
        billingProvider: inactiveStoreReceipt ? 'app_store' : null,
        storeProductId: inactiveStoreReceipt
            ? 'com.damanak.subscription.starter.monthly'
            : null,
      ),
    );
  }
}
