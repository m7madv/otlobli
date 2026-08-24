import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen> {
  bool _started = false;
  bool _failed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final result = await ref.read(appControllerProvider.notifier).createBrief();
    if (!mounted) return;
    if (result == null) {
      setState(() => _failed = true);
      return;
    }
    context.go('/result');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    return PopScope(
      canPop: _failed,
      child: AppScaffold(
        appBar: AppTopBar(title: context.l10n.creatingBrief),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: _failed
              ? AppErrorView(
                  message: state.errorMessage == null
                      ? context.l10n.processingFallbackError
                      : context.localizeFailure(state.errorMessage!),
                  onRetry: () {
                    setState(() => _failed = false);
                    _run();
                  },
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const AudioWaveform(height: 96, activeFraction: 0.57),
                        const SizedBox(height: AppSpacing.xl),
                        ProcessingStepIndicator(current: state.processingStep),
                        const SizedBox(height: AppSpacing.xl),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: context.palette.surface,
                            borderRadius: BorderRadius.circular(
                              AppRadii.control,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock_outline,
                                  size: 19,
                                  color: context.palette.secondaryText,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    context.l10n.processingKeepOpen,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
