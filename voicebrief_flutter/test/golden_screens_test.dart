@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/app/app_controller.dart';
import 'package:voicebrief/app/config/app_config.dart';
import 'package:voicebrief/features/auth/presentation/auth_screen.dart';
import 'package:voicebrief/features/home/presentation/shell_screen.dart';
import 'package:voicebrief/features/recorder/presentation/recorder_screen.dart';
import 'package:voicebrief/features/reminders/presentation/scheduled_reminders_screen.dart';
import 'package:voicebrief/features/settings/presentation/settings_screen.dart';
import 'package:voicebrief/features/subscription/presentation/paywall_screen.dart';
import 'package:voicebrief/features/transcription/presentation/result_screen.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';

import 'helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadTestFonts);

  Future<void> golden(
    WidgetTester tester, {
    required String name,
    required Widget screen,
    required AppControllerFactory controllerFactory,
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1,
    Locale locale = const Locale('en'),
    AppConfig config = testConfig,
  }) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = await controllerFactory();
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('golden'),
        child: testApp(
          controller: controller,
          home: screen,
          themeMode: themeMode,
          textScale: textScale,
          locale: locale,
          config: config,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('golden')),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('light authentication', (tester) async {
    await golden(
      tester,
      name: 'auth_light',
      screen: const AuthScreen(),
      controllerFactory: () async => createTestController(),
      config: providerReadyTestConfig,
    );
  });

  testWidgets('dark authentication', (tester) async {
    await golden(
      tester,
      name: 'auth_dark',
      screen: const AuthScreen(),
      themeMode: ThemeMode.dark,
      controllerFactory: () async => createTestController(),
      config: providerReadyTestConfig,
    );
  });

  testWidgets('Arabic authentication providers', (tester) async {
    await golden(
      tester,
      name: 'auth_ar',
      screen: const AuthScreen(),
      locale: const Locale('ar'),
      controllerFactory: () async => createTestController(),
      config: providerReadyTestConfig,
    );
  });

  testWidgets('light home', (tester) async {
    await golden(
      tester,
      name: 'home_light',
      screen: const ShellScreen(),
      controllerFactory: signedInController,
    );
  });

  testWidgets('dark home', (tester) async {
    await golden(
      tester,
      name: 'home_dark',
      screen: const ShellScreen(),
      themeMode: ThemeMode.dark,
      controllerFactory: signedInController,
    );
  });

  testWidgets('processing', (tester) async {
    await golden(
      tester,
      name: 'processing',
      screen: const Scaffold(
        body: Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: ProcessingStepIndicator(
              current: ProcessingStep.transcribing,
            ),
          ),
        ),
      ),
      controllerFactory: signedInController,
    );
  });

  testWidgets('result', (tester) async {
    await golden(
      tester,
      name: 'result',
      screen: const ResultScreen(),
      controllerFactory: () async {
        final controller = await signedInController();
        controller.openResult(sampleResult());
        return controller;
      },
    );
  });

  testWidgets('paywall', (tester) async {
    await golden(
      tester,
      name: 'paywall',
      screen: const PaywallScreen(),
      controllerFactory: signedInController,
    );
  });

  testWidgets('accessibility large text', (tester) async {
    await golden(
      tester,
      name: 'home_large_text',
      screen: const ShellScreen(),
      textScale: 1.6,
      controllerFactory: signedInController,
    );
  });

  testWidgets('Arabic settings empty text state', (tester) async {
    await golden(
      tester,
      name: 'settings_ar',
      screen: const Scaffold(body: SettingsScreen()),
      locale: const Locale('ar'),
      controllerFactory: signedInController,
    );
  });

  testWidgets('Arabic recorder idle state', (tester) async {
    await golden(
      tester,
      name: 'recorder_ar',
      screen: const RecorderScreen(),
      locale: const Locale('ar'),
      controllerFactory: signedInController,
    );
  });

  testWidgets('Arabic alarms empty state', (tester) async {
    const channel = MethodChannel('voicebrief/reminders');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'list') return <Object>[];
          if (call.method == 'getPreferredTone') {
            return {'soundKey': 'system'};
          }
          return false;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    await golden(
      tester,
      name: 'alarms_ar',
      screen: const ScheduledRemindersScreen(),
      locale: const Locale('ar'),
      themeMode: ThemeMode.dark,
      controllerFactory: signedInController,
    );
  });
}

typedef AppControllerFactory = Future<AppController> Function();

Future<AppController> signedInController() async {
  final controller = createTestController();
  await controller.signInWithProvider(IdentityProvider.google);
  return controller;
}
