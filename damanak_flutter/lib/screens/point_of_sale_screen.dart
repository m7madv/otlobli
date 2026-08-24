import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../models/branch.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';
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
    final controller = AppScope.of(context);
    final product = controller.productByBarcode(code);
    if (product == null) {
      setState(() => _search.text = code);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('هذا الباركود غير موجود في الكتالوج.')),
      );
      return;
    }
    await _add(product);
  }

  Future<void> _add(Product product) async {
    final controller = AppScope.of(context);
    final stock = controller.inventoryLevel(product.id)?.available ?? 0;
    final current = _cart[product.id];
    if (product.trackInventory && stock <= (current?.quantity ?? 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('لا توجد كمية متاحة من ${product.name}.')),
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

  Future<String?> _askSerial(Product product) async {
    final input = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('الرقم التسلسلي'),
        content: TextField(
          controller: input,
          autofocus: true,
          textDirection: TextDirection.ltr,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: product.name,
            helperText: 'يُربط هذا الرقم بقطعة واحدة وبضمانها.',
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.pop(dialogContext, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              if (input.text.trim().isNotEmpty) {
                Navigator.pop(dialogContext, input.text.trim());
              }
            },
            child: const Text('إضافة القطعة'),
          ),
        ],
      ),
    );
    input.dispose();
    return result;
  }

  Future<void> _openRegister(StoreBranch branch) async {
    final input = TextEditingController(text: '0');
    final value = await showDialog<num>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('فتح صندوق ${branch.name}'),
        content: TextField(
          controller: input,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'النقد الافتتاحي',
            helperText: 'المبلغ الموجود فعلياً في الدرج قبل أول عملية بيع.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, num.tryParse(input.text) ?? 0),
            child: const Text('فتح الصندوق'),
          ),
        ],
      ),
    );
    input.dispose();
    if (value != null && mounted) {
      await AppScope.of(
        context,
      ).openRegister(branchId: branch.id, openingCash: value);
    }
  }

  Future<void> _checkout() async {
    final controller = AppScope.of(context);
    final branch = controller.activeBranch;
    if (branch == null || _cart.isEmpty) {
      return;
    }
    if (controller.openRegisterForBranch(branch.id) == null) {
      await _openRegister(branch);
      if (!mounted || controller.openRegisterForBranch(branch.id) == null) {
        return;
      }
    }
    final sale = await showModalBottomSheet<SaleTransaction>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) =>
          _CheckoutSheet(lines: _cart.values.toList(), branch: branch),
    );
    if (sale != null && mounted) {
      setState(_cart.clear);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: Icon(
            Icons.check_circle_rounded,
            color: context.colors.primary,
            size: 42,
          ),
          title: const Text('اكتمل البيع'),
          content: Text(
            'حُفظت الفاتورة ${sale.invoiceNumber}، وخُصمت الكميات، وأُنشئت الضمانات المؤهلة تلقائياً.',
            textAlign: TextAlign.center,
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('عملية جديدة'),
            ),
          ],
        ),
      );
    }
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'نقطة البيع',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          _CartButton(
                            count: _cart.length,
                            total: cartTotal,
                            currency: currency,
                            onPressed: _cart.isEmpty ? null : _checkout,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const _LifecycleRail(),
                      const SizedBox(height: 12),
                      const MessageBanner(),
                      if (controller.branches.length > 1)
                        DropdownButtonFormField<String>(
                          initialValue: branch?.id,
                          decoration: const InputDecoration(
                            labelText: 'الفرع النشط',
                            prefixIcon: Icon(Icons.storefront_outlined),
                          ),
                          items: controller.branches
                              .where((item) => item.acceptsSales)
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item.id,
                                  child: Text(item.name),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) controller.selectBranch(value);
                          },
                        ),
                      if (controller.branches.length > 1)
                        const SizedBox(height: 10),
                      _RegisterStrip(
                        branch: branch,
                        isOpen:
                            branch != null &&
                            controller.openRegisterForBranch(branch.id) != null,
                        onOpen: branch == null
                            ? null
                            : () => _openRegister(branch),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          labelText: 'ابحث بالاسم أو الرمز أو الباركود',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'مسح باركود المنتج',
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
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('لا توجد منتجات متاحة في هذا الفرع.'),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 2, 18, 110),
                  sliver: SliverList.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (_, index) {
                      final product = products[index];
                      final available = controller
                          .inventoryLevel(product.id, branch?.id)
                          ?.available;
                      return _PosProductTile(
                        product: product,
                        available: available,
                        currency: currency,
                        inCart: _cart[product.id]?.quantity ?? 0,
                        onAdd: () => _add(product),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: _cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _checkout,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: Text('إتمام البيع • ${formatMoney(cartTotal, currency)}'),
            ),
    );
  }
}

