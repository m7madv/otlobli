import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:voicebrief/app/config/app_config.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/features/auth/data/auth_repository.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    ref.listen(appControllerProvider.select((value) => value.user), (
      previous,
      next,
    ) {
      if (previous?.id == next?.id || next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/app');
      });
    });
    final config = ref.watch(appConfigProvider);
    final showApple =
        Platform.isIOS ||
        Platform.isMacOS ||
        (config.appleServiceId.isNotEmpty &&
            config.appleRedirectUri.isNotEmpty);
    return AppScaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),
                const _AuthMark(),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.l10n.authHeadline,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.authSupporting,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: context.palette.secondaryText,
                  ),
                ),
                if (config.useMocks) ...[
                  const SizedBox(height: AppSpacing.md),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.palette.surface,
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Text(context.l10n.demoServicesActive),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                Text(
                  context.l10n.providerSignInTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.providerSignInDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.palette.secondaryText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (showApple) ...[
                  SizedBox(
                    key: const ValueKey('sign-in-with-apple'),
                    height: 52,
                    child: _AppleIdentityButton(
                      onPressed: state.authBusy
                          ? null
                          : () => _provider(IdentityProvider.apple),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                SizedBox(
                  key: const ValueKey('sign-in-with-google'),
                  height: 52,
                  child: OutlinedButton(
                    onPressed: state.authBusy
                        ? null
                        : () => _provider(IdentityProvider.google),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.palette.primaryText,
                      side: BorderSide(color: context.palette.strongBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadii.control),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 28,
                          child: Text(
                            'G',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4285F4),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            context.l10n.continueWithGoogle,
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 28),
                      ],
                    ),
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.localizeFailure(state.errorMessage!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      context.l10n.byContinuingPrefix,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    _LegalLink(
                      label: context.l10n.terms,
                      url: AppIdentity.termsUrl,
                    ),
                    Text(
                      context.l10n.andConjunction,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    _LegalLink(
                      label: context.l10n.privacyPolicy,
                      url: AppIdentity.privacyUrl,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _provider(IdentityProvider provider) async {
    final success = await ref
        .read(appControllerProvider.notifier)
        .signInWithProvider(provider);
    if (!mounted) return;
    if (success) {
      context.go('/app');
      return;
    }
    final message = ref.read(appControllerProvider).errorMessage;
    if (message != null) {
      AppToast.show(context, context.localizeFailure(message));
    }
  }
}

class _AppleIdentityButton extends StatelessWidget {
  const _AppleIdentityButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? Colors.white : Colors.black;
    final foreground = dark ? Colors.black : Colors.white;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background.withValues(alpha: 0.62),
        disabledForegroundColor: foreground.withValues(alpha: 0.72),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.control),
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: Icon(Icons.apple, size: 25),
          ),
          Center(
            child: Text(
              context.l10n.continueWithApple,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthMark extends StatelessWidget {
  const _AuthMark();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: AudioWaveform(
            height: 34,
            activeFraction: 0.52,
            levels: const [0.3, 0.65, 1, 0.65, 0.3],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'VoiceBrief',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
