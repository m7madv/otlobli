import 'package:damanak/app.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('تظهر الصفحة الرئيسية العربية', (tester) async {
    final controller = AppController.unconfigured();
    await controller.startDemo();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('ضمانك'), findsOneWidget);
    expect(find.text('امسح. طابِق. أصدر.'), findsOneWidget);
    expect(find.text('آخر الضمانات'), findsOneWidget);
  });
}
