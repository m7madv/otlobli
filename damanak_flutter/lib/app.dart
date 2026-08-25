import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'models/account.dart';
import 'screens/auth_screen.dart';
import 'screens/configuration_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';
import 'state/app_controller.dart';
import 'state/app_scope.dart';

class DamanakApp extends StatelessWidget {
  const DamanakApp({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      controller: controller,
      child: const DamanakAppFrame(home: _AppGate()),
    );
  }
}

/// الغلاف البصري المشترك بين الإقلاع وبقية التطبيق، لمنع أي وميض بينهما.
class DamanakAppFrame extends StatelessWidget {
  const DamanakAppFrame({required this.home, super.key});

  final Widget home;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ضمانك للأعمال',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildAppTheme(),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: Directionality(textDirection: TextDirection.rtl, child: home),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final page = switch (controller.stage) {
      AppStage.configuring => const ConfigurationScreen(),
      AppStage.signedOut => const AuthScreen(),
      AppStage.onboarding => const OnboardingScreen(),
      AppStage.ready => const ShellScreen(),
    };
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      child: KeyedSubtree(key: ValueKey(controller.stage), child: page),
    );
  }
}
