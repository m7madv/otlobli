import 'package:damanak/core/app_theme.dart';
import 'package:damanak/models/account.dart';
import 'package:damanak/screens/auth_screen.dart';
import 'package:damanak/screens/onboarding_screen.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:damanak/state/app_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('تعرض شاشة الدخول Apple وGoogle فقط', (tester) async {
    final controller = AppController.unconfigured();

    await tester.pumpWidget(_screen(controller, const AuthScreen()));
    await tester.pumpAndSettle();

    expect(find.text('المتابعة باستخدام Apple'), findsOneWidget);
    expect(find.text('المتابعة باستخدام Google'), findsOneWidget);
    expect(find.text('البريد الإلكتروني'), findsNothing);
    expect(find.text('كلمة المرور'), findsNothing);
    expect(find.text('نسيت كلمة المرور؟'), findsNothing);
  });

  testWidgets('يحفظ رابط الدعوة ويجهز نموذج الانضمام', (tester) async {
    final controller = AppController.unconfigured();
    final handled = controller.handleIncomingUri(
      Uri.parse('com.damanak.damanak://join?code=DMN-7K4P9Q&role=staff'),
    );

    expect(handled, isTrue);
    expect(controller.pendingInvitationCode, 'DMN-7K4P9Q');
    expect(controller.pendingInvitationRole, MemberRole.staff);

    await tester.pumpWidget(_screen(controller, const OnboardingScreen()));
    await tester.pumpAndSettle();

    expect(find.text('رمز دعوة الفريق'), findsOneWidget);
    expect(
      find.text('تم تحميل الدعوة. صلاحيتك بعد الانضمام: موظف.'),
      findsOneWidget,
    );
    expect(find.text('DMN-7K4P9Q'), findsWidgets);
    expect(find.text('تأكيد الانضمام'), findsOneWidget);
  });

  test('ينشئ رابط دعوة يتضمن الرمز والصلاحية', () {
    final invite = StoreInvite(
      code: 'DMN-ABC123',
      role: MemberRole.manager,
      expiresAt: DateTime(2026, 8, 26),
      maxUses: 1,
    );

    expect(invite.deepLink.scheme, 'com.damanak.damanak');
    expect(invite.deepLink.host, 'join');
    expect(invite.deepLink.queryParameters['code'], 'DMN-ABC123');
    expect(invite.deepLink.queryParameters['role'], 'manager');
  });
}

Widget _screen(AppController controller, Widget child) {
  return AppScope(
    controller: controller,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: Directionality(textDirection: TextDirection.rtl, child: child),
    ),
  );
}
