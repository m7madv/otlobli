import 'package:damanak/app.dart';
import 'package:damanak/screens/product_import_screen.dart';
import 'package:damanak/screens/startup_screen.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('يعرض هوية الإقلاع فوراً بدلاً من شاشة بيضاء', (tester) async {
    await tester.pumpWidget(const DamanakAppFrame(home: StartupScreen()));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFF087F5B));
    expect(find.text('ضمانك'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('يعرض مسار استعادة واضحاً إذا تعذرت التهيئة', (tester) async {
    await tester.pumpWidget(
      DamanakAppFrame(
        home: StartupScreen(
          errorMessage: 'تعذّر تجهيز التطبيق.',
          onRetry: () {},
        ),
      ),
    );

    expect(find.text('تعذّر تجهيز التطبيق.'), findsOneWidget);
    expect(find.text('إعادة المحاولة'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('يفتح التطبيق على مسار الضمان ويعرض الوجهات الرئيسية', (
    tester,
  ) async {
    final controller = AppController.unconfigured();
    await controller.startDemo();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الضمانات'), findsOneWidget);
    expect(find.text('المطالبات'), findsOneWidget);
    expect(find.text('الإدارة'), findsOneWidget);
    expect(find.byKey(const ValueKey('home-scan-warranty')), findsOneWidget);
    expect(find.byKey(const ValueKey('home-manual-warranty')), findsOneWidget);
    expect(find.text('مطالبات الضمان الحديثة'), findsOneWidget);
  });

  testWidgets('يبحث في الضمانات بالهاتف ويعرض فلاتر الحالة', (tester) async {
    final controller = AppController.unconfigured();
    await controller.startDemo();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.text('الضمانات'));
    await tester.pumpAndSettle();

    expect(find.text('رقم الجوال أو التسلسلي أو رقم الضمان'), findsOneWidget);
    expect(find.textContaining('ساري'), findsWidgets);
    expect(find.textContaining('قريب'), findsOneWidget);
    expect(find.textContaining('منتهي'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('warranties-create-button')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('warranty-search-field')),
      '0550007788',
    );
    await tester.pump();

    expect(find.text('أحمد خالد'), findsOneWidget);
    expect(find.text('سارة العتيبي'), findsNothing);
  });

  testWidgets('يبقي نموذج الضمان مختصراً ويطوي التفاصيل الاختيارية', (
    tester,
  ) async {
    final controller = AppController.unconfigured();
    await controller.startDemo();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('home-manual-warranty')));
    await tester.pumpAndSettle();

    expect(find.text('المنتج'), findsOneWidget);
    expect(find.text('العميل'), findsOneWidget);
    expect(find.text('مدة الضمان'), findsWidgets);
    expect(find.byTooltip('مسح الباركود'), findsOneWidget);
    expect(find.byTooltip('مسح الرقم التسلسلي'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsNothing);
    expect(find.text('سعر البيع'), findsNothing);

    final optionalToggle = find.byKey(
      const ValueKey('optional-warranty-details-toggle'),
    );
    await tester.ensureVisible(optionalToggle);
    await tester.tap(optionalToggle);
    await tester.pumpAndSettle();

    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('سعر البيع'), findsOneWidget);
    expect(find.text('رقم الإيصال'), findsOneWidget);
  });

  testWidgets('يبقى مسار إصدار الضمان قابلاً للاستخدام عند 320×568 و200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final controller = AppController.unconfigured();
    await controller.startDemo();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    final manualWarranty = find.byKey(const ValueKey('home-manual-warranty'));
    await tester.ensureVisible(manualWarranty);
    await tester.pumpAndSettle();
    await tester.tap(manualWarranty);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('warranty-product-name')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('warranty-customer-name')),
      findsOneWidget,
    );
    final issueButton = find.byKey(const ValueKey('issue-warranty-button'));
    await tester.ensureVisible(issueButton);
    await tester.pumpAndSettle();
    expect(issueButton, findsOneWidget);
  });

  testWidgets('يتيح مسح الرقم التسلسلي أو كتابته عند إضافة قطعة', (
    tester,
  ) async {
    final controller = AppController.unconfigured();
    await controller.startDemo();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();

    await _openPointOfSale(tester);

    await tester.tap(find.byTooltip('إضافة ماكينة قهوة منزلية'));
    await tester.pumpAndSettle();

    expect(find.text('رقم القطعة'), findsOneWidget);
    expect(find.text('مسح الرقم التسلسلي'), findsOneWidget);
    expect(find.text('أو اكتبه يدوياً'), findsOneWidget);
    expect(find.text('إضافة الرقم للسلة'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, 'الرقم التسلسلي'),
      'SN-TEST-001',
    );
    await tester.tap(find.text('إضافة الرقم للسلة'));
    await tester.pumpAndSettle();

    expect(find.text('مراجعة وإتمام البيع'), findsOneWidget);

    await tester.tap(find.byTooltip('زيادة الكمية'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'الرقم التسلسلي'),
      'sn-test-001',
    );
    await tester.tap(find.text('إضافة الرقم للسلة'));
    await tester.pumpAndSettle();

    expect(find.text('هذا الرقم موجود في السلة بالفعل.'), findsOneWidget);
  });

  testWidgets('تبقى نافذة الرقم التسلسلي قابلة للاستخدام مع تكبير 200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final controller = AppController.unconfigured();
    await controller.startDemo();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();
    await _openPointOfSale(tester);
    final addProduct = find.byTooltip('إضافة ماكينة قهوة منزلية');
    await tester.ensureVisible(addProduct);
    await tester.pumpAndSettle();
    await tester.tap(addProduct);
    await tester.pumpAndSettle();

    expect(find.text('مسح الرقم التسلسلي'), findsOneWidget);
    expect(find.text('إضافة الرقم للسلة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('يبقى مركز المطالبات قابلاً للاستخدام عند 320×568 و200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final controller = AppController.unconfigured();
    await controller.startDemo();
    await controller.addMaintenanceRequest(
      warrantyId: controller.warranties.first.id,
      issue: 'الجهاز لا يعمل بعد التشغيل',
    );

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المطالبات'));
    await tester.pumpAndSettle();

    expect(find.text('مركز المطالبات'), findsOneWidget);
    expect(find.text('نطاق العمل'), findsOneWidget);
    expect(find.text('1 مطالبة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('تبقى تقارير الضمان قابلة للقراءة عند 320×568 و200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final controller = AppController.unconfigured();
    await controller.startDemo();
    await controller.addMaintenanceRequest(
      warrantyId: controller.warranties.first.id,
      issue: 'البطارية لا تشحن',
    );

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإدارة'));
    await tester.pumpAndSettle();
    final reports = find.ancestor(
      of: find.text('أداء الضمان'),
      matching: find.byType(ListTile),
    );
    await tester.ensureVisible(reports);
    await tester.pumpAndSettle();
    await tester.tap(reports);
    await tester.pumpAndSettle();

    expect(find.text('صحة خدمة ما بعد البيع'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('أسباب المطالبات'),
      240,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('أسباب المطالبات'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('تبقى خيارات استيراد المنتجات واضحة عند 320×568 و200%', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const DamanakAppFrame(home: ProductImportScreen()));
    await tester.pumpAndSettle();

    expect(find.text('استيراد المنتجات'), findsOneWidget);
    expect(find.text('اختيار ملف CSV'), findsOneWidget);
    expect(find.text('تحليل PDF أو صورة'), findsOneWidget);
    expect(find.text('قالب جاهز'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _openPointOfSale(WidgetTester tester) async {
  await tester.tap(find.text('الإدارة'));
  await tester.pumpAndSettle();
  await tester.scrollUntilVisible(
    find.text('نقطة البيع'),
    220,
    scrollable: find.byType(Scrollable).last,
  );
  final pointOfSale = find.ancestor(
    of: find.text('نقطة البيع'),
    matching: find.byType(ListTile),
  );
  await tester.ensureVisible(pointOfSale);
  await tester.pumpAndSettle();
  await tester.tap(pointOfSale);
  await tester.pumpAndSettle();
}
