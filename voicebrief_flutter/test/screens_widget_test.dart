import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/features/auth/presentation/auth_screen.dart';
import 'package:voicebrief/features/history/presentation/history_screen.dart';
import 'package:voicebrief/features/home/presentation/home_screen.dart';
import 'package:voicebrief/features/settings/presentation/settings_screen.dart';
import 'package:voicebrief/features/subscription/presentation/paywall_screen.dart';
import 'package:voicebrief/features/transcription/presentation/result_screen.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';

import 'helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('authentication exposes provider and email paths', (
    tester,
  ) async {
    final controller = createTestController();
    await tester.pumpWidget(
      testApp(controller: controller, home: const AuthScreen()),
    );
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  testWidgets('home presents direct sharing, import, record, and empty state', (
    tester,
  ) async {
    final controller = createTestController();
    await controller.signInWithEmail('owner@example.com', 'a-secure-password');
    await tester.pumpWidget(
      testApp(controller: controller, home: const HomeScreen()),
    );
    await tester.pump();
    expect(find.text('From WhatsApp'), findsOneWidget);
    expect(find.text('Choose a voice note'), findsOneWidget);
    expect(find.text('Record instead'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('No briefs yet'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No briefs yet'), findsOneWidget);
    expect(find.byType(AppUsageIndicator), findsOneWidget);
  });

  testWidgets('Arabic system locale localizes and mirrors the home screen', (
    tester,
  ) async {
    final controller = createTestController();
    await controller.signInWithEmail('owner@example.com', 'a-secure-password');
    await tester.pumpWidget(
      testApp(
        controller: controller,
        home: const HomeScreen(),
        locale: const Locale('ar'),
      ),
    );
    await tester.pump();

    expect(find.text('حوّل الرسائل الصوتية إلى خطوات واضحة'), findsOneWidget);
    expect(find.text('متبقي 10 من أصل 10 دقائق مجانية'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(HomeScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('Arabic empty history stays centered on a narrow screen', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 740));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = createTestController();
    await controller.signInWithEmail('owner@example.com', 'a-secure-password');
    await tester.pumpWidget(
      testApp(
        controller: controller,
        home: const Scaffold(body: HistoryScreen()),
        locale: const Locale('ar'),
      ),
    );
    await tester.pump();

    final screenRect = tester.getRect(find.byType(HistoryScreen));
    final titleRect = tester.getRect(find.text('لا يوجد شيء محفوظ بعد'));
    final messageRect = tester.getRect(
      find.text('احفظ النتيجة عندما تريد ظهورها هنا.'),
    );
    expect(titleRect.center.dx, closeTo(screenRect.center.dx, 1));
    expect(messageRect.center.dx, closeTo(screenRect.center.dx, 1));
    expect(titleRect.left, greaterThanOrEqualTo(screenRect.left));
    expect(titleRect.right, lessThanOrEqualTo(screenRect.right));
    expect(messageRect.left, greaterThanOrEqualTo(screenRect.left));
    expect(messageRect.right, lessThanOrEqualTo(screenRect.right));
  });

  testWidgets('swiping a saved brief removes it immediately and offers undo', (
    tester,
  ) async {
    final controller = createTestController();
    await controller.signInWithEmail('owner@example.com', 'a-secure-password');
    controller.openResult(sampleResult());
    await controller.saveActiveResult();
    await tester.pumpWidget(
      testApp(
        controller: controller,
        home: const Scaffold(body: HistoryScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Project launch follow-up'), findsOneWidget);

    await tester.drag(
      find.text('Project launch follow-up'),
      const Offset(-500, 0),
    );
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Project launch follow-up'), findsNothing);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('result separates generated text from the transcript', (
    tester,
  ) async {
    final controller = createTestController(pro: true);
    await controller.signInWithEmail('owner@example.com', 'a-secure-password');
    controller.openResult(sampleResult());
    await tester.pumpWidget(
      testApp(controller: controller, home: const ResultScreen()),
    );
    expect(find.text('Brief'), findsWidgets);
    expect(find.text('Key points'), findsOneWidget);
    expect(find.textContaining('dates found'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Word-for-word transcript'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Word-for-word transcript'), findsOneWidget);
    await tester.tap(find.text('Word-for-word transcript'));
    await tester.pumpAndSettle();
    expect(
      find.text('Maya will send the proposal before Thursday.'),
      findsOneWidget,
    );
  });

  testWidgets('paywall uses store options and annual selection', (
    tester,
  ) async {
    final controller = createTestController();
    await controller.signInWithEmail('owner@example.com', 'a-secure-password');
    await tester.pumpWidget(
      testApp(controller: controller, home: const PaywallScreen()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Yearly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.textContaining('SAVE 34%'), findsOneWidget);
    final selected = tester.widget<SubscriptionOptionTile>(
      find.widgetWithText(SubscriptionOptionTile, 'Yearly'),
    );
    expect(selected.selected, isTrue);
  });

  testWidgets('empty saved-text actions explain why there is nothing to do', (
    tester,
  ) async {
    final controller = createTestController();
    await controller.signInWithEmail('owner@example.com', 'a-secure-password');
    await tester.pumpWidget(
      testApp(
        controller: controller,
        home: const Scaffold(body: SettingsScreen()),
      ),
    );
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('Share saved text'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.text('There is no saved text on this device.'), findsWidgets);
    await tester.tap(find.text('Share saved text'));
    await tester.pump();
    expect(find.text('There is no saved text on this device.'), findsWidgets);
  });

  testWidgets('large text error state remains usable in dark mode', (
    tester,
  ) async {
    final controller = createTestController();
    await tester.pumpWidget(
      testApp(
        controller: controller,
        themeMode: ThemeMode.dark,
        textScale: 2,
        home: const AppErrorView(
          message: 'The service is temporarily unavailable.',
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(
      find.text('The service is temporarily unavailable.'),
      findsOneWidget,
    );
  });
}
