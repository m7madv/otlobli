import 'package:damanak/app.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
