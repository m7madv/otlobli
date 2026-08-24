import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/features/audio_import/domain/audio_input.dart';
import 'package:voicebrief/features/history/presentation/history_screen.dart';
import 'package:voicebrief/features/home/presentation/home_screen.dart';
import 'package:voicebrief/features/settings/presentation/settings_screen.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    ref.listen<String?>(
      appControllerProvider.select((value) => value.errorMessage),
      (previous, next) {
        if (next == null || next == previous) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          AppToast.show(context, context.localizeFailure(next));
          ref.read(appControllerProvider.notifier).clearError();
        });
      },
    );
    ref.listen<(bool, String?, AudioSourceKind?)>(
      appControllerProvider.select(
        (value) => (
          value.audioImporting,
          value.selectedAudio?.path,
          value.selectedAudio?.source,
        ),
      ),
      (previous, next) {
        final completedSharedImport =
            previous?.$1 == true &&
            !next.$1 &&
            next.$2 != null &&
            next.$2 != previous?.$2 &&
            (next.$3 == AudioSourceKind.androidShare ||
                next.$3 == AudioSourceKind.iosShare);
        if (!completedSharedImport) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.push('/audio');
        });
      },
    );
    if (state.user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/auth');
      });
    }
    return AppScaffold(
      body: IndexedStack(
        index: state.navigationIndex,
        children: const [HomeScreen(), HistoryScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: AppBottomNavigation(
        index: state.navigationIndex,
        onDestinationSelected: ref
            .read(appControllerProvider.notifier)
            .setNavigationIndex,
      ),
    );
  }
}
