import 'package:damanak/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';

import 'core/app_theme.dart';
import 'models/account.dart';
import 'screens/auth_screen.dart';
import 'screens/configuration_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/shell_screen.dart';
import 'screens/subscription_screen.dart';
import 'state/app_controller.dart';
import 'state/app_scope.dart';

class DamanakApp extends StatefulWidget {
  const DamanakApp({required this.controller, super.key});

  final AppController controller;

  @override
  State<DamanakApp> createState() => _DamanakAppState();
}

class _DamanakAppState extends State<DamanakApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didUpdateWidget(covariant DamanakApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.cancelStoreBillingReconciliation();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.handleAppResumed();
    }
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    L10n.instance.deviceLocalesChanged();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    return AppScope(
      controller: widget.controller,
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
    L10n.watch(context);
    return ListenableBuilder(
      listenable: L10n.instance,
      builder: (context, child) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: L10n.current.msg3493ba48d2a7,
        locale: L10n.instance.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildAppTheme(),
        darkTheme: buildAppTheme(Brightness.dark),
        themeMode: ThemeMode.system,
        home: home,
      ),
    );
  }
}

class _AppGate extends StatelessWidget {
  const _AppGate();

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    final requiresFirstSubscription =
        controller.stage == AppStage.ready &&
        controller.requiresInitialSubscriptionActivation;
    final page = switch (controller.stage) {
      AppStage.configuring => const ConfigurationScreen(),
      AppStage.signedOut => const AuthScreen(),
      AppStage.onboarding => const OnboardingScreen(),
      AppStage.ready when requiresFirstSubscription => const SubscriptionScreen(
        requiredActivation: true,
      ),
      AppStage.ready => const ShellScreen(),
    };
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 220),
      child: KeyedSubtree(
        key: ValueKey(
          requiresFirstSubscription
              ? 'subscription-required'
              : controller.stage,
        ),
        child: page,
      ),
    );
  }
}
