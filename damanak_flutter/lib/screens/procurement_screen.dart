import 'package:damanak/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../core/date_utils.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';

class ProcurementScreen extends StatelessWidget {
  const ProcurementScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: Scaffold(
      appBar: AppBar(
        title: Text(L10n.current.msgb303479250b4),
        bottom: TabBar(
          tabs: [
            Tab(text: L10n.current.msg37d10770219f),
            Tab(text: L10n.current.msge9907912acf6),
          ],
        ),
      ),
      body: const SafeArea(
        child: TabBarView(children: [_OrdersTab(), _SuppliersTab()]),
      ),
    ),
  );
}

class _SuppliersTab extends StatelessWidget {
  const _SuppliersTab();

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            const MessageBanner(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    L10n.current.msg24348f4b9021(controller.suppliers.length),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _editSupplier(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(L10n.current.msg9b286307f684),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (controller.suppliers.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: Text(L10n.current.msg2066172a5f71)),
                ),
              )
            else
              ...controller.suppliers.map(
                (supplier) => Card(
                  margin: const EdgeInsets.only(bottom: 9),
                  child: ListTile(
                    onTap: () => _editSupplier(context, supplier),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.local_shipping_outlined,
                        color: context.colors.primary,
                      ),
                    ),
                    title: Text(
                      supplier.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      [
                        supplier.contactName,
                        supplier.phone,
                        supplier.email,
                      ].where((value) => value.isNotEmpty).join(' • '),
                    ),
                    trailing: const Icon(Icons.edit_outlined),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editSupplier(BuildContext context, [Supplier? supplier]) async {
    final draft = await showModalBottomSheet<_SupplierDraft>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SupplierSheet(supplier: supplier),
    );
    if (draft == null || !context.mounted) return;
    await AppScope.of(context).saveSupplier(
      supplierId: supplier?.id,
      name: draft.name,
      contactName: draft.contact,
      phone: draft.phone,
      email: draft.email,
      taxNumber: draft.taxNumber,
      address: draft.address,
      notes: draft.notes,
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
          children: [
            const MessageBanner(),
            Row(
              children: [
                Expanded(
                  child: Text(
                    L10n.current.msga714623dcee2(
                      controller.purchaseOrders.length,
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                FilledButton.icon(
                  onPressed:
                      controller.suppliers.isEmpty ||
                          controller.products.isEmpty
                      ? null
                      : () => _newOrder(context),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(L10n.current.msg56d621339101),
                ),
              ],
            ),
            if (controller.suppliers.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  L10n.current.msg5453ad7ce99a,
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: 14),
            if (controller.purchaseOrders.isEmpty)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: Text(L10n.current.msg1d610c795c9e)),
                ),
              )
            else
              ...controller.purchaseOrders.map(
                (order) => _OrderCard(order: order),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _newOrder(BuildContext context) async {
    final draft = await showModalBottomSheet<_OrderDraft>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _OrderSheet(),
    );
    if (draft == null || !context.mounted) return;
    await AppScope.of(context).createPurchaseOrder(
      branchId: draft.branchId,
      supplierId: draft.supplierId,
      expectedAt: draft.expectedAt,
      notes: draft.notes,
      lines: draft.lines,
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});
  final PurchaseOrder order;
  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    final supplier = controller.suppliers
        .where((item) => item.id == order.supplierId)
        .firstOrNull;
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
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
                        order.orderNumber,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${supplier?.name ?? L10n.knownLabel('مورد')} • ${formatDate(order.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    order.status.label,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(L10n.current.msgd10984c34bd5(order.lines.length)),
                const Spacer(),
                Text(
                  formatMoney(order.totalCost, controller.store!.currencyCode),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            if (order.status == PurchaseOrderStatus.ordered) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.busy
                      ? null
                      : () => controller.receivePurchaseOrder(order.id),
                  icon: const Icon(Icons.inventory_rounded),
                  label: Text(L10n.current.msgdc3e3b89eb83),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SupplierSheet extends StatefulWidget {
  const _SupplierSheet({this.supplier});
  final Supplier? supplier;
  @override
  State<_SupplierSheet> createState() => _SupplierSheetState();
}

class _SupplierSheetState extends State<_SupplierSheet> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _fields;
  @override
  void initState() {
    super.initState();
    final supplier = widget.supplier;
    _fields = [
      supplier?.name ?? '',
      supplier?.contactName ?? '',
      supplier?.phone ?? '',
      supplier?.email ?? '',
      supplier?.taxNumber ?? '',
      supplier?.address ?? '',
      supplier?.notes ?? '',
    ].map((value) => TextEditingController(text: value)).toList();
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.supplier == null
                  ? L10n.current.msg9e920136dad3
                  : L10n.current.msg491a2b55387d,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 14),
            _field(0, L10n.current.msg881c6f87377c, required: true),
            const SizedBox(height: 9),
            _field(1, L10n.current.msg2d47a8a2f231),
            const SizedBox(height: 9),
            _field(2, L10n.current.msg94b59a5125fb, phone: true),
            const SizedBox(height: 9),
            _field(3, L10n.current.msgddf0fca39a4f, email: true),
            const SizedBox(height: 9),
            _field(5, L10n.current.msg2d110e56d5f5),
            const SizedBox(height: 9),
            _field(6, L10n.current.msgd446d2dc6b81),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  Navigator.pop(
                    context,
                    _SupplierDraft(
                      name: _fields[0].text,
                      contact: _fields[1].text,
                      phone: _fields[2].text,
                      email: _fields[3].text,
                      taxNumber: '',
                      address: _fields[5].text,
                      notes: _fields[6].text,
                    ),
                  );
                },
                child: Text(L10n.current.msg32ffe863ab83),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  Widget _field(
    int index,
    String label, {
    bool required = false,
    bool phone = false,
    bool email = false,
  }) => TextFormField(
    controller: _fields[index],
    keyboardType: phone
        ? TextInputType.phone
        : email
        ? TextInputType.emailAddress
        : null,
    textDirection: phone || email ? TextDirection.ltr : null,
    decoration: InputDecoration(labelText: label),
    validator: required
        ? (value) => (value?.trim().length ?? 0) < 2
              ? L10n.current.msgd5a02f880a17
              : null
        : null,
  );
}

class _OrderSheet extends StatefulWidget {
  const _OrderSheet();
  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  late String _branchId;
  late String _supplierId;
  Product? _product;
  final _quantity = TextEditingController(text: '1');
  final _cost = TextEditingController();
  final _notes = TextEditingController();
  final List<PurchaseOrderLineInput> _lines = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = AppScope.of(context);
    _branchId = controller.activeBranch!.id;
    _supplierId = controller.suppliers.first.id;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _cost.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _addLine() {
    final quantity = num.tryParse(_quantity.text);
    final cost = num.tryParse(_cost.text);
    if (_product == null ||
        quantity == null ||
        quantity <= 0 ||
        cost == null ||
        cost < 0) {
      return;
    }
    setState(() {
      _lines.add(
        PurchaseOrderLineInput(
          productId: _product!.id,
          quantity: quantity,
          unitCost: cost,
        ),
      );
      _product = null;
      _quantity.text = '1';
      _cost.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .9,
      maxChildSize: .96,
      minChildSize: .6,
      builder: (_, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        children: [
          Text(
            L10n.current.msg1c89e0bef044,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _branchId,
            decoration: InputDecoration(
              labelText: L10n.current.msg59daeec17138,
            ),
            items: controller.branches
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: (value) => _branchId = value!,
          ),
          const SizedBox(height: 9),
          DropdownButtonFormField<String>(
            initialValue: _supplierId,
            decoration: InputDecoration(
              labelText: L10n.current.msg4680c31a727f,
            ),
            items: controller.suppliers
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: (value) => _supplierId = value!,
          ),
          const SizedBox(height: 16),
          Text(
            L10n.current.msgcdc1331ab21e,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 9),
          DropdownButtonFormField<Product>(
            initialValue: _product,
            decoration: InputDecoration(
              labelText: L10n.current.msga79e304d96a1,
            ),
            items: controller.products
                .map(
                  (item) =>
                      DropdownMenuItem(value: item, child: Text(item.name)),
                )
                .toList(),
            onChanged: (value) => setState(() {
              _product = value;
              _cost.text = '${value?.costPrice ?? 0}';
            }),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: L10n.current.msg935e21853946,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  controller: _cost,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textDirection: TextDirection.ltr,
                  decoration: InputDecoration(
                    labelText: L10n.current.msg86df419eaf6e,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          OutlinedButton.icon(
            onPressed: _addLine,
            icon: const Icon(Icons.playlist_add_rounded),
            label: Text(L10n.current.msg409af7a5a6d3),
          ),
          const SizedBox(height: 10),
          ..._lines.indexed.map((entry) {
            final product = controller.productById(entry.$2.productId);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(product?.name ?? L10n.current.msgf8720c7412f1),
              subtitle: Text(
                '${entry.$2.quantity} × ${formatMoney(entry.$2.unitCost, controller.store!.currencyCode)}',
              ),
              trailing: IconButton(
                onPressed: () => setState(() => _lines.removeAt(entry.$1)),
                icon: const Icon(Icons.close_rounded),
              ),
            );
          }),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: L10n.current.msg0cdc868b58b7,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _lines.isEmpty
                ? null
                : () => Navigator.pop(
                    context,
                    _OrderDraft(
                      branchId: _branchId,
                      supplierId: _supplierId,
                      expectedAt: null,
                      notes: _notes.text,
                      lines: List.of(_lines),
                    ),
                  ),
            icon: const Icon(Icons.send_outlined),
            label: Text(L10n.current.msgb06d19e66e3b),
          ),
        ],
      ),
    );
  }
}

class _SupplierDraft {
  const _SupplierDraft({
    required this.name,
    required this.contact,
    required this.phone,
    required this.email,
    required this.taxNumber,
    required this.address,
    required this.notes,
  });
  final String name;
  final String contact;
  final String phone;
  final String email;
  final String taxNumber;
  final String address;
  final String notes;
}

class _OrderDraft {
  const _OrderDraft({
    required this.branchId,
    required this.supplierId,
    required this.expectedAt,
    required this.notes,
    required this.lines,
  });
  final String branchId;
  final String supplierId;
  final DateTime? expectedAt;
  final String notes;
  final List<PurchaseOrderLineInput> lines;
}
