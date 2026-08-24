import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/core/utils/formatters.dart';
import 'package:voicebrief/features/subscription/domain/subscription_models.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _checkedInbox = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_checkedInbox) return;
    _checkedInbox = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(appControllerProvider.notifier).takePendingSharedAudio();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final recent = state.history.take(3).toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      children: [
        Row(
          children: [
            SizedBox(
              width: 44,
              child: AudioWaveform(
                height: 32,
                activeFraction: 0.5,
                levels: const [0.3, 0.62, 1, 0.62, 0.3],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'VoiceBrief',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontSize: 20),
              ),
            ),
            if (state.subscription.tier == SubscriptionTier.free)
              TextButton(
                onPressed: () => context.push('/paywall'),
                child: Text(context.l10n.goPro),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          context.l10n.homeHeadline,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          context.l10n.homeSupporting,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: context.palette.secondaryText),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.audioImporting) ...[
          Semantics(
            liveRegion: true,
            label: context.l10n.sharedAudioImporting,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(AppRadii.control),
                border: Border.all(color: context.palette.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(child: Text(context.l10n.sharedAudioImporting)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const _ShareGuide(),
        const SizedBox(height: AppSpacing.lg),
        AppPrimaryButton(
          label: context.l10n.chooseVoiceNote,
          icon: Icons.audio_file_outlined,
          onPressed: _pick,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppSecondaryButton(
          label: context.l10n.recordInstead,
          icon: Icons.mic_none_rounded,
          onPressed: () => context.push('/record'),
        ),
        const SizedBox(height: AppSpacing.md),
        AppUsageIndicator(
          remaining: state.subscription.remainingMinutes,
          total: state.subscription.totalMinutes,
          isPro: state.subscription.tier == SubscriptionTier.pro,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(
          context.l10n.recentBriefs,
          action: recent.isEmpty
              ? null
              : TextButton(
                  onPressed: () => ref
                      .read(appControllerProvider.notifier)
                      .setNavigationIndex(1),
                  child: Text(context.l10n.viewAll),
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (recent.isEmpty)
          AppEmptyState(
            title: context.l10n.noBriefsYet,
            message: context.l10n.noBriefsMessage,
          )
        else
          for (final (index, result) in recent.indexed) ...[
            _RecentResult(result: result),
            if (index != recent.length - 1) const AppDivider(),
          ],
      ],
    );
  }

  Future<void> _pick() async {
    final selected = await ref.read(appControllerProvider.notifier).pickAudio();
    if (selected && mounted) await context.push('/audio');
  }
}

class _ShareGuide extends StatelessWidget {
  const _ShareGuide();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${context.l10n.shareFromWhatsApp}. ${context.l10n.shareFromWhatsAppSteps}',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.ios_share_outlined,
                size: 22,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.shareFromWhatsApp,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      context.l10n.shareFromWhatsAppSteps,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentResult extends ConsumerWidget {
  const _RecentResult({required this.result});

  final BriefResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppListTile(
      title: result.title,
      subtitle:
          '${formatDuration(result.audioDurationSeconds)} · ${result.detectedLanguage.toUpperCase()} · ${formatDate(result.processedAt, locale: Localizations.localeOf(context).toLanguageTag())}',
      leading: const Icon(Icons.subject_outlined),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        ref.read(appControllerProvider.notifier).openResult(result);
        context.push('/result');
      },
    );
  }
}
