import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/features/audio_import/presentation/audio_preparation_screen.dart';
import 'package:voicebrief/features/auth/presentation/auth_screen.dart';
import 'package:voicebrief/features/home/presentation/shell_screen.dart';
import 'package:voicebrief/features/onboarding/presentation/onboarding_screen.dart';
import 'package:voicebrief/features/recorder/presentation/recorder_screen.dart';
import 'package:voicebrief/features/reminders/presentation/scheduled_reminders_screen.dart';
import 'package:voicebrief/features/subscription/presentation/paywall_screen.dart';
import 'package:voicebrief/features/transcription/presentation/processing_screen.dart';
import 'package:voicebrief/features/transcription/presentation/result_screen.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final appState = ref.read(appControllerProvider);
  final hasRestoredSession = appState.user != null;
  final shouldOpenSharedResult =
      hasRestoredSession &&
      appState.activeResult != null &&
      appState.resultNavigationRequest > 0;
  final router = GoRouter(
    initialLocation: shouldOpenSharedResult
        ? '/result'
        : hasRestoredSession
        ? '/app'
        : '/onboarding',
    routes: [
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/auth', builder: (_, _) => const AuthScreen()),
      GoRoute(path: '/app', builder: (_, _) => const ShellScreen()),
      GoRoute(
        path: '/audio',
        builder: (_, _) => const AudioPreparationScreen(),
      ),
      GoRoute(path: '/record', builder: (_, _) => const RecorderScreen()),
      GoRoute(
        path: '/alarms',
        builder: (_, _) => const ScheduledRemindersScreen(),
      ),
      GoRoute(path: '/processing', builder: (_, _) => const ProcessingScreen()),
      GoRoute(path: '/result', builder: (_, _) => const ResultScreen()),
      GoRoute(path: '/paywall', builder: (_, _) => const PaywallScreen()),
    ],
    errorBuilder: (context, state) => AppScaffold(
      body: AppErrorView(
        message: context.l10n.screenUnavailable,
        onRetry: () => context.go('/app'),
      ),
    ),
  );
  ref.onDispose(router.dispose);
  return router;
});
