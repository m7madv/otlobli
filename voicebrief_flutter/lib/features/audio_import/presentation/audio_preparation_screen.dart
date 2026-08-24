import 'dart:async';
import 'dart:math' as math;

import 'package:audio_waveforms/audio_waveforms.dart' as waveforms;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/core/utils/formatters.dart';
import 'package:voicebrief/features/audio_import/domain/audio_input.dart';
import 'package:voicebrief/features/transcription/domain/processing_options.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class AudioPreparationScreen extends ConsumerStatefulWidget {
  const AudioPreparationScreen({super.key});

  @override
  ConsumerState<AudioPreparationScreen> createState() =>
      _AudioPreparationScreenState();
}

class _AudioPreparationScreenState
    extends ConsumerState<AudioPreparationScreen> {
  static const _waveformSamples = 72;

  final _player = AudioPlayer();
  final _waveformPlayer = waveforms.PlayerController();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlayerState>? _stateSubscription;
  StreamSubscription<List<double>>? _waveformSubscription;
  StreamSubscription<double>? _waveformProgressSubscription;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  RangeValues _trimRange = const RangeValues(0, 1);
  List<double> _waveformLevels = const [];
  double _waveformProgress = 0;
  bool _playing = false;
  bool _loadingAudio = true;
  bool _trimming = false;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _positionSubscription = _player.positionStream.listen(_handlePosition);
    _stateSubscription = _player.playerStateStream.listen((value) {
      if (mounted) setState(() => _playing = value.playing);
    });
    _waveformSubscription = _waveformPlayer
        .waveformExtraction
        .onCurrentExtractedWaveformData
        .listen((levels) {
          if (mounted && levels.isNotEmpty) {
            setState(() => _waveformLevels = List.unmodifiable(levels));
          }
        });
    _waveformProgressSubscription = _waveformPlayer
        .waveformExtraction
        .onExtractionProgress
        .listen((progress) {
          if (mounted) setState(() => _waveformProgress = progress);
        });
    _waveformPlayer.addListener(_takeCompletedWaveform);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSelected());
  }

  void _takeCompletedWaveform() {
    final levels = _waveformPlayer.waveformExtraction.waveformData;
    if (mounted && levels.isNotEmpty) {
      setState(() {
        _waveformLevels = List.unmodifiable(levels);
        _waveformProgress = 1;
      });
    }
  }

  void _handlePosition(Duration value) {
    if (!mounted) return;
    final end = _trimEnd;
    if (_playing && _duration > Duration.zero && value >= end) {
      unawaited(_restartSelection());
      return;
    }
    setState(() => _position = value);
  }

  Future<void> _restartSelection() async {
    await _player.pause();
    await _player.seek(_trimStart);
    if (mounted) setState(() => _position = _trimStart);
  }

  Future<void> _loadSelected() async {
    final input = ref.read(appControllerProvider).selectedAudio;
    if (input == null) {
      if (mounted) context.go('/app');
      return;
    }
    final generation = ++_loadGeneration;
    await _player.stop();
    _cancelWaveformExtraction();
    if (mounted) {
      setState(() {
        _loadingAudio = true;
        _position = Duration.zero;
        _trimRange = const RangeValues(0, 1);
        _waveformLevels = const [];
        _waveformProgress = 0;
      });
    }
    try {
      final loadedDuration = await _player.setFilePath(input.path);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _duration = loadedDuration ?? Duration(seconds: input.durationSeconds);
        _loadingAudio = false;
      });
      unawaited(
        _waveformPlayer
            .preparePlayer(
              path: input.path,
              shouldExtractWaveform: true,
              noOfSamples: _waveformSamples,
            )
            .catchError((_) {}),
      );
    } on Object {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _duration = Duration(seconds: input.durationSeconds);
        _loadingAudio = false;
      });
    }
  }

  @override
  void dispose() {
    _loadGeneration += 1;
    unawaited(_positionSubscription?.cancel());
    unawaited(_stateSubscription?.cancel());
    unawaited(_waveformSubscription?.cancel());
    unawaited(_waveformProgressSubscription?.cancel());
    _waveformPlayer.removeListener(_takeCompletedWaveform);
    _waveformPlayer.dispose();
    unawaited(_player.dispose());
    super.dispose();
  }

  Duration get _trimStart => Duration(
    milliseconds: (_effectiveDuration.inMilliseconds * _trimRange.start)
        .round(),
  );

  Duration get _trimEnd => Duration(
    milliseconds: (_effectiveDuration.inMilliseconds * _trimRange.end).round(),
  );

  Duration get _effectiveDuration {
    if (_duration > Duration.zero) return _duration;
    final seconds = ref
        .read(appControllerProvider)
        .selectedAudio
        ?.durationSeconds;
    return Duration(seconds: seconds ?? 0);
  }

  bool get _hasTrimSelection =>
      _trimRange.start > 0.001 || _trimRange.end < 0.999;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final audio = state.selectedAudio;
    if (audio == null) return const SizedBox.shrink();
    final options = state.processingOptions;
    final shared =
        audio.source == AudioSourceKind.androidShare ||
        audio.source == AudioSourceKind.iosShare;
    final duration = _effectiveDuration;
    final progress = duration.inMilliseconds <= 0
        ? 0.0
        : _position.inMilliseconds / duration.inMilliseconds;
    return AppScaffold(
      appBar: AppTopBar(
        title: shared ? context.l10n.voiceNoteReady : context.l10n.reviewAudio,
        leading: const BackButton(),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          if (shared) ...[
            const _SharedAudioReadyBanner(),
            const SizedBox(height: AppSpacing.md),
          ],
          AudioFileTile(
            name: audio.displayName,
            details:
                '${formatDuration(duration.inSeconds)} · ${formatBytes(audio.sizeBytes)}',
            onRemove: _trimming ? null : _remove,
            onReplace: _trimming ? null : _replace,
          ),
          const SizedBox(height: AppSpacing.lg),
          _SeekableWaveform(
            levels: _waveformLevels,
            progress: progress,
            trimRange: _trimRange,
            loading: _waveformProgress < 1 && _waveformLevels.isEmpty,
            onSeek: _seekToFraction,
          ),
          if (_waveformProgress < 1) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                SizedBox.square(
                  dimension: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value: _waveformProgress > 0 ? _waveformProgress : null,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    context.l10n.audioWaveformLoading,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
          AudioPlayerBar(
            playing: _playing,
            progress: progress,
            elapsedLabel: formatDuration(_position.inSeconds),
            durationLabel: formatDuration(duration.inSeconds),
            onSeek: _loadingAudio || duration <= Duration.zero
                ? null
                : _seekToFraction,
            onPlayPause: _togglePlayback,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.trimAudio,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            context.l10n.trimAudioHelp,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          RangeSlider(
            values: _trimRange,
            labels: RangeLabels(
              formatDuration(_trimStart.inSeconds),
              formatDuration(_trimEnd.inSeconds),
            ),
            onChanged: _loadingAudio || duration.inMilliseconds < 1000
                ? null
                : _updateTrimRange,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    context.l10n.selectedAudioRange(
                      formatDuration(_trimStart.inSeconds),
                      formatDuration(_trimEnd.inSeconds),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              if (_hasTrimSelection)
                TextButton(
                  onPressed: _trimming ? null : _resetTrim,
                  child: Text(context.l10n.useFullAudio),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_trimming)
            AppLoadingView(label: context.l10n.trimmingAudio)
          else
            AppPrimaryButton(
              label: _hasTrimSelection
                  ? context.l10n.createBriefFromSelection
                  : context.l10n.createMyBrief,
              icon: _hasTrimSelection
                  ? Icons.content_cut_rounded
                  : Icons.auto_awesome_rounded,
              onPressed: () => _continueToProcessing(options),
            ),
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            label: context.l10n.secureAiProcessingSemantics,
            child: Text(
              context.l10n.secureAiProcessing,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(context.l10n.customizeOutput),
              subtitle: Text(context.l10n.defaultOutput),
              children: [
                _OptionSwitch(
                  label: context.l10n.summaryAndKeyPoints,
                  value: options.summary,
                  onChanged: (value) =>
                      _update(options.copyWith(summary: value)),
                ),
                const AppDivider(),
                _OptionSwitch(
                  label: context.l10n.actionItemsAndDates,
                  value: options.actionItems,
                  onChanged: (value) =>
                      _update(options.copyWith(actionItems: value)),
                ),
                const AppDivider(),
                _OptionSwitch(
                  label: context.l10n.suggestedReplies,
                  value: options.suggestedReplies,
                  onChanged: (value) =>
                      _update(options.copyWith(suggestedReplies: value)),
                ),
                const AppDivider(),
                _OptionSwitch(
                  label: context.l10n.translateSummaryEnglish,
                  value: options.translation,
                  onChanged: (value) =>
                      _update(options.copyWith(translation: value)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePlayback() async {
    if (_loadingAudio || _effectiveDuration <= Duration.zero) return;
    if (_playing) {
      await _player.pause();
      return;
    }
    if (_position < _trimStart ||
        _position >= _trimEnd ||
        _player.processingState == ProcessingState.completed) {
      await _player.seek(_trimStart);
    }
    await _player.play();
  }

  Future<void> _seekToFraction(double requested) async {
    if (_effectiveDuration <= Duration.zero) return;
    final fraction = requested.clamp(_trimRange.start, _trimRange.end);
    final target = Duration(
      milliseconds: (_effectiveDuration.inMilliseconds * fraction).round(),
    );
    await _player.seek(target);
    if (mounted) setState(() => _position = target);
  }

  void _updateTrimRange(RangeValues requested) {
    final durationMs = _effectiveDuration.inMilliseconds;
    if (durationMs <= 0) return;
    final minimumFraction = math.min(1.0, 1000 / durationMs);
    if (requested.end - requested.start < minimumFraction) return;
    setState(() => _trimRange = requested);
    if (_position < _trimStart || _position > _trimEnd) {
      unawaited(_seekToFraction(_trimRange.start));
    }
  }

  void _resetTrim() {
    setState(() => _trimRange = const RangeValues(0, 1));
  }

  Future<void> _continueToProcessing(ProcessingOptions options) async {
    if (_trimming || _loadingAudio) return;
    if (_hasTrimSelection) {
      setState(() => _trimming = true);
      await _player.pause();
      _cancelWaveformExtraction();
      final trimmed = await ref
          .read(appControllerProvider.notifier)
          .trimSelectedAudio(start: _trimStart, end: _trimEnd);
      if (!mounted) return;
      if (!trimmed) {
        setState(() => _trimming = false);
        return;
      }
      setState(() => _trimming = false);
      AppToast.show(context, context.l10n.audioTrimmed);
    }
    if (mounted) context.push('/processing');
  }

  void _update(ProcessingOptions options) {
    ref
        .read(appControllerProvider.notifier)
        .updateProcessingOptions(options.copyWith(transcript: true));
  }

  Future<void> _remove() async {
    await _player.stop();
    _cancelWaveformExtraction();
    await ref.read(appControllerProvider.notifier).discardAudio();
    if (mounted) context.go('/app');
  }

  Future<void> _replace() async {
    await _player.stop();
    _cancelWaveformExtraction();
    final selected = await ref.read(appControllerProvider.notifier).pickAudio();
    if (!selected || !mounted) return;
    await _loadSelected();
  }

  void _cancelWaveformExtraction() {
    unawaited(
      _waveformPlayer.waveformExtraction.stopWaveformExtraction().catchError(
        (_) {},
      ),
    );
  }
}

class _SeekableWaveform extends StatelessWidget {
  const _SeekableWaveform({
    required this.levels,
    required this.progress,
    required this.trimRange,
    required this.loading,
    required this.onSeek,
  });

  final List<double> levels;
  final double progress;
  final RangeValues trimRange;
  final bool loading;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    final shownLevels = levels.isEmpty
        ? List<double>.filled(
            _AudioPreparationScreenState._waveformSamples,
            0.08,
          )
        : levels;
    return LayoutBuilder(
      builder: (context, constraints) {
        void seekAt(double dx) {
          if (loading || constraints.maxWidth <= 0) return;
          final visual = (dx / constraints.maxWidth).clamp(0.0, 1.0);
          final value = Directionality.of(context) == TextDirection.rtl
              ? 1 - visual
              : visual;
          onSeek(value);
        }

        final rtl = Directionality.of(context) == TextDirection.rtl;
        final visualStart = rtl ? 1 - trimRange.end : trimRange.start;
        final visualEnd = rtl ? 1 - trimRange.start : trimRange.end;
        return Semantics(
          label: context.l10n.audioWaveform,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (details) => seekAt(details.localPosition.dx),
            onHorizontalDragUpdate: (details) =>
                seekAt(details.localPosition.dx),
            child: Stack(
              children: [
                AudioWaveform(
                  levels: shownLevels,
                  activeFraction: progress,
                  height: 86,
                ),
                if (trimRange.start > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: constraints.maxWidth * visualStart,
                    child: ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.68),
                    ),
                  ),
                if (trimRange.end < 1)
                  Positioned(
                    left: constraints.maxWidth * visualEnd,
                    top: 0,
                    bottom: 0,
                    right: 0,
                    child: ColoredBox(
                      color: Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.68),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SharedAudioReadyBanner extends StatelessWidget {
  const _SharedAudioReadyBanner();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: context.l10n.sharedAudioReadySemantics,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.success.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(
            color: context.palette.success.withValues(alpha: 0.35),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: context.palette.success,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.sharedAudioReady,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OptionSwitch extends StatelessWidget {
  const _OptionSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      value: value,
      onChanged: onChanged,
    );
  }
}