class _LifecycleRail extends StatelessWidget {
  const _LifecycleRail();

  @override
  Widget build(BuildContext context) {
    final color = context.colors.primary;
    const stages = [
      (Icons.inventory_2_outlined, 'المخزون'),
      (Icons.point_of_sale_outlined, 'البيع'),
      (Icons.receipt_long_outlined, 'الفاتورة'),
      (Icons.verified_user_outlined, 'الضمان'),
    ];
    return Semantics(
      label: 'دورة المنتج من المخزون إلى الضمان',
      child: Row(
        children: [
          for (var index = 0; index < stages.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  Icon(stages[index].$1, size: 20, color: color),
                  const SizedBox(height: 3),
                  Text(
                    stages[index].$2,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (index < stages.length - 1)
              Icon(
                Icons.arrow_back_rounded,
                size: 14,
                color: context.colors.outline,
              ),
          ],
        ],
      ),
    );
  }
}

class _RegisterStrip extends StatelessWidget {
  const _RegisterStrip({
    required this.branch,
    required this.isOpen,
    required this.onOpen,
  });
  final StoreBranch? branch;
  final bool isOpen;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: isOpen ? context.colors.primaryContainer : context.colors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.colors.outlineVariant),
    ),
    child: Row(
      children: [
        Icon(
          isOpen ? Icons.lock_open_rounded : Icons.point_of_sale_outlined,
          color: isOpen
              ? context.colors.primary
              : context.colors.onSurfaceVariant,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            isOpen
                ? 'الصندوق مفتوح وجاهز للبيع'
                : 'افتح الصندوق قبل أول عملية بيع',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        if (!isOpen) TextButton(onPressed: onOpen, child: const Text('فتح')),
      ],
    ),
  );
}

class _PosProductTile extends StatelessWidget {
  const _PosProductTile({
    required this.product,
    required this.available,
    required this.currency,
    required this.inCart,
    required this.onAdd,
  });
  final Product product;
  final num? available;
  final String currency;
  final num inCart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onAdd,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: context.colors.primaryContainer,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          product.isSerialized
              ? Icons.numbers_rounded
              : Icons.inventory_2_outlined,
          color: context.colors.primary,
        ),
      ),
      title: Text(
        product.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${product.sku}${available == null ? '' : ' • متاح ${available!.toStringAsFixed(available! % 1 == 0 ? 0 : 2)}'}${inCart > 0 ? ' • في السلة $inCart' : ''}',
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatMoney(product.salePrice ?? 0, currency),
            style: TextStyle(
              color: context.colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          const Icon(Icons.add_circle_outline_rounded, size: 20),
        ],
      ),
    ),
  );
}

