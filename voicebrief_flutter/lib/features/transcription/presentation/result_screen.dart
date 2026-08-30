import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/core/platform/calendar_launcher.dart';
import 'package:voicebrief/core/platform/reminder_launcher.dart';
import 'package:voicebrief/features/reminders/presentation/alarm_tone_sheet.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class ResultScreen extends ConsumerWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(
      appControllerProvider.select((value) => value.activeResult),
    );
    if (result == null) {
      return AppScaffold(
        appBar: AppTopBar(title: context.l10n.brief),
        body: AppErrorView(
          message: context.l10n.briefUnavailable,
          onRetry: () => context.go('/app'),
        ),
      );
    }
    final controller = ref.read(appControllerProvider.notifier);
    final allText = _plainText(context, result);
    final replies = result.suggestedReplies;
    final hasReplies =
        replies.short.isNotEmpty ||
        replies.friendly.isNotEmpty ||
        replies.professional.isNotEmpty;
    final detectedDateCount =
        result.importantDates.length +
        result.actionItems
            .where(
              (item) =>
                  item.dueDateIso != null || item.originalDatePhrase != null,
            )
            .length;
    return AppScaffold(
      appBar: AppTopBar(
        title: context.l10n.brief,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: context.l10n.close,
          onPressed: () => context.go('/app'),
        ),
        actions: [
          AppIconButton(
            icon: Icons.copy_all_outlined,
            tooltip: context.l10n.copyAll,
            onPressed: () => copyText(context, allText),
          ),
          AppIconButton(
            icon: Icons.ios_share_outlined,
            tooltip: context.l10n.shareResult,
            onPressed: () => SharePlus.instance.share(
              ShareParams(text: allText, subject: result.title),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          Text(result.title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${result.detectedLanguage.toUpperCase()} · ${result.savedLocally ? context.l10n.savedLocally : context.l10n.notSaved}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (detectedDateCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            _CalendarSummaryBanner(count: detectedDateCount),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppSecondaryButton(
                  label: result.savedLocally
                      ? context.l10n.saved
                      : context.l10n.saveResult,
                  icon: result.savedLocally
                      ? Icons.check
                      : Icons.bookmark_border,
                  onPressed: result.savedLocally
                      ? null
                      : () async {
                          await controller.saveActiveResult();
                          if (context.mounted) {
                            AppToast.show(context, context.l10n.savedLocally);
                          }
                        },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppIconButton(
                icon: Icons.delete_outline,
                tooltip: context.l10n.deleteResult,
                onPressed: () async {
                  final confirmed = await AppDialog.confirm(
                    context: context,
                    title: context.l10n.deleteBriefTitle,
                    message: context.l10n.deleteBriefMessage,
                    confirmLabel: context.l10n.delete,
                    destructive: true,
                  );
                  if (!confirmed) return;
                  unawaited(controller.deleteResult(result.id));
                  if (context.mounted) context.go('/app');
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          ResultSection(
            title: context.l10n.brief,
            onCopy: () => copyText(context, result.summary),
            child: SelectableText(
              result.summary,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          if (result.keyPoints.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const AppDivider(),
            const SizedBox(height: AppSpacing.xl),
            ResultSection(
              title: context.l10n.keyPoints,
              onCopy: () => copyText(context, result.keyPoints.join('\n')),
              child: Column(
                children: result.keyPoints
                    .map((point) => _Bullet(text: point))
                    .toList(growable: false),
              ),
            ),
          ],
          if (result.actionItems.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const AppDivider(),
            const SizedBox(height: AppSpacing.xl),
            ResultSection(
              title: context.l10n.actionItems,
              onCopy: () => copyText(
                context,
                result.actionItems.map((item) => item.title).join('\n'),
              ),
              child: Column(
                children: [
                  for (final item in result.actionItems)
                    AppListTile(
                      title: item.title,
                      subtitle: [
                        if (item.owner != null)
                          context.l10n.ownerLabel(item.owner!),
                        if (item.originalDatePhrase != null)
                          context.l10n.heardLabel(item.originalDatePhrase!),
                      ].join(' · '),
                      leading: const Icon(Icons.check_box_outline_blank),
                      trailing:
                          item.dueDateIso == null &&
                              item.originalDatePhrase == null
                          ? null
                          : _DateActions(
                              onReminder: () => _confirmAndScheduleReminder(
                                context,
                                identifier: result.id,
                                title: item.title,
                                originalPhrase:
                                    item.originalDatePhrase ??
                                    context.l10n.taskDeadline,
                                dateIso: item.dueDateIso,
                                requiresConfirmation:
                                    item.dueDateIso == null ||
                                    _isDateOnly(item.dueDateIso) ||
                                    _timeIsAmbiguous(
                                      item.originalDatePhrase ?? '',
                                    ),
                              ),
                              onCalendar: () => _confirmAndAddCalendarEvent(
                                context,
                                title: item.title,
                                originalPhrase:
                                    item.originalDatePhrase ??
                                    context.l10n.taskDeadline,
                                dateIso: item.dueDateIso,
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ],
          if (result.importantDates.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const AppDivider(),
            const SizedBox(height: AppSpacing.xl),
            ResultSection(
              title: context.l10n.importantDates,
              child: Column(
                children: [
                  for (final date in result.importantDates)
                    AppListTile(
                      title: date.label,
                      subtitle:
                          '${context.l10n.heardLabel(date.originalPhrase)}${date.requiresConfirmation ? ' · ${context.l10n.needsConfirmation}' : ''}',
                      leading: const Icon(Icons.event_outlined),
                      trailing: _DateActions(
                        onReminder: () => _confirmAndScheduleReminder(
                          context,
                          identifier: result.id,
                          title: date.label,
                          originalPhrase: date.originalPhrase,
                          dateIso: date.dateIso,
                          requiresConfirmation:
                              date.requiresConfirmation ||
                              _timeIsAmbiguous(date.originalPhrase),
                        ),
                        onCalendar: () => _confirmAndAddCalendarEvent(
                          context,
                          title: date.label,
                          originalPhrase: date.originalPhrase,
                          dateIso: date.dateIso,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (hasReplies) ...[
            const SizedBox(height: AppSpacing.xl),
            const AppDivider(),
            const SizedBox(height: AppSpacing.xl),
            ResultSection(
              title: context.l10n.suggestedReplies,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (replies.short.isNotEmpty)
                    SuggestedReplyTile(
                      tone: context.l10n.shortTone,
                      text: replies.short,
                      onCopy: () => copyText(context, replies.short),
                      onEdit: () => _editReply(
                        context,
                        context.l10n.shortReply,
                        replies.short,
                      ),
                    ),
                  if (replies.friendly.isNotEmpty) ...[
                    if (replies.short.isNotEmpty) const AppDivider(),
                    SuggestedReplyTile(
                      tone: context.l10n.friendlyTone,
                      text: replies.friendly,
                      onCopy: () => copyText(context, replies.friendly),
                      onEdit: () => _editReply(
                        context,
                        context.l10n.friendlyReply,
                        replies.friendly,
                      ),
                    ),
                  ],
                  if (replies.professional.isNotEmpty) ...[
                    if (replies.short.isNotEmpty || replies.friendly.isNotEmpty)
                      const AppDivider(),
                    SuggestedReplyTile(
                      tone: context.l10n.professionalTone,
                      text: replies.professional,
                      onCopy: () => copyText(context, replies.professional),
                      onEdit: () => _editReply(
                        context,
                        context.l10n.professionalReply,
                        replies.professional,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          const AppDivider(),
          const SizedBox(height: AppSpacing.xl),
          if (result.transcript.isNotEmpty)
            Theme(
              data: Theme.of(
                context,
              ).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(top: AppSpacing.sm),
                title: Text(context.l10n.fullTranscript),
                subtitle: Text(context.l10n.fullTranscriptDescription),
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AppIconButton(
                      icon: Icons.copy_outlined,
                      tooltip: context.l10n.copySection(
                        context.l10n.fullTranscript,
                      ),
                      onPressed: () => copyText(context, result.transcript),
                    ),
                  ),
                  SelectableText(
                    result.transcript,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  static String _plainText(BuildContext context, BriefResult result) {
    return '${result.title}\n\n${context.l10n.brief}\n${result.summary}\n\n${context.l10n.keyPoints}\n${result.keyPoints.map((item) => '• $item').join('\n')}\n\n${context.l10n.actionItems}\n${result.actionItems.map((item) => '□ ${item.title}').join('\n')}\n\n${context.l10n.importantDates}\n${result.importantDates.map((date) => '• ${date.label}: ${date.originalPhrase}').join('\n')}\n\n${context.l10n.suggestedReplies}\n${context.l10n.shortTone}: ${result.suggestedReplies.short}\n${context.l10n.friendlyTone}: ${result.suggestedReplies.friendly}\n${context.l10n.professionalTone}: ${result.suggestedReplies.professional}\n\n${context.l10n.fullTranscript}\n${result.transcript}';
  }

  static Future<void> _editReply(
    BuildContext context,
    String title,
    String initial,
  ) async {
    final textController = TextEditingController(text: initial);
    await AppSheet.show<void>(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.page),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: textController,
              minLines: 3,
              maxLines: 6,
              autofocus: true,
              decoration: InputDecoration(labelText: context.l10n.replyText),
            ),
            const SizedBox(height: AppSpacing.md),
            AppPrimaryButton(
              label: context.l10n.shareEditedReply,
              icon: Icons.ios_share_outlined,
              onPressed: () async {
                await SharePlus.instance.share(
                  ShareParams(text: textController.text),
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            AppSecondaryButton(
              label: context.l10n.copyEditedReply,
              icon: Icons.copy_outlined,
              onPressed: () => copyText(context, textController.text),
            ),
          ],
        ),
      ),
    );
    textController.dispose();
  }

  static Future<void> _confirmAndAddCalendarEvent(
    BuildContext context, {
    required String title,
    required String originalPhrase,
    required String? dateIso,
  }) async {
    final parsed = dateIso == null ? null : DateTime.tryParse(dateIso);
    final isDateOnly =
        dateIso != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateIso);
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate:
          parsed?.toLocal() ?? DateTime.now().add(const Duration(days: 1)),
      helpText: context.l10n.confirmDatePhrase(originalPhrase),
    );
    if (selectedDate == null || !context.mounted) return;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: parsed == null || isDateOnly
          ? const TimeOfDay(hour: 17, minute: 0)
          : TimeOfDay.fromDateTime(parsed.toLocal()),
      helpText: context.l10n.confirmEventTime,
    );
    if (selectedTime == null || !context.mounted) return;
    final start = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    final calendarDescription = context.l10n.calendarDescription(
      originalPhrase,
    );
    final confirmed = await AppDialog.confirm(
      context: context,
      title: context.l10n.openCalendarTitle,
      message: context.l10n.openCalendarMessage(
        originalPhrase,
        '${MaterialLocalizations.of(context).formatFullDate(start)} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(start))}',
      ),
      confirmLabel: context.l10n.openCalendar,
    );
    if (!confirmed) return;
    final opened = await CalendarLauncher.openEvent(
      title: title,
      description: calendarDescription,
      start: start,
      end: start.add(const Duration(hours: 1)),
    );
    if (context.mounted && opened) {
      AppToast.show(context, context.l10n.calendarOpened);
    }
  }

  static Future<void> _confirmAndScheduleReminder(
    BuildContext context, {
    required String identifier,
    required String title,
    required String originalPhrase,
    required String? dateIso,
    required bool requiresConfirmation,
  }) async {
    final parsed = dateIso == null ? null : DateTime.tryParse(dateIso);
    final dateOnly = _isDateOnly(dateIso);
    DateTime? fireAt;
    if (!requiresConfirmation && parsed != null && !dateOnly) {
      fireAt = parsed.toLocal();
    } else {
      final selectedDate = await showDatePicker(
        context: context,
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 3650)),
        initialDate:
            parsed?.toLocal() ?? DateTime.now().add(const Duration(days: 1)),
        helpText: context.l10n.confirmDatePhrase(originalPhrase),
      );
      if (selectedDate == null || !context.mounted) return;
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: _initialReminderTime(
          parsed: parsed,
          dateOnly: dateOnly,
          originalPhrase: originalPhrase,
        ),
        helpText: context.l10n.confirmEventTime,
      );
      if (selectedTime == null || !context.mounted) return;
      fireAt = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      );
    }
    if (!fireAt.isAfter(DateTime.now())) {
      if (context.mounted) {
        AppToast.show(context, context.l10n.reminderMustBeFuture);
      }
      return;
    }
    var tone = const ReminderTone.system();
    if (Platform.isIOS) {
      final preferredTone = await ReminderLauncher.preferredTone();
      if (!context.mounted) return;
      final selectedTone = await showAlarmToneSheet(
        context: context,
        initialTone: preferredTone,
      );
      if (selectedTone == null || !context.mounted) return;
      tone = selectedTone;
    }
    try {
      final scheduled = await ReminderLauncher.schedule(
        identifier:
            '$identifier-${fireAt.millisecondsSinceEpoch}-${title.hashCode.abs()}',
        title: context.l10n.reminderNotificationTitle(title),
        body: context.l10n.reminderNotificationBody(originalPhrase),
        fireAt: fireAt,
        tone: tone,
      );
      if (context.mounted) {
        if (scheduled == null) {
          AppToast.show(context, context.l10n.reminderUnavailable);
        } else if (Platform.isIOS) {
          AppToast.show(context, context.l10n.reminderSet);
          await context.push('/alarms');
        } else {
          AppToast.show(context, context.l10n.reminderSet);
        }
      }
    } on Object {
      if (context.mounted) {
        AppToast.show(context, context.l10n.reminderUnavailable);
      }
    }
  }

  static bool _isDateOnly(String? dateIso) =>
      dateIso != null && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(dateIso);

  static bool _timeIsAmbiguous(String phrase) {
    final normalized = _normalizedTimePhrase(phrase);
    final hasClock = RegExp(r'(?:الساعه|ساعه)\s+').hasMatch(normalized);
    final hasPeriod = RegExp(
      r'(?:صباح|الصبح|فجرا|مساء|المساء|المسا|ليل|بالليل|\bam\b|\bpm\b)',
    ).hasMatch(normalized);
    return hasClock && !hasPeriod;
  }

  static TimeOfDay _initialReminderTime({
    required DateTime? parsed,
    required bool dateOnly,
    required String originalPhrase,
  }) {
    if (parsed != null && !dateOnly) {
      return TimeOfDay.fromDateTime(parsed.toLocal());
    }
    return _spokenTime(originalPhrase) ?? const TimeOfDay(hour: 17, minute: 0);
  }

  static TimeOfDay? _spokenTime(String phrase) {
    final normalized = _normalizedTimePhrase(phrase);
    final match = RegExp(
      r'(?:الساعه|ساعه)\s+([^\s،,.؛;!?؟]+)',
    ).firstMatch(normalized);
    if (match == null) return null;
    var token = match.group(1)!;
    if (token.startsWith('ال') && token.length > 2) token = token.substring(2);
    const numbers = <String, int>{
      'واحد': 1,
      'واحده': 1,
      'اولي': 1,
      'اثنين': 2,
      'اثنان': 2,
      'ثانيه': 2,
      'ثلاثه': 3,
      'ثالثه': 3,
      'اربعه': 4,
      'رابعه': 4,
      'خمسه': 5,
      'خامسه': 5,
      'سته': 6,
      'سادسه': 6,
      'سبعه': 7,
      'سابعه': 7,
      'ثمانيه': 8,
      'ثامنه': 8,
      'تسعه': 9,
      'تاسعه': 9,
      'عشره': 10,
      'عاشره': 10,
      'احدعشر': 11,
      'احدي_عشره': 11,
      'اثناعشر': 12,
      'ثانيه_عشره': 12,
    };
    var hour = int.tryParse(token) ?? numbers[token];
    if (hour == null || hour < 1 || hour > 12) return null;
    final minute = RegExp(r'(?:ونص|والنصف)').hasMatch(normalized)
        ? 30
        : RegExp(r'(?:وربع|والربع)').hasMatch(normalized)
        ? 15
        : 0;
    final morning = RegExp(r'(?:صباح|الصبح|فجرا|\bam\b)').hasMatch(normalized);
    final evening = RegExp(
      r'(?:مساء|المساء|المسا|ليل|بالليل|\bpm\b)',
    ).hasMatch(normalized);
    if (evening && hour < 12) hour += 12;
    if (morning && hour == 12) hour = 0;
    if (!morning && !evening && hour < 12) hour += 12;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String _normalizedTimePhrase(String phrase) {
    const arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    const persianDigits = '۰۱۲۳۴۵۶۷۸۹';
    final converted = StringBuffer();
    for (final rune in phrase.runes) {
      final character = String.fromCharCode(rune);
      final arabicIndex = arabicDigits.indexOf(character);
      final persianIndex = persianDigits.indexOf(character);
      converted.write(
        arabicIndex >= 0
            ? arabicIndex
            : persianIndex >= 0
            ? persianIndex
            : character,
      );
    }
    return converted
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064b-\u065f\u0670]'), '')
        .replaceAll(RegExp('[إأآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
  }
}

class _DateActions extends StatelessWidget {
  const _DateActions({required this.onReminder, required this.onCalendar});

  final VoidCallback onReminder;
  final VoidCallback onCalendar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: onReminder,
          icon: const Icon(Icons.alarm_add_outlined, size: 18),
          label: Text(context.l10n.setReminder),
        ),
        TextButton.icon(
          onPressed: onCalendar,
          icon: const Icon(Icons.event_outlined, size: 18),
          label: Text(context.l10n.addToCalendar),
        ),
      ],
    );
  }
}

class _CalendarSummaryBanner extends StatelessWidget {
  const _CalendarSummaryBanner({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: context.l10n.datesFoundSemantics(count),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(AppRadii.control),
          border: Border.all(color: context.palette.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Row(
            children: [
              Icon(
                Icons.event_available_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  context.l10n.datesFound(count),
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

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
        ],
      ),
    );
  }
}
