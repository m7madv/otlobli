import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../core/date_utils.dart';
import '../models/warranty.dart';
import '../models/account.dart';
import '../state/app_scope.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final store = controller.store!;
    final warranties = controller.warranties;
    final average = controller.sales.isEmpty
        ? 0
        : controller.totalSales / controller.sales.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير والتصدير'),
        actions: [
          IconButton(
            tooltip: 'تصدير CSV',
            onPressed: () => _exportCsv(context),
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
                  'ملخص المتجر',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth >= 720
                        ? (constraints.maxWidth - 20) / 3
                        : (constraints.maxWidth - 10) / 2;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _ReportMetric(
                          width: width,
                          label: 'إجمالي المبيعات',
                          value: formatMoney(
                            controller.totalSales,
                            store.currencyCode,
                          ),
                          icon: Icons.payments_outlined,
                        ),
                        _ReportMetric(
                          width: width,
                          label: 'مبيعات الشهر',
                          value: formatMoney(
                            controller.currentMonthSales,
                            store.currencyCode,
                          ),
                          icon: Icons.calendar_today_outlined,
                        ),
                        _ReportMetric(
                          width: width,
                          label: 'متوسط الإيصال',
                          value: formatMoney(average, store.currencyCode),
                          icon: Icons.query_stats_outlined,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),
                _BreakdownCard(warranties: warranties),
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
                      'تصدير سجل المبيعات CSV',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'يشمل الإيصال والعميل والمنتج والخصم وطريقة الدفع.',
                    ),
                    trailing: const Icon(Icons.ios_share_outlined),
                    onTap: () => _exportCsv(context),
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

  Future<void> _exportCsv(BuildContext context) async {
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
    final csv = rows.map((row) => row.map(_csvCell).join(',')).join('\r\n');
    final bytes = Uint8List.fromList(utf8.encode('\ufeff$csv'));
    final file = XFile.fromData(
      bytes,
      mimeType: 'text/csv',
      name: 'damanak-sales-${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    final box = context.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: [file.name],
        subject: 'تقرير مبيعات ${controller.store!.name}',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  String _csvCell(String value) => '"${value.replaceAll('"', '""')}"';
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;

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
              Icon(icon, color: colors.primary),
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

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.warranties});

  final Iterable<Warranty> warranties;

  @override
  Widget build(BuildContext context) {
    final counts = <PaymentMethod, int>{
      for (final method in PaymentMethod.values) method: 0,
    };
    for (final warranty in warranties) {
      counts[warranty.paymentMethod] = counts[warranty.paymentMethod]! + 1;
    }
    final total = warranties.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('طرق الدفع', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            ...counts.entries
                .where((entry) => entry.value > 0)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Expanded(child: Text(entry.key.label)),
                        Text('${entry.value} إيصال'),
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
            if (total == 0) const Text('لا توجد مبيعات مسجلة بعد.'),
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
