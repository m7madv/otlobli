import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../core/date_utils.dart';
import '../models/sale.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final query = _search.text.trim().toLowerCase();
    final sales = controller.sales
        .where(
          (sale) =>
              query.isEmpty ||
              sale.invoiceNumber.toLowerCase().contains(query) ||
              sale.customerName.toLowerCase().contains(query) ||
              sale.customerPhone.contains(query),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('المبيعات والمرتجعات')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                const MessageBanner(),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'رقم الإيصال أو العميل أو الهاتف',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                ),
                const SizedBox(height: 14),
                if (sales.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(child: Text('لا توجد مبيعات مطابقة.')),
                    ),
                  )
                else
                  ...sales.map(
                    (sale) =>
                        _SaleTile(sale: sale, onTap: () => _showSale(sale)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSale(SaleTransaction sale) async {
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SaleDetails(sale: sale),
    );
  }
}

class _SaleTile extends StatelessWidget {
  const _SaleTile({required this.sale, required this.onTap});
  final SaleTransaction sale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 9),
    child: ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.colors.primaryContainer,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(Icons.receipt_long_outlined, color: context.colors.primary),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              sale.invoiceNumber,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          _SaleStatusBadge(status: sale.status),
        ],
      ),
      subtitle: Text('${sale.customerName} • ${formatDate(sale.createdAt)}'),
      trailing: Text(
        formatMoney(sale.netTotal, sale.currencyCode),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
  );
}

class _SaleDetails extends StatefulWidget {
  const _SaleDetails({required this.sale});
  final SaleTransaction sale;
  @override
  State<_SaleDetails> createState() => _SaleDetailsState();
}

class _SaleDetailsState extends State<_SaleDetails> {
  final Map<String, num> _returns = {};
  PaymentMethod _method = PaymentMethod.cash;
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submitReturn() async {
    final selected = Map<String, num>.fromEntries(
      _returns.entries.where((entry) => entry.value > 0),
    );
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر كمية واحدة على الأقل للإرجاع.')),
      );
      return;
    }
    if (_reason.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اذكر سبب المرتجع لحفظ سجل واضح.')),
      );
      return;
    }
    await AppScope.of(context).returnSale(
      saleId: widget.sale.id,
      lineQuantities: selected,
      refundMethod: _method,
      reason: _reason.text,
    );
    if (mounted && AppScope.of(context).errorMessage == null) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sale = widget.sale;
    final canReturn =
        sale.status != SaleStatus.returned && sale.status != SaleStatus.voided;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .88,
      maxChildSize: .96,
      minChildSize: .55,
      builder: (_, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sale.invoiceNumber,
                  textDirection: TextDirection.ltr,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              _SaleStatusBadge(status: sale.status),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${sale.customerName} • ${sale.customerPhone}',
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          ...sale.lines.map(
            (line) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.productName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'مباع ${line.quantity} • مرتجع ${line.returnedQuantity}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          formatMoney(line.lineTotal, sale.currencyCode),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    if (canReturn && line.returnableQuantity > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('كمية المرتجع'),
                          const Spacer(),
                          IconButton(
                            onPressed: (_returns[line.id] ?? 0) <= 0
                                ? null
                                : () => setState(
                                    () => _returns[line.id] =
                                        (_returns[line.id] ?? 0) - 1,
                                  ),
                            icon: const Icon(
                              Icons.remove_circle_outline_rounded,
                            ),
                          ),
                          Text(
                            '${_returns[line.id] ?? 0}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            onPressed:
                                (_returns[line.id] ?? 0) >=
                                    line.returnableQuantity
                                ? null
                                : () => setState(
                                    () => _returns[line.id] =
                                        (_returns[line.id] ?? 0) + 1,
                                  ),
                            icon: const Icon(Icons.add_circle_outline_rounded),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SummaryRow(
                    label: 'قبل الخصم',
                    value: formatMoney(sale.subtotal, sale.currencyCode),
                  ),
                  _SummaryRow(
                    label: 'الخصم',
                    value: formatMoney(sale.discountAmount, sale.currencyCode),
                  ),
                  if (sale.refundedAmount > 0)
                    _SummaryRow(
                      label: 'المرتجع',
                      value: formatMoney(
                        sale.refundedAmount,
                        sale.currencyCode,
                      ),
                    ),
                  const Divider(),
                  _SummaryRow(
                    label: 'الصافي',
                    value: formatMoney(sale.netTotal, sale.currencyCode),
                    strong: true,
                  ),
                ],
              ),
            ),
          ),
          if (canReturn) ...[
            const SizedBox(height: 16),
            Text('تسجيل مرتجع', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            DropdownButtonFormField<PaymentMethod>(
              initialValue: _method,
              decoration: const InputDecoration(labelText: 'طريقة رد المبلغ'),
              items: PaymentMethod.values
                  .map(
                    (item) =>
                        DropdownMenuItem(value: item, child: Text(item.label)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _method = value!),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _reason,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'سبب المرتجع'),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: AppScope.of(context).busy ? null : _submitReturn,
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.error,
              ),
              icon: const Icon(Icons.keyboard_return_rounded),
              label: const Text('تأكيد المرتجع'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SaleStatusBadge extends StatelessWidget {
  const _SaleStatusBadge({required this.status});
  final SaleStatus status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: status == SaleStatus.completed
          ? context.colors.primaryContainer
          : context.colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      status.label,
      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });
  final String label;
  final String value;
  final bool strong;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(
          value,
          style: TextStyle(
            fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
            fontSize: strong ? 18 : null,
          ),
        ),
      ],
    ),
  );
}
