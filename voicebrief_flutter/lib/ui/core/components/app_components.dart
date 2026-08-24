import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    required this.body,
    super.key,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset = true,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: SafeArea(top: appBar == null, child: body),
    );
  }
}

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    required this.title,
    super.key,
    this.leading,
    this.actions = const [],
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: leading,
      title: Text(title),
      actions: actions,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: context.palette.border),
      ),
    );
  }
}

class AppBottomNavigation extends StatelessWidget {
  const AppBottomNavigation({
    required this.index,
    required this.onDestinationSelected,
    super.key,
  });

  final int index;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.palette.border)),
      ),
      child: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: context.l10n.home,
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history),
            label: context.l10n.history,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: context.l10n.settings,
          ),
        ],
      ),
    );
  }
}

class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? const SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 21),
                const SizedBox(width: AppSpacing.xs),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: busy ? null : onPressed,
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            textStyle: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 21),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: context.palette.primaryText,
            side: BorderSide(color: context.palette.strongBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.control),
            ),
            textStyle: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class AppIconButton extends StatelessWidget {
  const AppIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 48, height: 48),
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.label,
    super.key,
    this.controller,
    this.hint,
    this.errorText,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.autofillHints,
  });

  final String label;
  final TextEditingController? controller;
  final String? hint;
  final String? errorText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onChanged: onChanged,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: errorText,
      ),
    );
  }
}

class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    required this.label,
    super.key,
    this.controller,
    this.errorText,
    this.textInputAction,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController? controller;
  final String? errorText;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: widget.textInputAction,
      onSubmitted: widget.onSubmitted,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: widget.label,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: _obscure
              ? context.l10n.showPassword
              : context.l10n.hidePassword,
          onPressed: () => setState(() => _obscure = !_obscure),
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
        ),
      ),
    );
  }
}

class AppSegmentedControl<T extends Object> extends StatelessWidget {
  const AppSegmentedControl({
    required this.segments,
    required this.selected,
    required this.onSelectionChanged,
    super.key,
  });

  final List<ButtonSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        segments: segments,
        selected: {selected},
        showSelectedIcon: false,
        onSelectionChanged: (values) => onSelectionChanged(values.first),
      ),
    );
  }
}

class AppListTile extends StatelessWidget {
  const AppListTile({
    required this.title,
    super.key,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.bodyLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.title, {super.key, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ?action,
      ],
    );
  }
}

class AppDivider extends StatelessWidget {
  const AppDivider({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, indent: indent, color: context.palette.border);
}

abstract final class AppSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.palette.elevatedSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadii.surface),
        ),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: child,
      ),
    );
  }
}

abstract final class AppDialog {
  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    bool destructive = false,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(context.l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: destructive
                    ? TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      )
                    : null,
                child: Text(confirmLabel),
              ),
            ],
          ),
        ) ??
        false;
  }
}

abstract final class AppToast {
  static void show(
    BuildContext context,
    String message, {
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          action: actionLabel == null
              ? null
              : SnackBarAction(
                  label: actionLabel,
                  onPressed: onAction ?? () {},
                ),
        ),
      );
  }
}

class AppErrorView extends StatelessWidget {
  const AppErrorView({required this.message, super.key, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(0, constraints.maxHeight - AppSpacing.page * 2),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 32,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(message, textAlign: TextAlign.center),
                if (onRetry != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  AppSecondaryButton(
                    label: context.l10n.tryAgain,
                    onPressed: onRetry,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    required this.message,
    super.key,
    this.icon = Icons.graphic_eq,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        children: [
          Icon(icon, size: 34, color: context.palette.secondaryText),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.md),
            action!,
          ],
        ],
      ),
    );
  }
}

class AppLoadingView extends StatelessWidget {
  const AppLoadingView({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: label,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox.square(
              dimension: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class AppUsageIndicator extends StatelessWidget {
  const AppUsageIndicator({
    required this.remaining,
    required this.total,
    super.key,
    this.isPro = false,
  });

  final int remaining;
  final int total;
  final bool isPro;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (remaining / total).clamp(0.0, 1.0);
    return Semantics(
      label: context.l10n.usageMinutesSemantics(remaining, total),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isPro
                      ? context.l10n.usageProMinutesRemaining(remaining, total)
                      : context.l10n.usageFreeMinutesRemaining(
                          remaining,
                          total,
                        ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              if (isPro) const ProBadge(),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              minHeight: 4,
              value: progress,
              backgroundColor: context.palette.border,
            ),
          ),
        ],
      ),
    );
  }
}

