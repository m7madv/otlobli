import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voicebrief/core/platform/reminder_launcher.dart';
import 'package:voicebrief/features/reminders/presentation/alarm_tone_sheet.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class ScheduledRemindersScreen extends StatefulWidget {
  const ScheduledRemindersScreen({super.key});

  @override
  State<ScheduledRemindersScreen> createState() =>
      _ScheduledRemindersScreenState();
}

class _ScheduledRemindersScreenState extends State<ScheduledRemindersScreen>
    with WidgetsBindingObserver {
  late Future<_AlarmPageData> _data;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _data = _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _reload();
  }

  Future<_AlarmPageData> _load() async {
    final values = await Future.wait<Object>([
      ReminderLauncher.scheduled(),
      ReminderLauncher.preferredTone(),
    ]);
    return _AlarmPageData(
      reminders: values[0] as List<ScheduledReminder>,
      preferredTone: values[1] as ReminderTone,
    );
  }

  void _reload() {
    if (!mounted) return;
    setState(() => _data = _load());
  }

  Future<void> _refresh() async {
    final next = await _load();
    if (mounted) setState(() => _data = Future.value(next));
  }

  Future<void> _changeTone(ReminderTone current) async {
    final tone = await showAlarmToneSheet(
      context: context,
      initialTone: current,
    );
    if (tone != null && mounted) _reload();
  }

  Future<void> _cancel(ScheduledReminder reminder) async {
    final confirmed = await AppDialog.confirm(
      context: context,
      title: context.l10n.cancelAlarmTitle,
      message: context.l10n.cancelAlarmMessage(reminder.title),
      confirmLabel: context.l10n.cancelAlarm,
      destructive: true,
    );
    if (!confirmed) return;
    final cancelled = await ReminderLauncher.cancel(reminder.id);
    if (!mounted) return;
    AppToast.show(
      context,
      cancelled ? context.l10n.alarmCancelled : context.l10n.alarmCancelFailed,
    );
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: AppTopBar(title: context.l10n.voiceBriefAlarms),
      body: FutureBuilder<_AlarmPageData>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return AppLoadingView(label: context.l10n.loadingAlarms);
          }
          if (snapshot.hasError) {
            return AppErrorView(
              message: context.l10n.alarmsUnavailable,
              onRetry: _reload,
            );
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    0,
                  ),
                  sliver: SliverToBoxAdapter(
                    child: _SoundCard(
                      tone: data.preferredTone,
                      onChange: () => _changeTone(data.preferredTone),
                    ),
                  ),
                ),
                if (data.reminders.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _AlarmEmptyState(),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.lg,
                      AppSpacing.page,
                      AppSpacing.sm,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        context.l10n.upcomingAlarms,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      0,
                      AppSpacing.page,
                      AppSpacing.xxl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: data.reminders.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) => _AlarmCard(
                        reminder: data.reminders[index],
                        onCancel: () => _cancel(data.reminders[index]),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AlarmPageData {
  const _AlarmPageData({required this.reminders, required this.preferredTone});

  final List<ScheduledReminder> reminders;
  final ReminderTone preferredTone;
}

class _SoundCard extends StatelessWidget {
  const _SoundCard({required this.tone, required this.onChange});

  final ReminderTone tone;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Material(
      color: context.palette.elevatedSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.surface),
        side: BorderSide(color: context.palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onChange,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 88),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadii.control),
                  ),
                  child: Icon(
                    tone.isCustom
                        ? Icons.graphic_eq_rounded
                        : Icons.notifications_active_outlined,
                    color: primary,
                    size: 27,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.alarmSoundTitle,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: context.palette.secondaryText,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        alarmToneLabel(context, tone),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  context.l10n.changeAlarmSound,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.xxs),
                Icon(
                  Directionality.of(context) == ui.TextDirection.rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  color: primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlarmEmptyState extends StatelessWidget {
  const _AlarmEmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.xl,
        AppSpacing.page,
        AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 330),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _AlarmDial(),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.noScheduledAlarms,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                context.l10n.noScheduledAlarmsMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.palette.secondaryText,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AlarmDial extends StatelessWidget {
  const _AlarmDial();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ExcludeSemantics(
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.palette.elevatedSurface,
          border: Border.all(color: context.palette.strongBorder, width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            for (final alignment in const [
              Alignment.topCenter,
              Alignment.centerRight,
              Alignment.bottomCenter,
              Alignment.centerLeft,
            ])
              Align(
                alignment: alignment,
                child: Container(
                  width: alignment.x == 0 ? 3 : 7,
                  height: alignment.x == 0 ? 7 : 3,
                  margin: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: context.palette.strongBorder,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            Transform.translate(
              offset: const Offset(0, -13),
              child: Container(
                width: 4,
                height: 31,
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(11, 8),
              child: Transform.rotate(
                angle: -0.78,
                child: Container(
                  width: 4,
                  height: 27,
                  decoration: BoxDecoration(
                    color: context.palette.primaryText,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary,
                border: Border.all(
                  color: context.palette.elevatedSurface,
                  width: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlarmCard extends StatelessWidget {
  const _AlarmCard({required this.reminder, required this.onCancel});

  final ScheduledReminder reminder;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final localTime = reminder.fireAt.toLocal();
    final date = DateFormat.yMMMMEEEEd(locale).format(localTime);
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(TimeOfDay.fromDateTime(localTime));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.elevatedSurface,
        borderRadius: BorderRadius.circular(AppRadii.surface),
        border: Border.all(color: context.palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 94,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      time,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        date,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.palette.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Divider(height: 1, color: context.palette.border),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  reminder.tone.isCustom
                      ? Icons.graphic_eq_rounded
                      : Icons.notifications_active_outlined,
                  size: 19,
                  color: context.palette.secondaryText,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    alarmToneLabel(context, reminder.tone),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (reminder.tone.isCustom)
                  AppIconButton(
                    tooltip: context.l10n.previewTone,
                    onPressed: () => ReminderLauncher.preview(reminder.tone),
                    icon: Icons.play_arrow_rounded,
                  ),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: Text(context.l10n.cancelAlarm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
