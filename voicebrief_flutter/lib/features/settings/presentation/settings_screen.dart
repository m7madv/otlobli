import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicebrief/app/config/app_config.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/features/subscription/domain/subscription_models.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.page,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      children: [
        Text(
          context.l10n.settings,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionHeader(context.l10n.account),
        const SizedBox(height: AppSpacing.xs),
        AppListTile(
          title: state.user?.email ?? context.l10n.notSignedIn,
          subtitle: state.user?.emailVerified == true
              ? context.l10n.verifiedAccount
              : context.l10n.emailVerificationRequired,
          leading: const Icon(Icons.account_circle_outlined),
        ),
        const AppDivider(indent: 48),
        AppListTile(
          title: state.subscription.tier == SubscriptionTier.pro
              ? context.l10n.voiceBriefPro
              : context.l10n.freePlan,
          subtitle: context.l10n.minutesRemaining(
            state.subscription.remainingMinutes,
          ),
          leading: const Icon(Icons.workspace_premium_outlined),
          trailing: state.subscription.tier == SubscriptionTier.pro
              ? const ProBadge()
              : const Icon(Icons.chevron_right),
          onTap: () => context.push('/paywall'),
        ),
        const AppDivider(indent: 48),
        AppListTile(
          title: context.l10n.restorePurchases,
          leading: const Icon(Icons.restore),
          onTap: () async {
            final restored = await controller.restorePurchases();
            if (context.mounted) {
              AppToast.show(
                context,
                restored
                    ? context.l10n.purchasesRestored
                    : context.l10n.noPurchasesRestored,
              );
            }
          },
        ),
        const AppDivider(indent: 48),
        AppListTile(
          title: context.l10n.manageSubscription,
          leading: const Icon(Icons.open_in_new),
          onTap: () => launchUrl(
            Uri.parse(
              Platform.isIOS
                  ? 'https://apps.apple.com/account/subscriptions'
                  : 'https://play.google.com/store/account/subscriptions',
            ),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(context.l10n.appearance),
        const SizedBox(height: AppSpacing.sm),
        AppSegmentedControl<ThemeMode>(
          segments: [
            ButtonSegment(
              value: ThemeMode.system,
              label: Text(context.l10n.systemTheme),
            ),
            ButtonSegment(
              value: ThemeMode.light,
              label: Text(context.l10n.lightTheme),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              label: Text(context.l10n.darkTheme),
            ),
          ],
          selected: state.themeMode,
          onSelectionChanged: controller.setThemeMode,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(context.l10n.privacyAndData),
        const SizedBox(height: AppSpacing.xs),
        AppListTile(
          title: context.l10n.audioHandlingTitle,
          subtitle: context.l10n.audioHandlingDescription,
          leading: const Icon(Icons.lock_outline),
        ),
        const AppDivider(indent: 48),
        AppListTile(
          title: context.l10n.exportSavedText,
          subtitle: state.history.isEmpty
              ? context.l10n.noSavedTextOnDevice
              : context.l10n.exportSavedTextDescription,
          leading: const Icon(Icons.ios_share_outlined),
          onTap: () async {
            if (state.history.isEmpty) {
              AppToast.show(context, context.l10n.noSavedTextOnDevice);
              return;
            }
            await _export(context, state.history);
          },
        ),
        const AppDivider(indent: 48),
        AppListTile(
          title: context.l10n.clearLocalHistory,
          subtitle: state.history.isEmpty
              ? context.l10n.noSavedTextOnDevice
              : context.l10n.clearSavedTextDescription,
          leading: const Icon(Icons.delete_sweep_outlined),
          onTap: () async {
            if (state.history.isEmpty) {
              AppToast.show(context, context.l10n.noSavedTextOnDevice);
              return;
            }
            final confirmed = await AppDialog.confirm(
              context: context,
              title: context.l10n.clearHistoryTitle,
              message: context.l10n.clearHistoryMessage,
              confirmLabel: context.l10n.clearHistory,
              destructive: true,
            );
            if (!confirmed) return;
            final cleared = await controller.clearHistory();
            if (context.mounted) {
              AppToast.show(
                context,
                cleared
                    ? context.l10n.savedTextCleared
                    : context.l10n.clearSavedTextFailed,
              );
            }
          },
        ),
        const AppDivider(indent: 48),
        AppListTile(
          title: context.l10n.privacyPolicy,
          leading: const Icon(Icons.privacy_tip_outlined),
          onTap: () => launchUrl(
            Uri.parse(AppIdentity.privacyUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const AppDivider(indent: 48),
        AppListTile(
          title: context.l10n.termsOfService,
          leading: const Icon(Icons.description_outlined),
          onTap: () => launchUrl(
            Uri.parse(AppIdentity.termsUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSectionHeader(context.l10n.support),
        const SizedBox(height: AppSpacing.xs),
        AppListTile(
          title: context.l10n.contactSupport,
          leading: const Icon(Icons.help_outline),
          onTap: () => launchUrl(
            Uri.parse(AppIdentity.supportUrl),
            mode: LaunchMode.externalApplication,
          ),
        ),
        const AppDivider(indent: 48),
        FutureBuilder<String>(
          future: _appVersion(),
          builder: (context, snapshot) => AppListTile(
            title: context.l10n.appVersion,
            subtitle: snapshot.data?.isNotEmpty == true
                ? snapshot.data
                : context.l10n.unavailable,
            leading: const Icon(Icons.info_outline),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppSecondaryButton(
          label: context.l10n.signOut,
          onPressed: () async {
            await controller.signOut();
            if (context.mounted) context.go('/auth');
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            final confirmed = await AppDialog.confirm(
              context: context,
              title: context.l10n.deleteAccountTitle,
              message: context.l10n.deleteAccountMessage,
              confirmLabel: context.l10n.deleteAccount,
              destructive: true,
            );
            if (!confirmed) return;
            final deleted = await controller.deleteAccount();
            if (deleted && context.mounted) context.go('/auth');
          },
          child: Text(context.l10n.deleteAccount),
        ),
      ],
    );
  }

  Future<void> _export(BuildContext context, List<BriefResult> history) async {
    final text = history
        .map((result) => _plainText(context, result))
        .join('\n\n──────────\n\n');
    File? exportFile;
    try {
      final directory = await getTemporaryDirectory();
      exportFile = File(
        '${directory.path}${Platform.pathSeparator}'
        'voicebrief-text-${DateTime.now().millisecondsSinceEpoch}.txt',
      );
      await exportFile.writeAsString(text, flush: true);
      if (!context.mounted) return;
      final renderBox = context.findRenderObject() as RenderBox?;
      final origin = renderBox == null
          ? null
          : renderBox.localToGlobal(Offset.zero) & renderBox.size;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(exportFile.path, mimeType: 'text/plain')],
          subject: context.l10n.exportSubject,
          sharePositionOrigin: origin,
        ),
      );
    } on Object {
      if (context.mounted) {
        AppToast.show(context, context.l10n.exportSavedTextFailed);
      }
    } finally {
      if (exportFile != null && await exportFile.exists()) {
        await exportFile.delete();
      }
    }
  }

  Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version} (${info.buildNumber})';
    } on Object {
      // Platform metadata may be unavailable in previews and widget tests.
      return '';
    }
  }

  String _plainText(BuildContext context, BriefResult result) {
    final actionItems = result.actionItems
        .map((item) => '□ ${item.title}')
        .join('\n');
    final importantDates = result.importantDates
        .map((date) => '• ${date.label}: ${date.originalPhrase}')
        .join('\n');
    return '${result.title}\n\n'
        '${context.l10n.brief}\n${result.summary}\n\n'
        '${context.l10n.keyPoints}\n'
        '${result.keyPoints.map((item) => '• $item').join('\n')}\n\n'
        '${context.l10n.actionItems}\n$actionItems\n\n'
        '${context.l10n.importantDates}\n$importantDates\n\n'
        '${context.l10n.suggestedReplies}\n'
        '${context.l10n.shortTone}: ${result.suggestedReplies.short}\n'
        '${context.l10n.friendlyTone}: ${result.suggestedReplies.friendly}\n'
        '${context.l10n.professionalTone}: '
        '${result.suggestedReplies.professional}\n\n'
        '${context.l10n.fullTranscript}\n${result.transcript}';
  }
}
