import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../core/date_utils.dart';
import '../models/account.dart';
import '../models/branch.dart';
import '../models/customer.dart';
import '../models/product.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';
import 'scanner_screen.dart';
import 'warranty_detail_screen.dart';

enum _DuplicateWarrantyAction { openExisting, continueIssuing }

class WarrantyFormScreen extends StatefulWidget {
  const WarrantyFormScreen({this.product, this.scannedBarcode = '', super.key});

  final Product? product;
  final String scannedBarcode;

  @override
  State<WarrantyFormScreen> createState() => _WarrantyFormScreenState();
}

class _WarrantyFormScreenState extends State<WarrantyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _customerEmail = TextEditingController();
  final _customerNotes = TextEditingController();
  final _productName = TextEditingController();
  final _barcode = TextEditingController();
  final _serialNumber = TextEditingController();
  final _notes = TextEditingController();
  final _salePrice = TextEditingController();
  final _discount = TextEditingController();
  final _invoiceNumber = TextEditingController();
  Product? _selectedProduct;
  CustomerProfile? _selectedCustomer;
  StoreBranch? _selectedBranch;
  PaymentMethod _paymentMethod = PaymentMethod.card;
  DateTime _purchaseDate = DateTime.now();
  int _durationMonths = 12;
  bool _loadedDefaults = false;
  bool _showOptionalDetails = false;

  DateTime get _expiryDate => addMonths(_purchaseDate, _durationMonths);

  @override
  void initState() {
    super.initState();
    _selectProduct(widget.product);
    if (widget.scannedBarcode.isNotEmpty) _barcode.text = widget.scannedBarcode;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedDefaults) return;
    final controller = AppScope.of(context);
    if (_selectedProduct == null) {
      _durationMonths = controller.store!.defaultWarrantyMonths;
    }
    if (controller.branches.isNotEmpty) {
      _selectedBranch = controller.branches.firstWhere(
        (item) => item.isMain,
        orElse: () => controller.branches.first,
      );
    }
    _loadedDefaults = true;
  }

  void _selectProduct(Product? product) {
    _selectedProduct = product;
    if (product == null) return;
    _productName.text = product.name;
    _barcode.text = product.barcode;
    _durationMonths = product.warrantyMonths;
    _salePrice.text = product.salePrice == null ? '' : '${product.salePrice}';
  }

  void _selectCustomer(CustomerProfile? customer) {
    _selectedCustomer = customer;
    if (customer == null) return;
    _customerName.text = customer.name;
    _customerPhone.text = customer.phone;
    _customerEmail.text = customer.email;
    _customerNotes.text = customer.notes;
  }

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _customerEmail.dispose();
    _customerNotes.dispose();
    _productName.dispose();
    _barcode.dispose();
    _serialNumber.dispose();
    _notes.dispose();
    _salePrice.dispose();
    _discount.dispose();
    _invoiceNumber.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(returnBarcode: true),
      ),
    );
    if (code == null || !mounted) return;
    final controller = AppScope.of(context);
    final product = controller.productByBarcode(code);
    setState(() {
      if (product != null) {
        _selectProduct(product);
      } else {
        _selectedProduct = null;
        _productName.clear();
        _salePrice.clear();
        _barcode.text = code;
        _durationMonths = controller.store!.defaultWarrantyMonths;
      }
    });
  }

  Future<void> _scanSerialNumber() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(
          returnBarcode: true,
          mode: ScannerMode.serialNumber,
        ),
      ),
    );
    if (code != null && mounted) {
      setState(() => _serialNumber.text = code);
    }
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      helpText: 'اختر تاريخ الشراء',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );
    if (picked != null && mounted) setState(() => _purchaseDate = picked);
  }

  _FinancialTotals _totals(StoreWorkspace store) {
    final subtotal = num.tryParse(_salePrice.text.trim()) ?? 0;
    final discount = num.tryParse(_discount.text.trim()) ?? 0;
    final total = (subtotal - discount).clamp(0, double.infinity);
    return _FinancialTotals(
      subtotal: roundMoney(subtotal, store.currencyCode),
      discount: roundMoney(discount, store.currencyCode),
      total: roundMoney(total, store.currencyCode),
    );
  }

  bool get _optionalDetailsHaveValidationError {
    return _emailValidator(_customerEmail.text) != null ||
        _moneyValidator(_salePrice.text) != null ||
        _discountValidator(_discount.text) != null;
  }

  Future<void> _save() async {
    if (!_showOptionalDetails && _optionalDetailsHaveValidationError) {
      setState(() => _showOptionalDetails = true);
      await WidgetsBinding.instance.endOfFrame;
      _formKey.currentState?.validate();
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final controller = AppScope.of(context);
    final duplicate = await controller.findWarrantyBySerial(_serialNumber.text);
    if (!mounted) return;
    if (duplicate != null) {
      final action = await showDialog<_DuplicateWarrantyAction>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.content_copy_rounded),
          title: const Text('الرقم التسلسلي مسجل'),
          content: Text(
            'هذا الرقم مرتبط بالضمان ${duplicate.displayNumber} للعميل '
            '${duplicate.customerName}، وصلاحيته حتى '
            '${formatDate(duplicate.expiryDate)}. افتح السجل قبل إصدار ضمان آخر.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            if (controller.membership!.role.canManageTeam)
              TextButton(
                onPressed: () => Navigator.pop(
                  dialogContext,
                  _DuplicateWarrantyAction.continueIssuing,
                ),
                child: const Text('إصدار جديد بعد المراجعة'),
              ),
            FilledButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                _DuplicateWarrantyAction.openExisting,
              ),
              child: const Text('فتح الضمان الحالي'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (action == _DuplicateWarrantyAction.openExisting) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WarrantyDetailScreen(warrantyId: duplicate.id),
          ),
        );
        return;
      }
      if (action != _DuplicateWarrantyAction.continueIssuing) return;
    }
    final subscription = controller.subscription!;
    if (!subscription.isUsable || subscription.remainingWarranties <= 0) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('لا يمكن إصدار الضمان'),
          content: const Text(
            'الاشتراك غير فعّال أو تم استهلاك الحد الشهري. راجع المالك لتجديد الخطة.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('حسناً'),
            ),
          ],
        ),
      );
      return;
    }
    final store = controller.store!;
    final totals = _totals(store);
    final warranty = await controller.addWarranty(
      productId: _selectedProduct?.id,
      customerId: _selectedCustomer?.id,
      customerName: _customerName.text,
      customerPhone: _customerPhone.text,
      customerEmail: _customerEmail.text,
      customerNotes: _customerNotes.text,
      branchId: _selectedBranch?.id,
      productName: _productName.text,
      barcode: _barcode.text,
      serialNumber: _serialNumber.text,
      purchaseDate: _purchaseDate,
      expiryDate: _expiryDate,
      notes: _notes.text,
      invoiceNumber: _invoiceNumber.text,
      saleSubtotal: totals.subtotal,
      discountAmount: totals.discount,
      taxAmount: 0,
      saleTotal: totals.total,
      taxRate: 0,
      currencyCode: store.currencyCode,
      paymentMethod: _paymentMethod,
    );
    if (!mounted || warranty == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            WarrantyDetailScreen(warrantyId: warranty.id, justCreated: true),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final store = controller.store!;
    final currency = currencyInfo(store.currencyCode);
    final totals = _totals(store);
    return Scaffold(
      appBar: AppBar(title: const Text('إصدار ضمان')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MessageBanner(),
                    _IssueHeader(
                      productName: _productName.text,
                      expiryDate: _expiryDate,
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      step: 1,
                      title: 'المنتج',
                      child: Column(
                        children: [
                          DropdownButtonFormField<Product?>(
                            key: ValueKey(
                              'product-${_selectedProduct?.id ?? 'manual'}',
                            ),
                            initialValue: _selectedProduct,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'منتج من الكتالوج (اختياري)',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            items: [
                              const DropdownMenuItem<Product?>(
                                value: null,
                                child: Text('إدخال منتج يدوياً'),
                              ),
                              ...controller.products.map(
                                (product) => DropdownMenuItem<Product?>(
                                  value: product,
                                  child: Text(
                                    product.barcode.isEmpty
                                        ? product.name
                                        : '${product.name} • ${product.barcode}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (product) =>
                                setState(() => _selectProduct(product)),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('warranty-product-name'),
                            controller: _productName,
                            readOnly: _selectedProduct != null,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'اسم المنتج',
                              prefixIcon: Icon(Icons.devices_other_outlined),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('warranty-barcode'),
                            controller: _barcode,
                            readOnly: _selectedProduct != null,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              labelText: 'الباركود (اختياري)',
                              helperText: 'امسحه أو اكتبه يدوياً.',
                              prefixIcon: const Icon(Icons.qr_code_2_rounded),
                              suffixIcon: IconButton(
                                tooltip: 'مسح الباركود',
                                onPressed: _scanBarcode,
                                icon: const Icon(Icons.qr_code_scanner_rounded),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('warranty-serial-number'),
                            controller: _serialNumber,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              labelText: 'الرقم التسلسلي (اختياري)',
                              helperText: 'امسحه أو اكتبه يدوياً.',
                              prefixIcon: const Icon(Icons.tag_rounded),
                              suffixIcon: IconButton(
                                tooltip: 'مسح الرقم التسلسلي',
                                onPressed: _scanSerialNumber,
                                icon: const Icon(Icons.center_focus_strong),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      step: 2,
                      title: 'العميل',
                      child: Column(
                        children: [
                          DropdownButtonFormField<CustomerProfile?>(
                            initialValue: _selectedCustomer,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'عميل مسجل (اختياري)',
                              prefixIcon: Icon(Icons.people_outline_rounded),
                            ),
                            items: [
                              const DropdownMenuItem<CustomerProfile?>(
                                value: null,
                                child: Text('عميل جديد'),
                              ),
                              ...controller.customers.map(
                                (customer) =>
                                    DropdownMenuItem<CustomerProfile?>(
                                      value: customer,
                                      child: Text(
                                        '${customer.name} • ${customer.phone}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                              ),
                            ],
                            onChanged: (customer) =>
                                setState(() => _selectCustomer(customer)),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('warranty-customer-name'),
                            controller: _customerName,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            decoration: const InputDecoration(
                              labelText: 'اسم العميل',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            key: const ValueKey('warranty-customer-phone'),
                            controller: _customerPhone,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [
                              AutofillHints.telephoneNumber,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'رقم الجوال',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) =>
                                (value?.trim().length ?? 0) < 7
                                ? 'أدخل رقم جوال صحيحاً'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      step: 3,
                      title: 'مدة الضمان',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Semantics(
                            button: true,
                            label: 'تاريخ الشراء ${formatDate(_purchaseDate)}',
                            child: InkWell(
                              onTap: _pickPurchaseDate,
                              borderRadius: BorderRadius.circular(13),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'تاريخ الشراء',
                                  prefixIcon: Icon(Icons.event_outlined),
                                  suffixIcon: Icon(Icons.expand_more_rounded),
                                ),
                                child: Text(formatDate(_purchaseDate)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'مدة الضمان',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [3, 6, 12, 18, 24, 36, 60]
                                .map(
                                  (months) => ChoiceChip(
                                    label: Text('$months شهراً'),
                                    selected: _durationMonths == months,
                                    onSelected: (_) => setState(
                                      () => _durationMonths = months,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'ينتهي الضمان في ${formatDate(_expiryDate)}',
                            style: TextStyle(
                              color: context.colors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _OptionalDetailsCard(
                      expanded: _showOptionalDetails,
                      onToggle: () => setState(
                        () => _showOptionalDetails = !_showOptionalDetails,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _OptionalGroupTitle('بيانات العميل'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _customerEmail,
                            keyboardType: TextInputType.emailAddress,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'البريد الإلكتروني',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            validator: _emailValidator,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _customerNotes,
                            minLines: 2,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'ملاحظات العميل',
                              alignLabelWithHint: true,
                            ),
                          ),
                          const Divider(height: 32),
                          const _OptionalGroupTitle('البيع والإيصال'),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<StoreBranch?>(
                            initialValue: _selectedBranch,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'الفرع',
                              prefixIcon: Icon(
                                Icons.store_mall_directory_outlined,
                              ),
                            ),
                            items: [
                              if (controller.branches.isEmpty)
                                const DropdownMenuItem<StoreBranch?>(
                                  value: null,
                                  child: Text('لا يوجد فرع مسجل'),
                                ),
                              ...controller.branches.map(
                                (branch) => DropdownMenuItem<StoreBranch?>(
                                  value: branch,
                                  child: Text(
                                    '${branch.name} • ${branch.city}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (branch) =>
                                setState(() => _selectedBranch = branch),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _invoiceNumber,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: 'رقم الإيصال',
                              hintText: '${store.invoicePrefix}-000001',
                              prefixIcon: const Icon(Icons.numbers_rounded),
                              helperText:
                                  'اتركه فارغاً ليولده النظام تلقائياً.',
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<PaymentMethod>(
                            initialValue: _paymentMethod,
                            decoration: const InputDecoration(
                              labelText: 'طريقة الدفع',
                              prefixIcon: Icon(Icons.credit_card_outlined),
                            ),
                            items: PaymentMethod.values
                                .map(
                                  (method) => DropdownMenuItem(
                                    value: method,
                                    child: Text(method.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (method) => setState(
                              () => _paymentMethod = method ?? _paymentMethod,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _salePrice,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'سعر البيع',
                              prefixIcon: const Icon(Icons.sell_outlined),
                              suffixText: currency.symbol,
                            ),
                            validator: _moneyValidator,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _discount,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'الخصم',
                              prefixIcon: const Icon(Icons.discount_outlined),
                              suffixText: currency.symbol,
                            ),
                            validator: _discountValidator,
                          ),
                          if (_salePrice.text.trim().isNotEmpty ||
                              _discount.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _MoneySummary(
                              totals: totals,
                              currencyCode: store.currencyCode,
                            ),
                          ],
                          const Divider(height: 32),
                          const _OptionalGroupTitle('ملاحظات الضمان'),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _notes,
                            minLines: 2,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              labelText: 'الشروط أو الملاحظات',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('issue-warranty-button'),
                        onPressed: controller.busy ? null : _save,
                        icon: const Icon(Icons.verified_user_outlined),
                        label: Text(
                          controller.busy ? 'جارٍ الإصدار…' : 'إصدار الضمان',
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'يمكن إضافة تفاصيل البيع والإيصال قبل الإصدار عند الحاجة.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null;

  String? _emailValidator(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    return email.contains('@') ? null : 'أدخل بريداً صحيحاً';
  }

  String? _moneyValidator(String? value) {
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    final amount = num.tryParse(raw);
    if (amount == null || amount < 0) return 'أدخل مبلغاً صحيحاً';
    return null;
  }

  String? _discountValidator(String? value) {
    final error = _moneyValidator(value);
    if (error != null) return error;
    final raw = value?.trim() ?? '';
    if (raw.isEmpty) return null;
    final price = num.tryParse(_salePrice.text.trim()) ?? 0;
    final discount = num.tryParse(raw) ?? 0;
    return discount > price ? 'الخصم أكبر من سعر البيع' : null;
  }
}

class _FinancialTotals {
  const _FinancialTotals({
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  final num subtotal;
  final num discount;
  final num total;
}

class _MoneySummary extends StatelessWidget {
  const _MoneySummary({required this.totals, required this.currencyCode});

  final _FinancialTotals totals;
  final String currencyCode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _SummaryRow(
            label: 'سعر البيع',
            value: formatMoney(totals.subtotal, currencyCode),
          ),
          if (totals.discount > 0)
            _SummaryRow(
              label: 'الخصم',
              value: '- ${formatMoney(totals.discount, currencyCode)}',
            ),
          const Divider(height: 20),
          _SummaryRow(
            label: 'الإجمالي',
            value: formatMoney(totals.total, currencyCode),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = TextStyle(
      color: emphasized ? colors.onSurface : colors.onSurfaceVariant,
      fontWeight: emphasized ? FontWeight.w700 : FontWeight.w500,
      fontSize: emphasized ? 16 : 13,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Text(value, style: style),
          ),
        ],
      ),
    );
  }
}

class _IssueHeader extends StatelessWidget {
  const _IssueHeader({required this.productName, required this.expiryDate});

  final String productName;
  final DateTime expiryDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 52,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.verified_user_outlined, color: colors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName.trim().isEmpty ? 'ضمان جديد' : productName.trim(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'ينتهي في ${formatDate(expiryDate)}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '3 خطوات',
            style: TextStyle(
              color: colors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.step,
    required this.title,
    required this.child,
  });

  final int step;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$step',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _OptionalDetailsCard extends StatelessWidget {
  const _OptionalDetailsCard({
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Column(
        children: [
          InkWell(
            key: const ValueKey('optional-warranty-details-toggle'),
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(20),
              bottom: expanded ? Radius.zero : const Radius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: colors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'تفاصيل اختيارية',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'البيع والإيصال والبريد والملاحظات',
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            Padding(padding: const EdgeInsets.all(18), child: child),
          ],
        ],
      ),
    );
  }
}

class _OptionalGroupTitle extends StatelessWidget {
  const _OptionalGroupTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.colors.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
