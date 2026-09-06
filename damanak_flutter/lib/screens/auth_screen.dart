import 'package:damanak/l10n/l10n.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';
import '../widgets/message_banner.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    final inviteReady = controller.pendingInvitationCode != null;
    return Scaffold(
      appBar: AppBar(actions: const [LanguagePicker()]),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1040),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final form = _AuthPanel(
                    busy: controller.busy,
                    inviteReady: inviteReady,
                    onSocial: controller.signInWithSocial,
                  );
                  if (constraints.maxWidth < 780) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandMark(),
                        const SizedBox(height: 28),
                        form,
                        const SizedBox(height: 22),
                        const _TrustStrip(),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Expanded(child: _AuthStory()),
                      const SizedBox(width: 34),
                      Expanded(child: form),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.busy,
    required this.inviteReady,
    required this.onSocial,
  });

  final bool busy;
  final bool inviteReady;
  final ValueChanged<SocialAuthProvider> onSocial;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final colors = context.colors;
    final appleFirst = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final showApple = kIsWeb || defaultTargetPlatform == TargetPlatform.iOS;
    final buttons = <Widget>[
      if (appleFirst) ...[
        _AppleButton(busy: busy, onPressed: onSocial),
        const SizedBox(height: 12),
      ],
      _GoogleButton(busy: busy, onPressed: onSocial),
      if (showApple && !appleFirst) ...[
        const SizedBox(height: 12),
        _AppleButton(busy: busy, onPressed: onSocial),
      ],
    ];
    return Container(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width < 380 ? 18 : 24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            inviteReady
                ? L10n.current.msgb1afed756408
                : L10n.current.msg2837eb878bb4,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 7),
          Text(
            inviteReady
                ? showApple
                      ? L10n.current.msg6c4394b5c8de
                      : L10n.current.msg433779b5949c
                : L10n.current.msgbc960abda0c4,
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          if (inviteReady) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.group_add_outlined,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      L10n.current.msgf96ed34f8982,
                      style: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          const MessageBanner(),
          ...buttons,
          if (busy) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  L10n.current.msg78fd957e44f0,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Text(
            L10n.current.msgd98d709d9821,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.busy, required this.onPressed});

  final bool busy;
  final ValueChanged<SocialAuthProvider> onPressed;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    return Semantics(
      button: true,
      label: L10n.current.msgf8402c2a1011,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: OutlinedButton(
          onPressed: busy ? null : () => onPressed(SocialAuthProvider.google),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Text(
                  'G',
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  L10n.current.msgf8402c2a1011,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppleButton extends StatelessWidget {
  const _AppleButton({required this.busy, required this.onPressed});

  final bool busy;
  final ValueChanged<SocialAuthProvider> onPressed;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = dark ? Colors.black : Colors.white;
    final background = dark ? Colors.white : Colors.black;
    return Semantics(
      button: true,
      label: L10n.current.msg6bdd85157847,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            disabledBackgroundColor: background.withValues(alpha: 0.45),
            disabledForegroundColor: foreground.withValues(alpha: 0.72),
          ),
          onPressed: busy ? null : () => onPressed(SocialAuthProvider.apple),
          child: Row(
            children: [
              SizedBox(width: 28, child: Icon(Icons.apple_rounded, size: 23)),
              Expanded(
                child: Text(
                  L10n.current.msg6bdd85157847,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(width: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthStory extends StatelessWidget {
  const _AuthStory();

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandMark(onDark: true),
          Spacer(),
          Text(
            L10n.current.msgd43e32c57516,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              height: 1.15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          Text(
            L10n.current.msgb4b1b15b2668,
            style: TextStyle(color: Color(0xFFBDD0CD), height: 1.65),
          ),
          SizedBox(height: 28),
          _TrustStrip(onDark: true),
        ],
      ),
    );
  }
}

class _TrustStrip extends StatelessWidget {
  const _TrustStrip({this.onDark = false});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final colors = context.colors;
    final color = onDark
        ? Colors.white.withValues(alpha: 0.82)
        : colors.onSurface;
    final iconColor = onDark ? AppColors.accentDark : colors.primary;
    return Wrap(
      spacing: 14,
      runSpacing: 9,
      children: [
        _TrustItem(
          icon: Icons.person_outline_rounded,
          text: L10n.current.msg1914dae89043,
          color: color,
          iconColor: iconColor,
        ),
        _TrustItem(
          icon: Icons.shield_outlined,
          text: L10n.current.msg81538c5a6b52,
          color: color,
          iconColor: iconColor,
        ),
        _TrustItem(
          icon: Icons.link_rounded,
          text: L10n.current.msgfc933a60701c,
          color: color,
          iconColor: iconColor,
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({
    required this.icon,
    required this.text,
    required this.color,
    required this.iconColor,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: iconColor),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
