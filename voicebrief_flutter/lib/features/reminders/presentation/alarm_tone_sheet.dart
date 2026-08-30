import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:voicebrief/core/platform/reminder_launcher.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

Future<ReminderTone?> showAlarmToneSheet({
  required BuildContext context,
  required ReminderTone initialTone,
}) {
  return showModalBottomSheet<ReminderTone>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _AlarmToneSheet(initialTone: initialTone),
  );
}

String alarmToneLabel(BuildContext context, ReminderTone tone) => tone.isCustom
    ? tone.displayName ?? context.l10n.customAlarmSound
    : context.l10n.systemAlarmSound;

class _AlarmToneSheet extends StatefulWidget {
  const _AlarmToneSheet({required this.initialTone});

  final ReminderTone initialTone;

  @override
  State<_AlarmToneSheet> createState() => _AlarmToneSheetState();
}

class _AlarmToneSheetState extends State<_AlarmToneSheet> {
  late ReminderTone _selected;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialTone;
  }

  Future<void> _import(FileType type) async {
    final selected = await FilePicker.pickFile(
      type: type,
      dialogTitle: type == FileType.video
          ? context.l10n.importVideoSound
          : context.l10n.importAudioSound,
    );
    if (selected == null || !mounted) return;
    final sourcePath = selected.path;
    if (sourcePath == null || sourcePath.isEmpty) {
      AppToast.show(context, context.l10n.soundImportFailed);
      return;
    }
    setState(() => _importing = true);
    try {
      final tone = await ReminderLauncher.importTone(
        sourcePath: sourcePath,
        displayName: selected.name,
      );
      if (!mounted) return;
      if (tone == null) {
        AppToast.show(context, context.l10n.soundImportFailed);
        return;
      }
      await ReminderLauncher.setPreferredTone(tone);
      if (!mounted) return;
      setState(() => _selected = tone);
      AppToast.show(context, context.l10n.importedSoundReady);
      await ReminderLauncher.preview(tone);
    } on Object {
      if (mounted) AppToast.show(context, context.l10n.soundImportFailed);
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  Future<void> _confirm() async {
    await ReminderLauncher.setPreferredTone(_selected);
    if (mounted) Navigator.of(context).pop(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.page,
          0,
          AppSpacing.page,
          AppSpacing.page + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              context.l10n.chooseAlarmTone,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.chooseAlarmToneDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.palette.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _ToneOption(
              title: context.l10n.systemAlarmSound,
              subtitle: context.l10n.systemAlarmSoundDescription,
              selected: !_selected.isCustom,
              icon: Icons.notifications_active_outlined,
              onSelected: () =>
                  setState(() => _selected = const ReminderTone.system()),
            ),
            if (_selected.isCustom) ...[
              const SizedBox(height: AppSpacing.sm),
              _ToneOption(
                title: _selected.displayName ?? context.l10n.customAlarmSound,
                subtitle: context.l10n.customAlarmSound,
                selected: true,
                icon: Icons.graphic_eq_rounded,
                onSelected: () {},
                onPreview: () => ReminderLauncher.preview(_selected),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.l10n.addCustomAlarmSound,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.soundLimitNotice,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.palette.secondaryText,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: context.l10n.importAudioSound,
              icon: Icons.audio_file_outlined,
              onPressed: _importing ? null : () => _import(FileType.audio),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppSecondaryButton(
              label: context.l10n.importVideoSound,
              icon: Icons.video_file_outlined,
              onPressed: _importing ? null : () => _import(FileType.video),
            ),
            if (_importing) ...[
              const SizedBox(height: AppSpacing.md),
              AppLoadingView(label: context.l10n.preparingAlarmSound),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppPrimaryButton(
              label: context.l10n.useThisSound,
              icon: Icons.check_rounded,
              onPressed: _importing ? null : _confirm,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToneOption extends StatelessWidget {
  const _ToneOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.icon,
    required this.onSelected,
    this.onPreview,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final IconData icon;
  final VoidCallback onSelected;
  final VoidCallback? onPreview;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected
            ? primary.withValues(alpha: 0.10)
            : context.palette.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.surface),
          side: BorderSide(
            color: selected ? primary : context.palette.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: selected
                          ? primary.withValues(alpha: 0.14)
                          : context.palette.elevatedSurface,
                      borderRadius: BorderRadius.circular(AppRadii.control),
                    ),
                    child: Icon(icon, color: selected ? primary : null),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.palette.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  if (onPreview != null)
                    AppIconButton(
                      icon: Icons.play_arrow_rounded,
                      tooltip: context.l10n.previewTone,
                      onPressed: onPreview,
                    )
                  else
                    Icon(
                      selected
                          ? Icons.check_circle_rounded
                          : Icons.circle_outlined,
                      color: selected ? primary : context.palette.strongBorder,
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
