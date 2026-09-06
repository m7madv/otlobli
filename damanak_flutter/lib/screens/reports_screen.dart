import 'package:damanak/l10n/l10n.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/account.dart';
import '../models/maintenance_request.dart';
import '../models/warranty.dart';
import '../services/spreadsheet_safe_csv.dart';
import '../state/app_scope.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    final store = controller.store!;
    final warranties = controller.warranties;
    final requests = controller.requests;
    final openClaims = requests.where((item) => !item.status.isClosed).length;
    final overdueClaims = requests.where((item) => item.isOverdue).length;
    final approvedClaims = requests
        .where((item) => item.approvedAt != null)
        .toList();
    final completedClaims = requests
        .where((item) => item.completedAt != null)
        .toList();
    final rejectedClaims = requests
        .where((item) => item.status == MaintenanceStatus.rejected)
        .length;
    final decidedClaims = approvedClaims.length + rejectedClaims;
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.current.msg038317a4bdae),
        actions: [
          IconButton(
            tooltip: L10n.current.msg4413206fb3ff,
            onPressed: () => _exportClaimsCsv(context),
            icon: const Icon(Icons.file_download_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                Text(
                  L10n.current.msg3f718fc08a19,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  L10n.current.msgb7166f8ebf05,
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final largeText =
                        MediaQuery.textScalerOf(context).scale(14) > 19;
                    final width = largeText
                        ? constraints.maxWidth
                        : constraints.maxWidth >= 720
                        ? (constraints.maxWidth - 20) / 3
                        : (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ReportMetric(
                          width: width,
                          label: L10n.current.msg3e965378aea3,
                          value: '$openClaims',
                          icon: Icons.inbox_outlined,
                        ),
                        _ReportMetric(
                          width: width,
                          label: L10n.current.msgee61d382e5a9,
                          value: '$overdueClaims',
                          icon: Icons.warning_amber_rounded,
                          warning: overdueClaims > 0,
                        ),
                        _ReportMetric(
                          width: width,
                          label: L10n.current.msgf05f2eb8e683,
                          value: decidedClaims == 0
                              ? '—'
                              : '${(approvedClaims.length / decidedClaims * 100).round()}%',
                          icon: Icons.task_alt_outlined,
                        ),
                        _ReportMetric(
                          width: width,
                          label: L10n.current.msg4274413816a7,
                          value: _averageDuration(
                            approvedClaims.map(
                              (item) =>
                                  item.approvedAt!.difference(item.createdAt),
                            ),
                          ),
                          icon: Icons.speed_outlined,
                        ),
                        _ReportMetric(
                          width: width,
                          label: L10n.current.msgb4908cd47786,
                          value: _averageDuration(
                            completedClaims.map(
                              (item) =>
                                  item.completedAt!.difference(item.createdAt),
                            ),
                          ),
                          icon: Icons.timelapse_rounded,
                        ),
                        _ReportMetric(
                          width: width,
                          label: L10n.current.msge643c6cc697c,
                          value:
                              '${warranties.where((item) => item.statusAt() == WarrantyStatus.active).length}',
                          icon: Icons.verified_user_outlined,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _ClaimBreakdownCard(
                  title: L10n.current.msga5438e52bca2,
                  emptyLabel: L10n.current.msgbc67fe11a8c6,
                  values: {
                    for (final category in ClaimCategory.values)
                      category.label: requests
                          .where((item) => item.category == category)
                          .length,
                  },
                ),
                const SizedBox(height: 14),
                _ClaimBreakdownCard(
                  title: L10n.current.msga6c21ee652c9,
                  emptyLabel: L10n.current.msg2a61a562f417,
                  values: {
                    for (final resolution in ClaimResolution.values)
                      if (resolution != ClaimResolution.none)
                        resolution.label: requests
                            .where((item) => item.resolution == resolution)
                            .length,
                  },
                ),
                const SizedBox(height: 14),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        Icons.table_view_outlined,
                        color: context.colors.primary,
                      ),
                    ),
                    title: Text(
                      L10n.current.msg458477c1157c,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(L10n.current.msgeadba8bd2e70),
                    trailing: const Icon(Icons.ios_share_outlined),
                    onTap: () => _exportClaimsCsv(context),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    leading: const Icon(Icons.receipt_long_outlined),
                    title: Text(
                      L10n.current.msgd0a5192998cd,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      L10n.current.msg2c600aad6d9f(
                        warranties.length,
                        store.currencyCode,
                      ),
                    ),
                    trailing: const Icon(Icons.ios_share_outlined),
                    onTap: () => _exportWarrantiesCsv(context),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  L10n.current.msg623bfa279466,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                if (!controller.membership!.role.canManageTeam)
                  const _ActivityUnavailable()
                else if (controller.auditLogs.isEmpty)
                  const _ActivityEmpty()
                else
                  ...controller.auditLogs
                      .take(20)
                      .map(
                        (event) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.history_rounded),
                            title: Text(
                              '${event.actionLabel} • ${event.entityLabel}',
                            ),
                            subtitle: Text(
                              formatDate(event.createdAt),
                              textDirection: TextDirection.ltr,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _averageDuration(Iterable<Duration> values) {
    final safe = values.where((value) => !value.isNegative).toList();
    if (safe.isEmpty) return '—';
    final minutes =
        safe.fold<int>(0, (sum, value) => sum + value.inMinutes) ~/ safe.length;
    if (minutes < 60) return L10n.current.msg3f2e0dfb89ae(minutes);
    final hours = minutes / 60;
    if (hours < 24) {
      return L10n.current.msg0ad7d321ec09(
        hours.toStringAsFixed(hours < 10 ? 1 : 0),
      );
    }
    return L10n.current.msg435e31311dfe((hours / 24).toStringAsFixed(1));
  }

  Future<void> _exportClaimsCsv(BuildContext context) async {
    final controller = AppScope.of(context);
    final rows = <List<String>>[
      [
        L10n.current.msg9352b360a76f,
        L10n.current.msga97505f65ec3,
        L10n.current.msga79e304d96a1,
        L10n.current.msga042411e90be,
        L10n.current.msg9099527b2932,
        L10n.current.msgff61fb213ffc,
        L10n.current.msg4c3e5a87f1e4,
        L10n.current.msgc3a4749caed4,
        L10n.current.msga881a87897ba,
        L10n.current.msg5087bf126a06,
        L10n.current.msgdc08056fa4f2,
        L10n.current.msg78a3ea160681,
        L10n.current.msg3807bc689d6e,
      ],
      ...controller.requests.map((item) {
        final warranty = controller.warrantyById(item.warrantyId);
        final assignee = controller.teamMemberById(item.assignedTo);
        return [
          item.displayNumber,
          warranty?.displayNumber ?? '',
          warranty?.productName ?? '',
          warranty?.customerName ?? '',
          item.issue,
          item.category.label,
          item.priority.label,
          item.status.label,
          item.resolution.label,
          assignee?.fullName ?? '',
          item.createdAt.toIso8601String(),
          item.updatedAt.toIso8601String(),
          item.slaDueAt?.toIso8601String() ?? '',
        ];
      }),
    ];
    await _shareCsv(
      context,
      rows,
      'damanak-claims',
      L10n.current.msg321eecc7260a(controller.store!.name),
    );
  }

  Future<void> _exportWarrantiesCsv(BuildContext context) async {
    final controller = AppScope.of(context);
    final rows = <List<String>>[
      [
        L10n.current.msg239cb47cd98d,
        L10n.current.msga97505f65ec3,
        L10n.current.msgd90c384199ac,
        L10n.current.msga042411e90be,
        L10n.current.msg0b6aa9453dfb,
        L10n.current.msga79e304d96a1,
        L10n.current.msg259862e8b313,
        L10n.current.msgb593a6457673,
        L10n.current.msgbaed6e999960,
        L10n.current.msg30ce3a1dae2c,
        L10n.current.msgae2d60052976,
      ],
      ...controller.warranties.map(
        (item) => [
          item.invoiceNumber,
          item.displayNumber,
          formatDate(item.purchaseDate),
          item.customerName,
          item.customerPhone,
          item.productName,
          '${item.saleSubtotal}',
          '${item.discountAmount}',
          '${item.saleTotal}',
          item.currencyCode,
          item.paymentMethod.label,
        ],
      ),
    ];
    await _shareCsv(
      context,
      rows,
      'damanak-warranties',
      L10n.current.msg1db2d1d6ed62(controller.store!.name),
      numericColumnIndexes: const {6, 7, 8},
    );
  }

  Future<void> _shareCsv(
    BuildContext context,
    List<List<String>> rows,
    String filePrefix,
    String subject, {
    Set<int> numericColumnIndexes = const {},
  }) async {
    final csv = rows.indexed
        .map(
          (indexedRow) => indexedRow.$2.indexed
              .map(
                (indexedCell) =>
                    indexedRow.$1 > 0 &&
                        numericColumnIndexes.contains(indexedCell.$1)
                    ? spreadsheetSafeCsvNumberCell(indexedCell.$2)
                    : spreadsheetSafeCsvTextCell(indexedCell.$2),
              )
              .join(','),
        )
        .join('\r\n');
    final bytes = Uint8List.fromList(utf8.encode('\ufeff$csv'));
    final file = XFile.fromData(
      bytes,
      mimeType: 'text/csv',
      name: '$filePrefix-${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [file.name],
        subject: subject,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    this.warning = false,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final colors = context.colors;
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: warning ? colors.error : colors.primary),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: colors.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClaimBreakdownCard extends StatelessWidget {
  const _ClaimBreakdownCard({
    required this.title,
    required this.values,
    required this.emptyLabel,
  });

  final String title;
  final Map<String, int> values;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final visible = values.entries.where((entry) => entry.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = visible.fold<int>(0, (sum, entry) => sum + entry.value);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            ...visible.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value}'),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 80,
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : entry.value / total,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (total == 0) Text(emptyLabel),
          ],
        ),
      ),
    );
  }
}

class _ActivityEmpty extends StatelessWidget {
  const _ActivityEmpty();

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text(L10n.current.msg883b8347d313),
      ),
    );
  }
}

class _ActivityUnavailable extends StatelessWidget {
  const _ActivityUnavailable();

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    return Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text(L10n.current.msgd5be13d93eee),
      ),
    );
  }
}