class _CartButton extends StatelessWidget {
  const _CartButton({
    required this.count,
    required this.total,
    required this.currency,
    required this.onPressed,
  });
  final int count;
  final num total;
  final String currency;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: onPressed,
    icon: Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: const Icon(Icons.shopping_bag_outlined),
    ),
    label: Text(formatMoney(total, currency)),
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
  final _discount = TextEditingController(text: '0');
  final _notes = TextEditingController();
  CustomerProfile? _customer;
  PaymentMethod _firstMethod = PaymentMethod.card;
  PaymentMethod _secondMethod = PaymentMethod.cash;
  final _firstAmount = TextEditingController();
  final _secondAmount = TextEditingController(text: '0');
  bool _splitPayment = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_firstAmount.text.isEmpty) _firstAmount.text = '$total';
  }

  num get subtotal =>
      widget.lines.fold<num>(0, (sum, line) => sum + line.total);
  num get discount => num.tryParse(_discount.text) ?? 0;
  num get total => (subtotal - discount).clamp(0, double.infinity);

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = AppScope.of(context);
    final payments = <SalePayment>[
      SalePayment(
        id: '',
        method: _firstMethod,
        amount: num.tryParse(_firstAmount.text) ?? 0,
        reference: '',
      ),
      if (_splitPayment)
        SalePayment(
          id: '',
          method: _secondMethod,
          amount: num.tryParse(_secondAmount.text) ?? 0,
          reference: '',
        ),
    ];
    final paid = payments.fold<num>(0, (sum, payment) => sum + payment.amount);
    if ((paid - total).abs() > 0.01) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'مجموع الدفعات يجب أن يساوي ${formatMoney(total, controller.store!.currencyCode)}.',
          ),
        ),
      );
      return;
    }
    final sale = await controller.createSale(
      branchId: widget.branch.id,
      customerId: _customer?.id,
      customerName: _customerName.text,
      customerPhone: _customerPhone.text,
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
    final hasWarranty = widget.lines.any(
      (line) => line.product.warrantyMonths > 0,
    );
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .9,
      minChildSize: .62,
      maxChildSize: .96,
      builder: (_, scrollController) => Form(
        key: _formKey,
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Text(
              'إتمام البيع',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              '${widget.branch.name} • ${widget.lines.length} منتجات',
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            ...widget.lines.map(
              (line) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(line.product.name),
                subtitle: Text(
                  'الكمية ${line.quantity}${line.serialNumbers.isEmpty ? '' : ' • ${line.serialNumbers.join('، ')}'}',
                ),
                trailing: Text(formatMoney(line.total, currency)),
              ),
            ),
            const Divider(height: 28),
            DropdownButtonFormField<CustomerProfile?>(
              initialValue: _customer,
              decoration: const InputDecoration(
                labelText: 'العميل',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              items: [
                const DropdownMenuItem<CustomerProfile?>(
                  value: null,
                  child: Text('عميل نقدي / جديد'),
                ),
                ...controller.customers.map(
                  (item) => DropdownMenuItem(
                    value: item,
                    child: Text('${item.name} • ${item.phone}'),
                  ),
                ),
              ],
              onChanged: _chooseCustomer,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _customerName,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'اسم العميل'),
              validator: (value) =>
                  hasWarranty && (value?.trim().length ?? 0) < 2
                  ? 'اسم العميل مطلوب لإنشاء الضمان'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _customerPhone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(labelText: 'رقم العميل'),
              validator: (value) =>
                  hasWarranty && (value?.trim().length ?? 0) < 7
                  ? 'رقم صحيح مطلوب لإرسال وربط الضمان'
                  : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _discount,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(
                labelText: 'خصم على كامل الفاتورة',
              ),
              onChanged: (_) {
                setState(() {
                  if (!_splitPayment) _firstAmount.text = '$total';
                });
              },
              validator: (value) {
                final amount = num.tryParse(value ?? '');
                return amount == null || amount < 0 || amount > subtotal
                    ? 'أدخل خصماً صحيحاً'
                    : null;
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _splitPayment,
              title: const Text('تقسيم الدفع'),
              subtitle: const Text('مثلاً جزء نقدي وجزء بالبطاقة.'),
              onChanged: (value) => setState(() {
                _splitPayment = value;
                if (!value) {
                  _firstAmount.text = '$total';
                  _secondAmount.text = '0';
                }
              }),
            ),
            _PaymentRow(
              method: _firstMethod,
              amount: _firstAmount,
              onChanged: (value) => setState(() => _firstMethod = value!),
            ),
            if (_splitPayment) ...[
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
                labelText: 'ملاحظات الفاتورة (اختياري)',
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _AmountRow(
                      label: 'قبل الخصم',
                      value: formatMoney(subtotal, currency),
                    ),
                    _AmountRow(
                      label: 'الخصم',
                      value: formatMoney(discount, currency),
                    ),
                    const Divider(),
                    _AmountRow(
                      label: 'الإجمالي',
                      value: formatMoney(total, currency),
                      strong: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: controller.busy ? null : _submit,
              icon: const Icon(Icons.check_rounded),
              label: Text(controller.busy ? 'جارٍ الحفظ…' : 'تأكيد البيع'),
            ),
          ],
        ),
      ),
    );
  }
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
          decoration: const InputDecoration(labelText: 'طريقة الدفع'),
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

class _AmountRow extends StatelessWidget {
  const _AmountRow({
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
