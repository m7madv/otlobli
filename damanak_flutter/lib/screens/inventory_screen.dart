import 'package:damanak/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../models/account.dart';
import '../models/branch.dart';
import '../models/inventory.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';
import 'scanner_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(returnBarcode: true),
      ),
    );
    if (code != null && mounted) setState(() => _search.text = code);
  }

  Future<void> _adjust(Product product, InventoryLevel? level) async {
    final draft = await showModalBottomSheet<_InventoryDraft>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _AdjustmentSheet(product: product, level: level),
    );
    if (draft == null || !mounted) return;
    await AppScope.of(context).adjustInventory(
      branchId: AppScope.of(context).activeBranch!.id,
      productId: product.id,
      newQuantity: draft.quantity,
      unitCost: draft.unitCost,
      note: draft.note,
    );
  }

  Future<void> _transfer(Product product, InventoryLevel level) async {
    final controller = AppScope.of(context);
    final draft = await showModalBottomSheet<_TransferDraft>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _TransferSheet(
        product: product,
        source: controller.activeBranch!,
        destinations: controller.branches
            .where((branch) => branch.id != controller.activeBranch!.id)
            .toList(),
        available: level.available,
      ),
    );
    if (draft == null || !mounted) return;
    await controller.transferInventory(
      productId: product.id,
      fromBranchId: controller.activeBranch!.id,
      toBranchId: draft.destinationId,
      quantity: draft.quantity,
      note: draft.note,
    );
  }

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    final branch = controller.activeBranch;
    final canManage = controller.membership!.role.canManageTeam;
    final rows = controller.products
        .where((product) => product.matches(_search.text))
        .map(
          (product) =>
              (product, controller.inventoryLevel(product.id, branch?.id)),
        )
        .toList();
    final lowCount = rows.where((row) => row.$2?.isLow ?? true).length;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        L10n.current.msga0e7c1b2423d,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        L10n.current.msg77ec83154126,
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const MessageBanner(),
                      Row(
                        children: [
                          Expanded(
                            child: _InventoryMetric(
                              label: L10n.current.msgcdc1331ab21e,
                              value: '${rows.length}',
                              icon: Icons.inventory_2_outlined,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: _InventoryMetric(
                              label: L10n.current.msg93020592faa0,
                              value: '$lowCount',
                              icon: Icons.warning_amber_rounded,
                              alert: lowCount > 0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (controller.branches.length > 1)
                        DropdownButtonFormField<String>(
                          initialValue: branch?.id,
                          decoration: InputDecoration(
                            labelText: L10n.current.msg90bc2bfaccb2,
                            prefixIcon: Icon(Icons.storefront_outlined),
                          ),
                          items: controller.branches
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    '${item.name} • ${item.type.label}',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) controller.selectBranch(value);
                          },
                        ),
                      if (controller.branches.length > 1)
                        const SizedBox(height: 10),
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: L10n.current.msg5b37a29b3f7e,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            onPressed: _scan,
                            tooltip: L10n.current.msgef037f26c21d,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 2, 18, 100),
                sliver: SliverList.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 9),
                  itemBuilder: (_, index) {
                    final product = rows[index].$1;
                    final level = rows[index].$2;
                    return _InventoryTile(
                      product: product,
                      level: level,
                      currency: controller.store!.currencyCode,
                      onAdjust: canManage
                          ? () => _adjust(product, level)
                          : null,
                      onTransfer:
                          canManage &&
                              level != null &&
                              level.available > 0 &&
                              controller.branches.length > 1
                          ? () => _transfer(product, level)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryMetric extends StatelessWidget {
  const _InventoryMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.alert = false,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool alert;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: alert
            ? context.colors.error.withValues(alpha: .4)
            : context.colors.outlineVariant,
      ),
    ),
    child: Row(
      children: [
        Icon(
          icon,
          color: alert ? context.colors.error : context.colors.primary,
        ),
        const SizedBox(width: 9),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({
    required this.product,
    required this.level,
    required this.currency,
    required this.onAdjust,
    required this.onTransfer,
  });
  final Product product;
  final InventoryLevel? level;
  final String currency;
  final VoidCallback? onAdjust;
  final VoidCallback? onTransfer;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final isLow = level?.isLow ?? true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 52,
              decoration: BoxDecoration(
                color: isLow
                    ? context.colors.errorContainer
                    : context.colors.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                isLow ? Icons.inventory_outlined : Icons.inventory_2_outlined,
                color: isLow ? context.colors.error : context.colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${product.sku}${product.isSerialized ? L10n.knownLabel(' • متسلسل') : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: [
                      Text(
                        L10n.current.msg3c5264e88fce(level?.available ?? 0),
                        style: TextStyle(
                          color: isLow
                              ? context.colors.error
                              : context.colors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        L10n.current.msg5ca3e9ac1e4c(
                          level?.reorderPoint ?? product.reorderPoint,
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        L10n.current.msg00c439c9e1cc(
                          formatMoney(
                            level?.averageCost ?? product.costPrice ?? 0,
                            currency,
                          ),
                        ),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (onAdjust != null)
              PopupMenuButton<String>(
                tooltip: L10n.current.msg8330a0c71014,
                onSelected: (value) =>
                    value == 'adjust' ? onAdjust!() : onTransfer?.call(),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'adjust',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.tune_rounded),
                      title: Text(L10n.current.msg21ee6ce92265),
                    ),
                  ),
                  if (onTransfer != null)
                    PopupMenuItem(
                      value: 'transfer',
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.swap_horiz_rounded),
                        title: Text(L10n.current.msg0c19e9d7514c),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _AdjustmentSheet extends StatefulWidget {
  const _AdjustmentSheet({required this.product, required this.level});
  final Product product;
  final InventoryLevel? level;
  @override
  State<_AdjustmentSheet> createState() => _AdjustmentSheetState();
}

class _AdjustmentSheetState extends State<_AdjustmentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;
  late final TextEditingController _cost;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: '${widget.level?.onHand ?? 0}');
    _cost = TextEditingController(
      text: '${widget.level?.averageCost ?? widget.product.costPrice ?? 0}',
    );
  }

  @override
  void dispose() {
    _quantity.dispose();
    _cost.dispose();
    _note.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.current.msgc26759e06f41(widget.product.name),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            L10n.current.msg18a5dc02e52e,
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _quantity,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: L10n.current.msga8e0fa2ad992,
            ),
            validator: _nonNegative,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _cost,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: L10n.current.msga82a4ab6a00d,
            ),
            validator: _nonNegative,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _note,
            minLines: 2,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: L10n.current.msg046d9847b03a,
              hintText: L10n.current.msgd84e3987c305,
            ),
            validator: (value) => (value?.trim().length ?? 0) < 3
                ? L10n.current.msg3c94b6a4fd15
                : null,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  _InventoryDraft(
                    quantity: num.parse(_quantity.text),
                    unitCost: num.parse(_cost.text),
                    note: _note.text.trim(),
                  ),
                );
              },
              child: Text(L10n.current.msgd8a3c0282316),
            ),
          ),
        ],
      ),
    ),
  );

  String? _nonNegative(String? value) {
    final number = num.tryParse(value ?? '');
    return number == null || number < 0 ? L10n.current.msg981ec91b2ce8 : null;
  }
}

