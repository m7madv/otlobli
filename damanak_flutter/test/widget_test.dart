import 'package:damanak/app.dart';
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

  testWidgets('يفتح التطبيق مباشرة على مسار البيع المبسط', (tester) async {
    final controller = AppController.unconfigured();
    await controller.startDemo();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('بيع'), findsWidgets);
    expect(find.text('اسم المنتج أو الباركود…'), findsOneWidget);
    expect(find.text('المنتجات'), findsOneWidget);
    expect(find.text('المزيد'), findsOneWidget);
  });

  testWidgets('يتيح مسح الرقم التسلسلي أو كتابته عند إضافة قطعة', (
    tester,
  ) async {
    final controller = AppController.unconfigured();
    await controller.startDemo();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();

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
    final addProduct = find.byTooltip('إضافة ماكينة قهوة منزلية');
    await tester.ensureVisible(addProduct);
    await tester.pumpAndSettle();
    await tester.tap(addProduct);
    await tester.pumpAndSettle();

    expect(find.text('مسح الرقم التسلسلي'), findsOneWidget);
    expect(find.text('إضافة الرقم للسلة'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
