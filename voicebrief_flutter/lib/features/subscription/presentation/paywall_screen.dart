import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicebrief/app/config/app_config.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/features/subscription/domain/subscription_models.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selected = ProductIds.annual;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(appControllerProvider).subscription.offeringsLoaded) {
        ref.read(appControllerProvider.notifier).refreshSubscription();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(
      appControllerProvider.select((value) => value.subscription),
    );
    final options = [...status.options]
      ..sort((a, b) => a.annual == b.annual ? 0 : (a.annual ? -1 : 1));
    return AppScaffold(
      appBar: AppTopBar(
        title: '',
        leading: IconButton(
          onPressed: () => context.pop(),
          tooltip: context.l10n.close,
          icon: const Icon(Icons.close),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.xxl,
        ),
        children: [
          Row(
            children: [
              const ProBadge(label: 'VOICEBRIEF PRO'),
              if (status.tier == SubscriptionTier.pro) ...[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  context.l10n.active,
                  style: TextStyle(color: context.palette.success),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.proHeadline,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          _Benefit(
            icon: Icons.subject_outlined,
            label: context.l10n.accurateTranscripts,
          ),
          _Benefit(
            icon: Icons.short_text,
            label: context.l10n.instantSummaries,
          ),
          _Benefit(
            icon: Icons.check_circle_outline,
            label: context.l10n.actionItemsAndDates,
          ),
          _Benefit(
            icon: Icons.reply_outlined,
            label: context.l10n.threeReplyTones,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!status.offeringsLoaded)
            SizedBox(
              height: 190,
              child: AppLoadingView(label: context.l10n.loadingStorePrices),
            )
          else if (options.isEmpty)
            AppErrorView(
              message: context.l10n.subscriptionOptionsUnavailable,
              onRetry: () => ref
                  .read(appControllerProvider.notifier)
                  .refreshSubscription(),
            )
          else ...[
            for (final option in options) ...[
              SubscriptionOptionTile(
                title: option.annual
                    ? context.l10n.yearly
                    : context.l10n.monthly,
                price: option.localizedPrice,
                subtitle: option.annual
                    ? option.localizedMonthlyEquivalent
                    : null,
                badge: option.annual ? context.l10n.bestValue : null,
                selected: _selected == option.productId,
                onTap: () => setState(() => _selected = option.productId),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            const SizedBox(height: AppSpacing.sm),
            AppPrimaryButton(
              label: status.tier == SubscriptionTier.pro
                  ? context.l10n.proActive
                  : context.l10n.continueLabel,
              busy: _busy,
              onPressed: status.tier == SubscriptionTier.pro ? null : _purchase,
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: _busy ? null : _restore,
            child: Text(context.l10n.restorePurchases),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.subscriptionRenewalNotice,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(AppIdentity.termsUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(context.l10n.terms),
              ),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse(AppIdentity.privacyUrl),
                  mode: LaunchMode.externalApplication,
                ),
                child: Text(context.l10n.privacy),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _purchase() async {
    setState(() => _busy = true);
    final success = await ref
        .read(appControllerProvider.notifier)
        .purchase(_selected);
    if (!mounted) return;
    setState(() => _busy = false);
    if (success) {
      AppToast.show(context, context.l10n.proActivatedToast);
      context.pop();
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final success = await ref
        .read(appControllerProvider.notifier)
        .restorePurchases();
    if (!mounted) return;
    setState(() => _busy = false);
    AppToast.show(
      context,
      success ? context.l10n.purchasesRestored : context.l10n.noActivePurchases,
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 21, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
