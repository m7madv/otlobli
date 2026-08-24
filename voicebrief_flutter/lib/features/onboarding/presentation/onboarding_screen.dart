import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          children: [
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: () => context.go('/auth'),
                child: Text(context.l10n.onboardingSignIn),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: [
                  _OnboardingPage(
                    title: context.l10n.onboardingTitleOne,
                    body: context.l10n.onboardingBodyOne,
                    icon: Icons.graphic_eq,
                  ),
                  _OnboardingPage(
                    title: context.l10n.onboardingTitleTwo,
                    body: context.l10n.onboardingBodyTwo,
                    icon: Icons.lock_outline,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (index) => AnimatedContainer(
                  duration: AppMotion.quick,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: index == _page ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: index == _page
                        ? Theme.of(context).colorScheme.primary
                        : context.palette.strongBorder,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: _page == 0
                  ? context.l10n.continueLabel
                  : context.l10n.getStarted,
              onPressed: () {
                if (_page == 0) {
                  _controller.nextPage(
                    duration: AppMotion.standard,
                    curve: Curves.easeOutCubic,
                  );
                } else {
                  context.go('/auth');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.title,
    required this.body,
    required this.icon,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 128,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const AudioWaveform(height: 88, activeFraction: 0.53),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.palette.border),
                    ),
                    child: SizedBox.square(
                      dimension: 52,
                      child: Icon(
                        icon,
                        color: Theme.of(context).colorScheme.primary,
                        semanticLabel: '',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: context.palette.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