class AudioFileTile extends StatelessWidget {
  const AudioFileTile({
    required this.name,
    required this.details,
    super.key,
    this.onRemove,
    this.onReplace,
  });

  final String name;
  final String details;
  final VoidCallback? onRemove;
  final VoidCallback? onReplace;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(AppRadii.surface),
        border: Border.all(color: context.palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            const Icon(Icons.audio_file_outlined, size: 28),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(details, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (onReplace != null)
              AppIconButton(
                icon: Icons.swap_horiz,
                tooltip: context.l10n.replaceAudio,
                onPressed: onReplace,
              ),
            if (onRemove != null)
              AppIconButton(
                icon: Icons.close,
                tooltip: context.l10n.removeAudio,
                onPressed: onRemove,
              ),
          ],
        ),
      ),
    );
  }
}

class AudioPlayerBar extends StatelessWidget {
  const AudioPlayerBar({
    required this.playing,
    required this.progress,
    required this.elapsedLabel,
    required this.durationLabel,
    required this.onPlayPause,
    super.key,
    this.onSeek,
  });

  final bool playing;
  final double progress;
  final String elapsedLabel;
  final String durationLabel;
  final VoidCallback onPlayPause;
  final ValueChanged<double>? onSeek;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.audioPlayback(elapsedLabel, durationLabel),
      child: Row(
        children: [
          AppIconButton(
            icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            tooltip: playing ? context.l10n.pauseAudio : context.l10n.playAudio,
            onPressed: onPlayPause,
          ),
          Expanded(
            child: Slider(
              value: progress.clamp(0, 1),
              onChanged: onSeek,
              semanticFormatterCallback: (_) =>
                  context.l10n.audioPlayback(elapsedLabel, durationLabel),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$elapsedLabel / $durationLabel',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

class AudioWaveform extends StatelessWidget {
  const AudioWaveform({
    super.key,
    this.activeFraction = 0.42,
    this.height = 72,
    this.levels,
    this.live = false,
  });

  final double activeFraction;
  final double height;
  final List<double>? levels;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final waveformLevels = List<double>.unmodifiable(
      levels ??
          const [
            0.24,
            0.48,
            0.3,
            0.72,
            0.42,
            0.88,
            0.58,
            0.36,
            0.64,
            0.4,
            0.8,
            0.28,
            0.54,
            0.34,
            0.7,
            0.46,
            0.26,
            0.62,
            0.38,
            0.76,
            0.32,
          ],
    );
    return Semantics(
      image: true,
      label: context.l10n.audioWaveform,
      child: RepaintBoundary(
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: CustomPaint(
            painter: _WaveformPainter(
              levels: waveformLevels,
              activeFraction: activeFraction,
              active: Theme.of(context).colorScheme.primary,
              inactive: context.palette.strongBorder,
              live: live,
              textDirection: Directionality.of(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  const _WaveformPainter({
    required this.levels,
    required this.activeFraction,
    required this.active,
    required this.inactive,
    required this.live,
    required this.textDirection,
  });

  final List<double> levels;
  final double activeFraction;
  final Color active;
  final Color inactive;
  final bool live;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty || size.isEmpty) return;

    final width = math.min(
      8.0,
      math.max(3.0, size.width / (levels.length * 2.4)),
    );
    final gap = levels.length == 1
        ? 0.0
        : (size.width - width) / (levels.length - 1);
    final activeBars = (levels.length * activeFraction.clamp(0, 1)).round();
    final baselinePaint = Paint()
      ..color = active.withValues(alpha: live ? 0.12 : 0.08)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      baselinePaint,
    );

    for (var visualIndex = 0; visualIndex < levels.length; visualIndex++) {
      final dataIndex = textDirection == TextDirection.rtl
          ? levels.length - visualIndex - 1
          : visualIndex;
      final level = levels[dataIndex].clamp(0.0, 1.0);
      final barHeight = math.max(6.0, level * size.height * 0.9);
      final left = visualIndex * gap;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, (size.height - barHeight) / 2, width, barHeight),
        Radius.circular(width / 2),
      );
      final isActive =
          live ||
          (textDirection == TextDirection.rtl
              ? visualIndex >= levels.length - activeBars
              : visualIndex < activeBars);
      final age = levels.length == 1 ? 1.0 : dataIndex / (levels.length - 1);
      canvas.drawRRect(
        rect,
        Paint()
          ..color = isActive
              ? active.withValues(alpha: live ? 0.58 + age * 0.42 : 1)
              : inactive,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.activeFraction != activeFraction ||
        !listEquals(oldDelegate.levels, levels) ||
        oldDelegate.active != active ||
        oldDelegate.inactive != inactive ||
        oldDelegate.live != live ||
        oldDelegate.textDirection != textDirection;
  }
}

enum ProcessingStep { preparing, uploading, transcribing, creating, finalizing }

extension ProcessingStepLabel on ProcessingStep {
  String label(BuildContext context) => switch (this) {
    ProcessingStep.preparing => context.l10n.preparingAudio,
    ProcessingStep.uploading => context.l10n.uploadingSecurely,
    ProcessingStep.transcribing => context.l10n.transcribing,
    ProcessingStep.creating => context.l10n.creatingYourBrief,
    ProcessingStep.finalizing => context.l10n.finalizing,
  };
}

class ProcessingStepIndicator extends StatelessWidget {
  const ProcessingStepIndicator({required this.current, super.key});

  final ProcessingStep current;

  @override
  Widget build(BuildContext context) {
    final currentIndex = ProcessingStep.values.indexOf(current);
    return Semantics(
      liveRegion: true,
      label: current.label(context),
      child: Column(
        children: [
          for (final (index, step) in ProcessingStep.values.indexed)
            Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 44,
                  child: Center(
                    child: AnimatedContainer(
                      duration: AppMotion.quick,
                      width: index == currentIndex ? 12 : 8,
                      height: index == currentIndex ? 12 : 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index <= currentIndex
                            ? Theme.of(context).colorScheme.primary
                            : context.palette.border,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    step.label(context),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: index == currentIndex
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: index < currentIndex
                          ? context.palette.secondaryText
                          : null,
                    ),
                  ),
                ),
                if (index < currentIndex)
                  Icon(
                    Icons.check,
                    color: context.palette.success,
                    size: 20,
                    semanticLabel: context.l10n.complete,
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class ResultSection extends StatelessWidget {
  const ResultSection({
    required this.title,
    required this.child,
    super.key,
    this.onCopy,
  });

  final String title;
  final Widget child;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title,
          action: onCopy == null
              ? null
              : AppIconButton(
                  icon: Icons.copy_outlined,
                  tooltip: context.l10n.copySection(title),
                  onPressed: onCopy,
                ),
        ),
        const SizedBox(height: AppSpacing.sm),
        child,
      ],
    );
  }
}

class SuggestedReplyTile extends StatelessWidget {
  const SuggestedReplyTile({
    required this.tone,
    required this.text,
    required this.onCopy,
    required this.onEdit,
    super.key,
  });

  final String tone;
  final String text;
  final VoidCallback onCopy;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tone, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: AppSpacing.xs),
        Text(text, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            TextButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined, size: 18),
              label: Text(context.l10n.copy),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: Text(context.l10n.edit),
            ),
          ],
        ),
      ],
    );
  }
}

class SubscriptionOptionTile extends StatelessWidget {
  const SubscriptionOptionTile({
    required this.title,
    required this.price,
    required this.selected,
    required this.onTap,
    super.key,
    this.subtitle,
    this.badge,
  });

  final String title;
  final String price;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      label: '$title, $price${badge == null ? '' : ', $badge'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.surface),
        child: AnimatedContainer(
          duration: AppMotion.quick,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.surface),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : context.palette.strongBorder,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : context.palette.secondaryText,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (badge != null) ProBadge(label: badge!),
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      price,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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

class ProBadge extends StatelessWidget {
  const ProBadge({super.key, this.label = 'PRO'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

Future<void> copyText(
  BuildContext context,
  String text, {
  String? confirmation,
}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    AppToast.show(context, confirmation ?? context.l10n.copied);
  }
}
