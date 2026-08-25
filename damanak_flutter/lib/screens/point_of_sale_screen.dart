import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../models/account.dart';
import '../models/branch.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';
import 'product_form_screen.dart';
import 'scanner_screen.dart';

class PointOfSaleScreen extends StatefulWidget {
  const PointOfSaleScreen({super.key});

  @override
  State<PointOfSaleScreen> createState() => _PointOfSaleScreenState();
}

class _PointOfSaleScreenState extends State<PointOfSaleScreen> {
  final _search = TextEditingController();
  final Map<String, _CartLine> _cart = {};

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
    if (code == null || !mounted) return;
    final product = AppScope.of(context).productByBarcode(code);
    if (product != null) {
      await _add(product);
      return;
    }
    setState(() => _search.text = code);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('الباركود غير مسجل بعد.'),
        action: SnackBarAction(
          label: 'إضافة المنتج',
          onPressed: () {
            Navigator.of(context).push<Product>(
              MaterialPageRoute(
                builder: (_) => ProductFormScreen(initialBarcode: code),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _addFirstProduct() async {
    final product = await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
    if (product != null && mounted) await _add(product);
  }

  Future<void> _add(Product product) async {
    final controller = AppScope.of(context);
    if ((product.salePrice ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('أضف سعر بيع إلى ${product.name} أولاً.')),
      );
      return;
    }
    final stock = controller.inventoryLevel(product.id)?.available ?? 0;
    final current = _cart[product.id];
    if (product.trackInventory && stock <= (current?.quantity ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('نفدت الكمية المتاحة من ${product.name}.')),
      );
      return;
    }
    String? serial;
    if (product.isSerialized) {
      serial = await _askSerial(product);
      if (serial == null || !mounted) return;
    }
    setState(() {
      final line = current ?? _CartLine(product: product);
      _cart[product.id] = line.copyWith(
        quantity: line.quantity + 1,
        serialNumbers: [...line.serialNumbers, ?serial],
      );
    });
  }

  void _decrease(Product product) {
    final line = _cart[product.id];
    if (line == null) return;
    setState(() {
      if (line.quantity <= 1) {
        _cart.remove(product.id);
      } else {
        _cart[product.id] = line.copyWith(
          quantity: line.quantity - 1,
          serialNumbers: line.serialNumbers.isEmpty
              ? const []
              : line.serialNumbers.sublist(0, line.serialNumbers.length - 1),
        );
      }
    });
  }

  Future<String?> _askSerial(Product product) async {
    final existingSerialNumbers = _cart.values
        .expand((line) => line.serialNumbers)
        .map((serial) => serial.trim().toLowerCase())
        .where((serial) => serial.isNotEmpty)
        .toSet();
    return showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SerialNumberSheet(
        product: product,
        existingSerialNumbers: existingSerialNumbers,
      ),
    );
  }

  Future<void> _checkout() async {
    final controller = AppScope.of(context);
    final branch = controller.activeBranch;
    if (branch == null || _cart.isEmpty) return;
    final sale = await showModalBottomSheet<SaleTransaction>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _CheckoutSheet(lines: _cart.values.toList(), branch: branch),
    );
    if (sale == null || !mounted) return;
    setState(_cart.clear);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم البيع وحفظ الإيصال ${sale.invoiceNumber}.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final branch = controller.activeBranch;
    final products = controller.products.where((item) {
      if (!item.matches(_search.text)) return false;
      return branch == null ||
          (controller.inventoryLevel(item.id, branch.id)?.available ?? 0) > 0 ||
          !item.trackInventory;
    }).toList();
    final currency = controller.store!.currencyCode;
    final cartTotal = _cart.values.fold<num>(
      0,
      (sum, line) => sum + line.total,
    );
    final cartCount = _cart.values.fold<num>(
      0,
      (sum, line) => sum + line.quantity,
    );
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'بيع',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          if (controller.branches.length > 1)
                            PopupMenuButton<String>(
                              tooltip: 'تغيير الفرع',
                              initialValue: branch?.id,
                              onSelected: controller.selectBranch,
                              itemBuilder: (_) => controller.branches
                                  .where((item) => item.acceptsSales)
                                  .map(
                                    (item) => PopupMenuItem(
                                      value: item.id,
                                      child: Text(item.name),
                                    ),
                                  )
                                  .toList(),
                              child: _BranchChip(name: branch?.name ?? 'الفرع'),
                            )
                          else if (branch != null)
                            _BranchChip(name: branch.name),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const MessageBanner(),
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'اسم المنتج أو الباركود…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'مسح باركود',
                            onPressed: _scan,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptySale(
                    hasQuery: _search.text.isNotEmpty,
                    onAddProduct: controller.membership!.role.canManageTeam
                        ? _addFirstProduct
                        : null,
                  ),
                )
              else
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    18,
                    2,
                    18,
                    _cart.isEmpty ? 24 : 104,
                  ),
                  sliver: SliverList.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final product = products[index];
                      final available = controller
                          .inventoryLevel(product.id, branch?.id)
                          ?.available;
                      final quantity = _cart[product.id]?.quantity ?? 0;
                      return _PosProductTile(
                        product: product,
                        available: available,
                        currency: currency,
                        quantity: quantity,
                        onAdd: () => _add(product),
                        onDecrease: () => _decrease(product),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _cart.isEmpty
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: FilledButton(
                  onPressed: _checkout,
                  child: Row(
                    children: [
                      Badge(
                        label: Text(
                          cartCount.toStringAsFixed(cartCount % 1 == 0 ? 0 : 2),
                        ),
                        child: const Icon(Icons.shopping_bag_outlined),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(child: Text('مراجعة وإتمام البيع')),
                      Text(
                        formatMoney(cartTotal, currency),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _SerialNumberSheet extends StatefulWidget {
  const _SerialNumberSheet({
    required this.product,
    required this.existingSerialNumbers,
  });

  final Product product;
  final Set<String> existingSerialNumbers;

  @override
  State<_SerialNumberSheet> createState() => _SerialNumberSheetState();
}

class _SerialNumberSheetState extends State<_SerialNumberSheet> {
  final _input = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final serialNumber = value.trim();
    if (serialNumber.isEmpty) {
      setState(() => _errorText = 'اكتب الرقم أو امسحه بالكاميرا.');
      return;
    }
    if (widget.existingSerialNumbers.contains(serialNumber.toLowerCase())) {
      _input.text = serialNumber;
      _input.selection = TextSelection.collapsed(offset: serialNumber.length);
      setState(() => _errorText = 'هذا الرقم موجود في السلة بالفعل.');
      return;
    }
    Navigator.of(context).pop(serialNumber);
  }

  Future<void> _scanSerialNumber() async {
    FocusScope.of(context).unfocus();
    final serialNumber = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(
          returnBarcode: true,
          mode: ScannerMode.serialNumber,
        ),
      ),
    );
    if (!mounted || serialNumber == null) return;
    _submit(serialNumber);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      0,
      20,
      MediaQuery.viewInsetsOf(context).bottom + 24,
    ),
    child: SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('رقم القطعة', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 5),
          Text(
            widget.product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _scanSerialNumber,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('مسح الرقم التسلسلي'),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: Divider(color: context.colors.outlineVariant)),
              Flexible(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'أو اكتبه يدوياً',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Expanded(child: Divider(color: context.colors.outlineVariant)),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _input,
            keyboardType: TextInputType.visiblePassword,
            autocorrect: false,
            enableSuggestions: false,
            textDirection: TextDirection.ltr,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: 'الرقم التسلسلي',
              helperText: 'يُربط بالقطعة وضمانها.',
              errorText: _errorText,
            ),
            onChanged: (_) {
              if (_errorText != null) setState(() => _errorText = null);
            },
            onSubmitted: _submit,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _submit(_input.text),
              child: const Text('إضافة الرقم للسلة'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _BranchChip extends StatelessWidget {
  const _BranchChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(maxWidth: 170),
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: context.colors.outlineVariant),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.storefront_outlined,
          size: 17,
          color: context.colors.primary,
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _PosProductTile extends StatelessWidget {
  const _PosProductTile({
    required this.product,
    required this.available,
    required this.currency,
    required this.quantity,
    required this.onAdd,
    required this.onDecrease,
  });

  final Product product;
  final num? available;
  final String currency;
  final num quantity;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          available == null
              ? (product.brand.isEmpty ? 'متاح للبيع' : product.brand)
              : 'المتوفر ${available!.toStringAsFixed(available! % 1 == 0 ? 0 : 2)}',
          style: TextStyle(
            color: context.colors.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
      ],
    );
    final price = Text(
      formatMoney(product.salePrice ?? 0, currency),
      style: TextStyle(
        color: context.colors.primary,
        fontWeight: FontWeight.w800,
        fontSize: 15,
      ),
    );
    final quantityControl = quantity <= 0
        ? SizedBox.square(
            dimension: 36,
            child: IconButton.filledTonal(
              tooltip: 'إضافة ${product.name}',
              onPressed: onAdd,
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.add_rounded, size: 21),
            ),
          )
        : _QuantityControl(
            quantity: quantity,
            onAdd: onAdd,
            onDecrease: onDecrease,
          );
    final usesStackedLayout = MediaQuery.textScalerOf(context).scale(16) > 24;

    return Card(
      child: InkWell(
        onTap: onAdd,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: usesStackedLayout
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    details,
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 8,
                      children: [price, quantityControl],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        price,
                        const SizedBox(height: 7),
                        quantityControl,
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _QuantityControl extends StatelessWidget {
  const _QuantityControl({
    required this.quantity,
    required this.onAdd,
    required this.onDecrease,
  });

  final num quantity;
  final VoidCallback onAdd;
  final VoidCallback onDecrease;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.colors.primaryContainer,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'تقليل الكمية',
          onPressed: onDecrease,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.remove_rounded, size: 18),
        ),
        Text(
          quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 2),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        IconButton(
          tooltip: 'زيادة الكمية',
          onPressed: onAdd,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.add_rounded, size: 18),
        ),
      ],
    ),
  );
}

