import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voicebrief/app/app.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/core/storage/app_preferences.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/features/auth/presentation/auth_screen.dart';
import 'package:voicebrief/features/home/presentation/home_screen.dart';
import 'package:voicebrief/features/settings/presentation/settings_screen.dart';
import 'package:voicebrief/features/transcription/presentation/result_screen.dart';
import 'package:voicebrief/l10n/app_languages.dart';
import 'package:voicebrief/l10n/app_localizations.dart';

import 'helpers/test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadTestFonts);

  test('all 11 catalogs contain every message and placeholder', () {
    final base =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    final keys = base.keys
        .cast<String>()
        .where((key) => !key.startsWith('@'))
        .toSet();
    expect(
      AppLocalizations.supportedLocales.map((l) => l.languageCode).toSet(),
      AppLanguages.names.keys.toSet(),
    );
    for (final code in AppLanguages.names.keys) {
      final catalog =
          jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync()) as Map;
      expect(
        catalog.keys
            .cast<String>()
            .where((key) => !key.startsWith('@'))
            .toSet(),
        keys,
        reason: code,
      );
      for (final key in keys) {
        final message = catalog[key] as String;
        expect(message.trim(), isNotEmpty, reason: '$code.$key');
        for (final match in RegExp(
          r'\{([a-zA-Z]\w*)(?:\}|,)',
        ).allMatches(base[key] as String)) {
          expect(
            message.contains('{${match[1]}'),
            isTrue,
            reason: '$code.$key missing ${match[1]}',
          );
        }
      }
      final nativeCode = code == 'zh' ? 'zh-Hans' : code;
      for (final file in ['Localizable', 'InfoPlist']) {
        final source = File(
          'ios/Localization/en.lproj/$file.strings',
        ).readAsStringSync();
        final target = File(
          'ios/Localization/$nativeCode.lproj/$file.strings',
        ).readAsStringSync();
        Set<String> nativeKeys(String text) => RegExp(
          r'^"(.+)" = ',
          multiLine: true,
        ).allMatches(text).map((m) => m[1]!).toSet();
        expect(
          nativeKeys(target),
          nativeKeys(source),
          reason: '$code native $file',
        );
      }
    }
  });

  test('locale resolution respects preference order and safely falls back', () {
    final supported = AppLocalizations.supportedLocales;
    expect(
      AppLanguages.resolve([const Locale('en'), const Locale('ar')], supported),
      const Locale('en'),
    );
    expect(
      AppLanguages.resolve([
        const Locale('es', 'MX'),
        const Locale('ar'),
      ], supported),
      const Locale('es'),
    );
    expect(
      AppLanguages.resolve([const Locale('de'), const Locale('ur')], supported),
      const Locale('ur'),
    );
    expect(
      AppLanguages.resolve([
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ], supported).languageCode,
      'zh',
    );
    expect(
      AppLanguages.resolve([
        const Locale('zh', 'TW'),
        const Locale('fr'),
      ], supported),
      const Locale('fr'),
    );
    expect(
      AppLanguages.resolve([const Locale('xx')], supported),
      const Locale('en'),
    );
    expect(AppLanguages.resolve(null, supported), const Locale('en'));
  });

  test(
    'language survives restart, sign-out, and does not reset quota or theme',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await DeviceAppPreferences.load();
      await preferences.setThemeMode(ThemeMode.light);
      final controller = createTestController(preferences: preferences);
      await controller.signInWithProvider(IdentityProvider.google);
      final before = controller.state.subscription;
      expect(await controller.setLanguageCode('ur'), isTrue);
      expect(controller.state.subscription, before);
      await controller.signOut();
      expect(controller.state.languageCode, 'ur');
      controller.dispose();
      final restored = createTestController(
        preferences: await DeviceAppPreferences.load(),
      );
      expect(restored.state.languageCode, 'ur');
      expect(restored.state.themeMode, ThemeMode.light);
      expect(await restored.setLanguageCode('invalid'), isFalse);
      expect(restored.state.languageCode, 'ur');
      expect(await restored.setLanguageCode(null), isTrue);
      expect((await DeviceAppPreferences.load()).languageCode, isNull);
      restored.dispose();
    },
  );

  testWidgets(
    'settings switches the real app immediately and can return to system',
    (tester) async {
      tester.platformDispatcher.localesTestValue = [
        const Locale('en'),
        const Locale('ar'),
      ];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
      final controller = createTestController();
      await controller.signInWithProvider(IdentityProvider.google);
      controller.setNavigationIndex(2);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appControllerProvider.overrideWith((_) => controller),
            appConfigProvider.overrideWithValue(testConfig),
          ],
          child: const VoiceBriefApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('App language'));
      await tester.tap(find.text('App language'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Français'));
      await tester.pumpAndSettle();
      expect(controller.state.languageCode, 'fr');
      expect(find.text('Langue de l’application'), findsOneWidget);
      await tester.tap(find.text('Langue de l’application'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Utiliser la langue de l’appareil'));
      await tester.pumpAndSettle();
      expect(controller.state.languageCode, isNull);
      expect(find.text('App language'), findsOneWidget);
    },
  );

  for (final locale in AppLocalizations.supportedLocales) {
    testWidgets(
      '${locale.languageCode} screens fit narrow width and large text',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(360, 900));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        for (final screen in <Widget>[
          const AuthScreen(),
          const Scaffold(body: HomeScreen()),
          const Scaffold(body: SettingsScreen()),
          const ResultScreen(),
        ]) {
          final controller = createTestController();
          await controller.signInWithProvider(IdentityProvider.google);
          controller.openResult(sampleResult());
          await tester.pumpWidget(
            testApp(
              controller: controller,
              home: screen,
              locale: locale,
              textScale: 1.3,
              config: providerReadyTestConfig,
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${locale.languageCode}: ${screen.runtimeType}',
          );
          final direction = Directionality.of(
            tester.element(find.byWidget(screen)),
          );
          expect(
            direction,
            ['ar', 'ur'].contains(locale.languageCode)
                ? TextDirection.rtl
                : TextDirection.ltr,
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        }
      },
    );
  }
}
