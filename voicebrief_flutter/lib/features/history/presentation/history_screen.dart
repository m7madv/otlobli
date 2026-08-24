import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:voicebrief/app/providers.dart';
import 'package:voicebrief/core/utils/formatters.dart';
import 'package:voicebrief/features/transcription/domain/brief_result.dart';
import 'package:voicebrief/l10n/l10n.dart';
import 'package:voicebrief/ui/core/components/app_components.dart';
import 'package:voicebrief/ui/core/theme/app_tokens.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(
      appControllerProvider.select((value) => value.history),
    );
    final query = _search.text.trim().toLowerCase();
    final filtered = history
        .where(
          (item) =>
              query.isEmpty ||
              item.title.toLowerCase().contains(query) ||
              item.summary.toLowerCase().contains(query),
        )
        .toList(growable: false);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.page,
            AppSpacing.page,
            AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.history,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: context.palette.secondaryText,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      context.l10n.historyLocalOnly,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: context.l10n.searchBriefs,
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        const AppDivider(),
        Expanded(
          child: filtered.isEmpty
              ? AppEmptyState(
                  title: history.isEmpty
                      ? context.l10n.nothingSaved
                      : context.l10n.noMatchingBriefs,
                  message: history.isEmpty
                      ? context.l10n.nothingSavedMessage
                      : context.l10n.noMatchingBriefsMessage,
                  icon: history.isEmpty ? Icons.history : Icons.search_off,
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.xs,
                    AppSpacing.page,
                    AppSpacing.xxl,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const AppDivider(indent: 48),
                  itemBuilder: (context, index) =>
                      _HistoryItem(result: filtered[index]),
                ),
        ),
      ],
    );
  }
}

class _HistoryItem extends ConsumerWidget {
  const _HistoryItem({required this.result});

  final BriefResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(result.id),
      direction: DismissDirection.endToStart,
      background: ColoredBox(
        color: Theme.of(context).colorScheme.error,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.page),
            child: Icon(
              Icons.delete_outline,
              color: Colors.white,
              semanticLabel: context.l10n.delete,
            ),
          ),
        ),
      ),
      onDismissed: (_) {
        final controller = ref.read(appControllerProvider.notifier);
        unawaited(controller.deleteResult(result.id));
        AppToast.show(
          context,
          context.l10n.briefDeleted,
          actionLabel: context.l10n.undo,
          onAction: () => controller.restoreResult(result),
        );
      },
      child: AppListTile(
        title: result.title,
        subtitle:
            '${formatDuration(result.audioDurationSeconds)} · ${result.detectedLanguage.toUpperCase()}\n${formatDate(result.processedAt, locale: Localizations.localeOf(context).toLanguageTag())}',
        leading: const Icon(Icons.subject_outlined),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ref.read(appControllerProvider.notifier).openResult(result);
          context.push('/result');
        },
      ),
    );
  }
}
