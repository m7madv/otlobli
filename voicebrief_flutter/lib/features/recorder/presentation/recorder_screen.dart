import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:record/record.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/core/errors/app_failure.dart';
import 'package:voicebrief/core/security/safe_log.dart';
import 'package:voicebrief/core/utils/formatters.dart';
import 'package:voicebrief/features/recorder/data/recorder_service.dart';
import 'package:voicebrief/features/recorder/domain/amplitude_visualizer.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class RecorderScreen extends ConsumerStatefulWidget {
  const RecorderScreen({super.key});

  @override
  ConsumerState<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends ConsumerState<RecorderScreen> {
  late final RecorderService _recorder;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  Timer? _timer;
  List<double> _levels = List<double>.filled(
    25,
    AmplitudeVisualizer.restingLevel,
  );
  double _currentLevel = AmplitudeVisualizer.restingLevel;
  bool _recording = false;
  bool _paused = false;
  bool _busy = false;
  int _seconds = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _recorder = ref.read(recorderServiceProvider);
    _amplitudeSubscription = _recorder.amplitudeStream().listen(
      _onAmplitude,
      onError: _onAmplitudeError,
    );
  }

  void _onAmplitude(Amplitude amplitude) {
    if (!mounted || !_recording || _paused) return;
    final target = AmplitudeVisualizer.levelFromDbfs(amplitude.current);
    final level = AmplitudeVisualizer.smooth(
      previous: _currentLevel,
      next: target,
    );
    setState(() {
      _currentLevel = level;
      _levels = [..._levels.skip(1), level];
    });
  }

  void _onAmplitudeError(Object error, StackTrace stackTrace) {
    final subscription = _amplitudeSubscription;
    if (subscription == null) return;
    _amplitudeSubscription = null;
    SafeLog.event(
      'recorder_amplitude_unavailable',
      metadata: {'code': error.runtimeType.toString()},
    );
    unawaited(subscription.cancel());
  }

  @override
  void dispose() {
    _timer?.cancel();
    unawaited(_amplitudeSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_recording,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !_recording) return;
        final leave = await AppDialog.confirm(
          context: context,
          title: context.l10n.discardRecordingTitle,
          message: context.l10n.discardRecordingMessage,
          confirmLabel: context.l10n.discard,
          destructive: true,
        );
        if (leave) {
          await _cancel();
          if (context.mounted) context.pop();
        }
      },
      child: AppScaffold(
        appBar: AppTopBar(
          title: context.l10n.recordAudio,
          leading: const BackButton(),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: Column(
            children: [
              const Spacer(),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.palette.surface,
                  borderRadius: BorderRadius.circular(AppRadii.surface),
                  border: Border.all(color: context.palette.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 100),
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _recording && !_paused
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(
                                      alpha: 0.08 + _currentLevel * 0.16,
                                    )
                                  : context.palette.elevatedSurface,
                            ),
                            child: Icon(
                              _recording
                                  ? (_paused
                                        ? Icons.pause_rounded
                                        : Icons.mic_rounded)
                                  : Icons.mic_none_rounded,
                              size: 22,
                              color: _recording && !_paused
                                  ? Theme.of(context).colorScheme.primary
                                  : context.palette.secondaryText,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              _recording
                                  ? (_paused
                                        ? context.l10n.recordingPaused
                                        : context.l10n.recording)
                                  : context.l10n.tapRecordReady,
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        formatDuration(_seconds),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AudioWaveform(
                        height: 104,
                        levels: _levels,
                        activeFraction: _recording && !_paused ? 1 : 0,
                        live: _recording && !_paused,
                      ),
                    ],
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  context.localizeFailure(_error!),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              if (!_recording)
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _start,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.control),
                        ),
                      ),
                      icon: const Icon(Icons.mic_rounded),
                      label: Text(context.l10n.startRecording),
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        label: _paused
                            ? context.l10n.resume
                            : context.l10n.pause,
                        icon: _paused ? Icons.mic : Icons.pause,
                        onPressed: _busy ? null : _togglePause,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppPrimaryButton(
                        label: context.l10n.stop,
                        icon: Icons.stop,
                        busy: _busy,
                        onPressed: _stop,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: _busy ? null : _cancel,
                  child: Text(context.l10n.cancelRecording),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                context.l10n.microphoneJustInTime,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await HapticFeedback.selectionClick();
      await _recorder.start();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted && !_paused) setState(() => _seconds++);
      });
      setState(() {
        _recording = true;
        _busy = false;
      });
    } on AppFailure catch (failure) {
      setState(() {
        _busy = false;
        _error = failure.message;
      });
    } on Object catch (error) {
      SafeLog.event(
        'recorder_start_failed',
        metadata: {
          'code': error is PlatformException
              ? error.code
              : error.runtimeType.toString(),
          'stage': _recorderDiagnostic(error),
        },
      );
      setState(() {
        _busy = false;
        _error = const AppFailure(AppFailureCode.unknown).message;
      });
    }
  }

  String _recorderDiagnostic(Object error) {
    if (error is! PlatformException || error.message == null) {
      return error.runtimeType.toString();
    }
    return error.message!
        .replaceAll(RegExp(r'[/\\][^\s,;]+'), '<path>')
        .replaceAll(
          RegExp(r'[0-9a-f]{8}-[0-9a-f-]{27,}', caseSensitive: false),
          '<id>',
        );
  }

  Future<void> _togglePause() async {
    if (_paused) {
      await HapticFeedback.selectionClick();
      await _recorder.resume();
    } else {
      await _recorder.pause();
      await HapticFeedback.selectionClick();
    }
    setState(() => _paused = !_paused);
  }

  Future<void> _stop() async {
    setState(() => _busy = true);
    final recordedPath = await _recorder.stop();
    _timer?.cancel();
    if (recordedPath == null) {
      setState(() {
        _busy = false;
        _error = context.l10n.recordingSaveFailed;
      });
      return;
    }
    await HapticFeedback.mediumImpact();
    await ref
        .read(appControllerProvider.notifier)
        .selectRecording(recordedPath, _seconds);
    if (mounted) context.go('/audio');
  }

  Future<void> _cancel() async {
    _timer?.cancel();
    await _recorder.cancel();
    if (mounted) {
      setState(() {
        _recording = false;
        _paused = false;
        _seconds = 0;
        _currentLevel = AmplitudeVisualizer.restingLevel;
        _levels = List<double>.filled(25, AmplitudeVisualizer.restingLevel);
      });
    }
  }
}
