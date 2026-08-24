import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:voicebrief/app/app.dart';
import 'package:voicebrief/app/providers.dart';

import '../test/helpers/test_harness.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('onboarding, mock sign-in, and local account deletion', (
    tester,
  ) async {
    final controller = createTestController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith((_) => controller),
          appConfigProvider.overrideWithValue(testConfig),
        ],
        child: const VoiceBriefApp(),
      ),
    );

    expect(find.text('Turn voice into clarity'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Make every voice message useful'), findsOneWidget);
    await tester.tap(find.text('Sign in').last);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('From voice note to clear next steps'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Delete account'),
      500,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Delete account'), findsOneWidget);
    await controller.deleteAccount();
    await tester.pumpAndSettle();
    expect(controller.state.user, isNull);
  });
}
