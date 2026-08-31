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
        title: const Text('أداء الضمان'),
        actions: [
          IconButton(
            tooltip: 'تصدير المطالبات CSV',
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
                  'صحة خدمة ما بعد البيع',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 5),
                Text(
                  'أرقام تشغيلية تساعدك على تقليل التأخير وتحسين قرار الضمان.',
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
                          label: 'مطالبات مفتوحة',
                          value: '$openClaims',
                          icon: Icons.inbox_outlined,
                        ),
                        _ReportMetric(
                          width: width,
                          label: 'مطالبات متأخرة',
                          value: '$overdueClaims',
                          icon: Icons.warning_amber_rounded,
                          warning: overdueClaims > 0,
                        ),
                        _ReportMetric(
                          width: width,
                          label: 'نسبة القبول',
                          value: decidedClaims == 0
                              ? '—'
                              : '${(approvedClaims.length / decidedClaims * 100).round()}%',
                          icon: Icons.task_alt_outlined,
                        ),
                        _ReportMetric(
                          width: width,
                          label: 'متوسط وقت القبول',
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
                          label: 'متوسط وقت الإغلاق',
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
                          label: 'ضمانات سارية',
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
                  title: 'أسباب المطالبات',
                  emptyLabel: 'لا توجد مطالبات مصنفة بعد.',
                  values: {
                    for (final category in ClaimCategory.values)
                      category.label: requests
                          .where((item) => item.category == category)
                          .length,
                  },
                ),
                const SizedBox(height: 14),
                _ClaimBreakdownCard(
                  title: 'قرارات المعالجة',
                  emptyLabel: 'تظهر القرارات بعد إغلاق أول مطالبة.',
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
                    title: const Text(
                      'تصدير سجل المطالبات CSV',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'يشمل الحالة والأولوية والمسؤول والقرار وأوقات المعالجة.',
                    ),
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
                    title: const Text(
                      'تصدير سجل الضمانات CSV',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${warranties.length} ضمان • العملة ${store.currencyCode}',
                    ),
                    trailing: const Icon(Icons.ios_share_outlined),
                    onTap: () => _exportWarrantiesCsv(context),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'آخر النشاطات',
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
    if (minutes < 60) return '$minutes د';
    final hours = minutes / 60;
    if (hours < 24) return '${hours.toStringAsFixed(hours < 10 ? 1 : 0)} س';
    return '${(hours / 24).toStringAsFixed(1)} يوم';
  }

  Future<void> _exportClaimsCsv(BuildContext context) async {
    final controller = AppScope.of(context);
    final rows = <List<String>>[
      [
        'رقم المطالبة',
        'رقم الضمان',
        'المنتج',
        'العميل',
        'المشكلة',
        'الفئة',
        'الأولوية',
        'الحالة',
        'القرار',
        'المسؤول',
        'تاريخ الإنشاء',
        'آخر تحديث',
        'موعد الخدمة',
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
      'تقرير مطالبات ${controller.store!.name}',
    );
  }

  Future<void> _exportWarrantiesCsv(BuildContext context) async {
    final controller = AppScope.of(context);
    final rows = <List<String>>[
      [
        'رقم الإيصال',
        'رقم الضمان',
        'التاريخ',
        'العميل',
        'الجوال',
        'المنتج',
        'السعر',
        'الخصم',
        'الإجمالي',
        'العملة',
        'طريقة الدفع',
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
      'تقرير ضمانات ${controller.store!.name}',
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
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('سيظهر هنا سجل تغييرات المنتجات والضمانات والفروع.'),
      ),
    );
  }
}

class _ActivityUnavailable extends StatelessWidget {
  const _ActivityUnavailable();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Text('سجل النشاط متاح للمالك والمدير فقط.'),
      ),
    );
  }
}