class _EmptySale extends StatelessWidget {
  const _EmptySale({required this.hasQuery, required this.onAddProduct});

  final bool hasQuery;
  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasQuery ? Icons.search_off_rounded : Icons.inventory_2_outlined,
            size: 44,
            color: context.colors.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            hasQuery ? 'لا يوجد منتج مطابق' : 'أضف أول منتج لتبدأ البيع',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            hasQuery
                ? 'جرّب اسماً أو باركوداً آخر.'
                : 'يكفي الاسم والسعر والكمية. تستطيع إضافة بقية التفاصيل لاحقاً.',
            style: TextStyle(color: context.colors.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          if (!hasQuery && onAddProduct != null) ...[
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة منتج'),
            ),
          ],
        ],
      ),
    ),
  );
}

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet({required this.lines, required this.branch});

  final List<_CartLine> lines;
  final StoreBranch branch;

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _formKey = GlobalKey<FormState>();
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _discount = TextEditingController();
  final _notes = TextEditingController();
  final _firstAmount = TextEditingController();
  final _secondAmount = TextEditingController();
  CustomerProfile? _customer;
  PaymentMethod _firstMethod = PaymentMethod.cash;
  PaymentMethod _secondMethod = PaymentMethod.card;
  bool _showCustomer = false;
  bool _showMore = false;
  bool _splitPayment = false;

  num get subtotal =>
      widget.lines.fold<num>(0, (sum, line) => sum + line.total);
  num get discount => num.tryParse(_discount.text.trim()) ?? 0;
  num get total => (subtotal - discount).clamp(0, double.infinity);
  bool get hasWarranty =>
      widget.lines.any((line) => line.product.warrantyMonths > 0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firstAmount.text.isEmpty) _firstAmount.text = '$total';
    if (hasWarranty) _showCustomer = true;
  }

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _discount.dispose();
    _notes.dispose();
    _firstAmount.dispose();
    _secondAmount.dispose();
    super.dispose();
  }

  void _chooseCustomer(CustomerProfile? value) {
    setState(() {
      _customer = value;
      _customerName.text = value?.name ?? '';
      _customerPhone.text = value?.phone ?? '';
    });
  }

  void _refreshTotal() {
    setState(() {
      if (!_splitPayment) _firstAmount.text = '$total';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('إجمالي البيع يجب أن يكون أكبر من صفر.')),
      );
      return;
    }
    final payments = _splitPayment
        ? <SalePayment>[
            SalePayment(
              id: '',
              method: _firstMethod,
              amount: num.tryParse(_firstAmount.text) ?? 0,
              reference: '',
            ),
            SalePayment(
              id: '',
              method: _secondMethod,
              amount: num.tryParse(_secondAmount.text) ?? 0,
              reference: '',
            ),
          ]
        : <SalePayment>[
            SalePayment(
              id: '',
              method: _firstMethod,
              amount: total,
              reference: '',
            ),
          ];
    final paid = payments.fold<num>(0, (sum, payment) => sum + payment.amount);
    if ((paid - total).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'مجموع الدفعات يجب أن يساوي ${formatMoney(total, AppScope.of(context).store!.currencyCode)}.',
          ),
        ),
      );
      return;
    }
    final controller = AppScope.of(context);
    final sale = await controller.createSale(
      branchId: widget.branch.id,
      customerId: _customer?.id,
      customerName: _showCustomer ? _customerName.text : '',
      customerPhone: _showCustomer ? _customerPhone.text : '',
      lines: widget.lines
          .map(
            (line) => SaleLineInput(
              productId: line.product.id,
              quantity: line.quantity,
              unitPrice: line.product.salePrice ?? 0,
              discountAmount: 0,
              serialNumbers: line.serialNumbers,
            ),
          )
          .toList(),
      payments: payments,
      orderDiscount: discount,
      notes: _notes.text,
    );
    if (sale != null && mounted) Navigator.pop(context, sale);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final currency = controller.store!.currencyCode;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .9,
      minChildSize: .64,
      maxChildSize: .96,
      builder: (_, scrollController) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'تحصيل البيع',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.lines.length} منتجات • ${widget.branch.name}',
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatMoney(total, currency),
                  style: TextStyle(
                    color: context.colors.primary,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...widget.lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${line.product.name} × ${line.quantity.toStringAsFixed(line.quantity % 1 == 0 ? 0 : 2)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formatMoney(line.total, currency),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 24),
            Text('طريقة الدفع', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaymentMethod.values
                  .map(
                    (method) => ChoiceChip(
                      label: Text(method.label),
                      selected: _firstMethod == method,
                      onSelected: (_) => setState(() => _firstMethod = method),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            if (!_showCustomer)
              OutlinedButton.icon(
                onPressed: () => setState(() => _showCustomer = true),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: const Text('ربط البيع بعميل'),
              )
            else
              _CustomerFields(
                customers: controller.customers,
                customer: _customer,
                name: _customerName,
                phone: _customerPhone,
                requiredForWarranty: hasWarranty,
                onChanged: _chooseCustomer,
                onRemove: hasWarranty
                    ? null
                    : () {
                        _chooseCustomer(null);
                        setState(() => _showCustomer = false);
                      },
              ),
            if (hasWarranty) ...[
              const SizedBox(height: 8),
              Text(
                'بيانات العميل مطلوبة لإنشاء الضمان تلقائياً.',
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => setState(() => _showMore = !_showMore),
              icon: Icon(
                _showMore
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.tune_rounded,
              ),
              label: Text(
                _showMore ? 'إخفاء التفاصيل الإضافية' : 'خصم أو تقسيم الدفع',
              ),
            ),
            if (_showMore) ...[
              const SizedBox(height: 6),
              TextFormField(
                controller: _discount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: 'الخصم',
                  suffixText: currencyInfo(currency).symbol,
                ),
                onChanged: (_) => _refreshTotal(),
                validator: (value) {
                  final raw = value?.trim() ?? '';
                  final amount = num.tryParse(raw.isEmpty ? '0' : raw);
                  return amount == null || amount < 0 || amount > subtotal
                      ? 'أدخل خصماً صحيحاً'
                      : null;
                },
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _splitPayment,
                title: const Text('تقسيم الدفع'),
                subtitle: const Text('استخدم طريقتين للدفع في العملية نفسها.'),
                onChanged: (value) => setState(() {
                  _splitPayment = value;
                  _firstAmount.text = value ? '' : '$total';
                  _secondAmount.clear();
                }),
              ),
              if (_splitPayment) ...[
                _PaymentRow(
                  method: _firstMethod,
                  amount: _firstAmount,
                  onChanged: (value) => setState(() => _firstMethod = value!),
                ),
                const SizedBox(height: 10),
                _PaymentRow(
                  method: _secondMethod,
                  amount: _secondAmount,
                  onChanged: (value) => setState(() => _secondMethod = value!),
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظة (اختياري)',
                ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.busy ? null : _submit,
              icon: const Icon(Icons.check_rounded),
              label: Text(
                controller.busy
                    ? 'جارٍ الحفظ…'
                    : 'تأكيد ${formatMoney(total, currency)}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerFields extends StatelessWidget {
  const _CustomerFields({
    required this.customers,
    required this.customer,
    required this.name,
    required this.phone,
    required this.requiredForWarranty,
    required this.onChanged,
    required this.onRemove,
  });

  final List<CustomerProfile> customers;
  final CustomerProfile? customer;
  final TextEditingController name;
  final TextEditingController phone;
  final bool requiredForWarranty;
  final ValueChanged<CustomerProfile?> onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: context.colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: context.colors.outlineVariant),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'العميل',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (onRemove != null)
              IconButton(
                tooltip: 'إزالة العميل',
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
          ],
        ),
        if (customers.isNotEmpty) ...[
          DropdownButtonFormField<CustomerProfile?>(
            initialValue: customer,
            decoration: const InputDecoration(labelText: 'عميل محفوظ'),
            items: [
              const DropdownMenuItem<CustomerProfile?>(
                value: null,
                child: Text('عميل جديد'),
              ),
              ...customers.map(
                (item) => DropdownMenuItem(value: item, child: Text(item.name)),
              ),
            ],
            onChanged: onChanged,
          ),
          const SizedBox(height: 10),
        ],
        TextFormField(
          controller: name,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(labelText: 'اسم العميل'),
          validator: (value) =>
              requiredForWarranty && (value?.trim().length ?? 0) < 2
              ? 'أدخل اسم العميل'
              : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: phone,
          keyboardType: TextInputType.phone,
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: 'رقم الجوال'),
          validator: (value) =>
              requiredForWarranty && (value?.trim().length ?? 0) < 7
              ? 'أدخل رقم جوال صحيحاً'
              : null,
        ),
      ],
    ),
  );
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.method,
    required this.amount,
    required this.onChanged,
  });

  final PaymentMethod method;
  final TextEditingController amount;
  final ValueChanged<PaymentMethod?> onChanged;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: DropdownButtonFormField<PaymentMethod>(
          initialValue: method,
          decoration: const InputDecoration(labelText: 'الطريقة'),
          items: PaymentMethod.values
              .map(
                (item) =>
                    DropdownMenuItem(value: item, child: Text(item.label)),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: TextFormField(
          controller: amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(labelText: 'المبلغ'),
          validator: (value) =>
              (num.tryParse(value ?? '') ?? 0) <= 0 ? 'مبلغ غير صحيح' : null,
        ),
      ),
    ],
  );
}

class _CartLine {
  const _CartLine({
    required this.product,
    this.quantity = 0,
    this.serialNumbers = const [],
  });

  final Product product;
  final num quantity;
  final List<String> serialNumbers;

  num get total => quantity * (product.salePrice ?? 0);

  _CartLine copyWith({num? quantity, List<String>? serialNumbers}) => _CartLine(
    product: product,
    quantity: quantity ?? this.quantity,
    serialNumbers: serialNumbers ?? this.serialNumbers,
  );
}
