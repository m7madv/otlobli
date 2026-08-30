import 'dart:io';

import 'package:damanak/app.dart';
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
    });
    final growth = PlanInfo.fromJson({
      'id': 'growth',
      'name_ar': 'نمو',
      'monthly_price': 99,
      'yearly_price': 990,
      'max_members': 5,
      'monthly_warranties': 600,
    });
    final scale = PlanInfo.fromJson({
      'id': 'scale',
      'name_ar': 'توسع',
      'monthly_price': 199,
      'yearly_price': 1990,
      'max_members': 15,
      'monthly_warranties': 3000,
    });

    expect(starter.branchLabel, 'مناسب لفرع واحد');
    expect(starter.suggestedBranches, 1);
    expect(starter.features, contains('بطاقة ضمان رقمية برمز QR'));
    expect(starter.features, contains('رابط مشاركة آمن للضمان'));

    expect(growth.isRecommended, isTrue);
    expect(growth.suggestedBranches, 3);
    expect(growth.features, contains('فريق بأدوار مستقلة'));
    expect(growth.features, contains('الفروع والمخزون ونقطة البيع'));

    expect(scale.branchLabel, 'مناسب لفروع متعددة');
    expect(scale.suggestedBranches, isNull);
    expect(scale.features, contains('سجل نشاط للمالك والمدير'));
    expect(scale.features, contains('الموردون وأوامر الشراء'));

    final visibleFeatures = [
      ...starter.features,
      ...growth.features,
      ...scale.features,
    ].join(' ');
    for (final unavailableFeature in [
      'صور ومرفقات',
      'تعيين مسؤول',
      'تنبيهات',
      'إصدار ضمانات بدفعات',
      'API',
      'دعم بأولوية',
    ]) {
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

  testWidgets('تعرض مقارنة الباقات ومصدر السعر ومسارات الإدارة بوضوح', (
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

    expect(find.text('استعادة المشتريات'), findsOneWidget);
    expect(find.textContaining('تبقى الضمانات السابقة'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('قارن الباقات'),
      240,
      scrollable: scrollable,
    );
    expect(find.text('قارن الباقات'), findsOneWidget);
    expect(find.textContaining('السعر والعملة النهائيان'), findsOneWidget);

    final picker = find.byKey(const ValueKey('subscription-plan-picker'));
    await tester.scrollUntilVisible(picker, 240, scrollable: scrollable);
    expect(picker, findsOneWidget);

    for (final (id, name, quota) in [
      ('starter', 'بداية', '100 ضمان/شهر'),
      ('growth', 'نمو', '600 ضمان/شهر'),
      ('scale', 'توسع', '3000 ضمان/شهر'),
    ]) {
      await tester.tap(find.descendant(of: picker, matching: find.text(name)));
      await tester.pump();
      expect(find.byKey(ValueKey('subscription-plan-$id')), findsOneWidget);
      expect(find.text(quota), findsOneWidget);
      if (id == 'growth') {
        expect(find.text('موصى بها'), findsOneWidget);
      }
    }
    expect(find.text('بانتظار سعر المتجر'), findsOneWidget);
    expect(find.text('39'), findsNothing);
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

    expect(find.text('استعادة المشتريات'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('قارن الباقات'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('قارن الباقات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
