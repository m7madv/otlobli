import 'package:damanak/app.dart';
import 'package:damanak/data/local_repository.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('تظهر الصفحة الرئيسية العربية', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = AppController(LocalRepository());
    await controller.initialize();

    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('ضمانك'), findsOneWidget);
    expect(find.text('إنشاء ضمان جديد'), findsOneWidget);
    expect(find.text('أحدث الضمانات'), findsOneWidget);
  });
}
