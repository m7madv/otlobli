import 'package:damanak/app.dart';
import 'package:damanak/l10n/l10n.dart';
import 'package:damanak/l10n/generated/app_localizations.dart';
import 'package:damanak/state/app_controller.dart';
import 'package:damanak/state/app_scope.dart';
import 'package:damanak/screens/account_screen.dart';
import 'package:damanak/screens/subscription_screen.dart';
import 'package:damanak/screens/team_screen.dart';
import 'package:damanak/screens/requests_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({L10n.preferenceKey: 'ar'});
    await L10n.instance.initialize();
  });

  test('resolves supported device languages and English fallback', () {
    expect(L10n.resolve(const [Locale('fr', 'CA')]), const Locale('fr'));
    expect(L10n.resolve(const [Locale('zh', 'TW')]), const Locale('zh'));
    expect(
      L10n.resolve(const [Locale('tr'), Locale('de')]),
      const Locale('de'),
    );
    expect(L10n.resolve(const [Locale('tr')]), const Locale('en'));
  });

  test('persists selection without storing customer or payment data', () async {
    await L10n.instance.select('en');
    await L10n.instance.initialize();
    expect(L10n.instance.locale, const Locale('en'));
    expect(L10n.knownLabel('الضمانات'), 'Warranties');
    expect(L10n.knownLabel('متجر العميل الخاص'), 'متجر العميل الخاص');
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getKeys(), {L10n.preferenceKey});
    await L10n.instance.select(null);
    expect(preferences.containsKey(L10n.preferenceKey), isFalse);
  });

  testWidgets('English uses LTR and can switch to Arabic without restarting', (
    tester,
  ) async {
    await L10n.instance.select('en');
    final controller = AppController.unconfigured();
    await controller.startDemo();
    addTearDown(controller.dispose);
    await tester.pumpWidget(DamanakApp(controller: controller));
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(NavigationBar));
    expect(Directionality.of(context), TextDirection.ltr);
    expect(find.text('Warranties'), findsWidgets);
    await L10n.instance.select('ar');
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byType(NavigationBar))),
      TextDirection.rtl,
    );
    expect(find.text('الضمانات'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  for (final locale in L10n.languageNames.keys) {
    testWidgets('home in $locale at 320px with enlarged text', (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await L10n.instance.select(locale);
      final controller = AppController.unconfigured();
      await controller.startDemo();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: DamanakApp(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(AppLocalizations.supportedLocales, contains(Locale(locale)));
      expect(
        MediaQuery.textScalerOf(
          tester.element(find.byType(NavigationBar)),
        ).scale(1),
        1.5,
      );
      expect(tester.takeException(), isNull);
    });
    for (final screen in <String, Widget>{
      'account': const AccountScreen(),
      'subscriptions': const SubscriptionScreen(),
      'team': const TeamScreen(),
      'claims': const RequestsScreen(),
    }.entries) {
      testWidgets('${screen.key} in $locale at 320px and 150%', (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 1.5;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await L10n.instance.select(locale);
        final controller = AppController.unconfigured();
        await controller.startDemo();
        addTearDown(controller.dispose);
        await tester.pumpWidget(
          AppScope(
            controller: controller,
            child: MaterialApp(
              locale: Locale(locale),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              home: Scaffold(body: screen.value),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