class _TransferSheet extends StatefulWidget {
  const _TransferSheet({
    required this.product,
    required this.source,
    required this.destinations,
    required this.available,
  });
  final Product product;
  final StoreBranch source;
  final List<StoreBranch> destinations;
  final num available;
  @override
  State<_TransferSheet> createState() => _TransferSheetState();
}

class _TransferSheetState extends State<_TransferSheet> {
  late String _destinationId;
  final _quantity = TextEditingController(text: '1');
  final _note = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _destinationId = widget.destinations.first.id;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _note.dispose();
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            L10n.current.msg20c617d828ac(widget.product.name),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            L10n.current.msgee2c7ed76339(widget.source.name, widget.available),
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _destinationId,
            decoration: InputDecoration(
              labelText: L10n.current.msgab8fdcefa964,
            ),
            items: widget.destinations
                .map(
                  (item) =>
                      DropdownMenuItem(value: item.id, child: Text(item.name)),
                )
                .toList(),
            onChanged: (value) => setState(() => _destinationId = value!),
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _quantity,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: L10n.current.msg935e21853946,
            ),
            validator: (value) {
              final quantity = num.tryParse(value ?? '');
              return quantity == null ||
                      quantity <= 0 ||
                      quantity > widget.available
                  ? L10n.current.msge342accfe3ff
                  : null;
            },
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _note,
            decoration: InputDecoration(
              labelText: L10n.current.msgdaa5eccaa4f0,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(
                  context,
                  _TransferDraft(
                    destinationId: _destinationId,
                    quantity: num.parse(_quantity.text),
                    note: _note.text.trim(),
                  ),
                );
              },
              icon: const Icon(Icons.swap_horiz_rounded),
              label: Text(L10n.current.msg7e05ad8ae33d),
            ),
          ),
        ],
      ),
    ),
  );
}

class _InventoryDraft {
  const _InventoryDraft({
    required this.quantity,
    required this.unitCost,
    required this.note,
  });
  final num quantity;
  final num unitCost;
  final String note;
}

class _TransferDraft {
  const _TransferDraft({
    required this.destinationId,
    required this.quantity,
    required this.note,
  });
  final String destinationId;
  final num quantity;
  final String note;
}
