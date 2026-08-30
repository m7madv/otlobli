import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:voicebrief/core/platform/reminder_launcher.dart';
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
  late Future<List<ScheduledReminder>> _reminders;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reminders = ReminderLauncher.scheduled();
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

  void _reload() {
    if (!mounted) return;
    setState(() => _reminders = ReminderLauncher.scheduled());
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
      appBar: AppTopBar(
        title: context.l10n.voiceBriefAlarms,
        actions: [
          AppIconButton(
            icon: Icons.refresh,
            tooltip: context.l10n.refresh,
            onPressed: _reload,
          ),
        ],
      ),
      body: FutureBuilder<List<ScheduledReminder>>(
        future: _reminders,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AppErrorView(
              message: context.l10n.alarmsUnavailable,
              onRetry: _reload,
            );
          }
          final reminders = snapshot.data ?? const <ScheduledReminder>[];
          if (reminders.isEmpty) {
            return AppEmptyState(
              title: context.l10n.noScheduledAlarms,
              message: context.l10n.noScheduledAlarmsMessage,
              icon: Icons.alarm_off_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final next = await ReminderLauncher.scheduled();
              if (mounted) {
                setState(() => _reminders = Future.value(next));
              }
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.xxl,
              ),
              itemCount: reminders.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _AlarmCard(
                reminder: reminders[index],
                onCancel: () => _cancel(reminders[index]),
              ),
            ),
          );
        },
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
        color: context.palette.surface,
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
                Icon(
                  Icons.alarm_on_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '$date · $time',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _StatusPill(label: context.l10n.alarmScheduled),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.music_note_outlined,
                  size: 18,
                  color: context.palette.secondaryText,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  context.l10n.alarmToneLabel(
                    _soundLabel(context, reminder.sound),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                IconButton(
                  tooltip: context.l10n.previewTone,
                  onPressed: () => ReminderLauncher.preview(reminder.sound),
                  icon: const Icon(Icons.volume_up_outlined),
                ),
                TextButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.alarm_off_outlined, size: 18),
                  label: Text(context.l10n.cancelAlarm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _soundLabel(BuildContext context, ReminderSound sound) =>
      switch (sound) {
        ReminderSound.gentle => context.l10n.alarmToneGentle,
        ReminderSound.bright => context.l10n.alarmToneBright,
        ReminderSound.classic => context.l10n.alarmToneClassic,
      };
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
