import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';
import 'scanner_screen.dart';

class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({this.initialBarcode = '', this.product, super.key});

  final String initialBarcode;
  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _price = TextEditingController();
  final _quantity = TextEditingController(text: '0');
  final _barcode = TextEditingController();
  final _brand = TextEditingController();
  final _category = TextEditingController();
  final _sku = TextEditingController();
  final _cost = TextEditingController();
  final _reorderPoint = TextEditingController(text: '2');
  int _warrantyMonths = 0;
  num _initialQuantity = 0;
  bool _trackInventory = true;
  bool _isSerialized = false;
  bool _showAdvanced = false;
  bool _loadedWorkspace = false;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product == null) {
      _barcode.text = widget.initialBarcode;
      return;
    }
    _name.text = product.name;
    _price.text = product.salePrice == null ? '' : '${product.salePrice}';
    _barcode.text = product.barcode;
    _brand.text = product.brand;
    _category.text = product.category;
    _sku.text = product.sku;
    _cost.text = product.costPrice == null ? '' : '${product.costPrice}';
    _reorderPoint.text = '${product.reorderPoint}';
    _trackInventory = product.trackInventory;
    _isSerialized = product.isSerialized;
    _warrantyMonths = product.warrantyMonths;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedWorkspace) return;
    final controller = AppScope.of(context);
    if (widget.product == null) {
      _warrantyMonths = controller.store!.defaultWarrantyMonths;
    } else {
      _initialQuantity =
          controller.inventoryLevel(widget.product!.id)?.onHand ?? 0;
      _quantity.text = _numberText(_initialQuantity);
    }
    _loadedWorkspace = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _quantity.dispose();
    _barcode.dispose();
    _brand.dispose();
    _category.dispose();
    _sku.dispose();
    _cost.dispose();
    _reorderPoint.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(returnBarcode: true),
      ),
    );
    if (code != null && mounted) setState(() => _barcode.text = code);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = AppScope.of(context);
    final quantity = num.tryParse(_quantity.text.trim()) ?? 0;
    final cost = num.tryParse(_cost.text.trim());
    final product = widget.product == null
        ? await controller.addProduct(
            name: _name.text,
            brand: _brand.text,
            category: _category.text,
            barcode: _barcode.text,
            sku: _sku.text,
            warrantyMonths: _warrantyMonths,
            salePrice: num.tryParse(_price.text.trim()),
            costPrice: cost,
            trackInventory: _trackInventory,
            isSerialized: _isSerialized,
            reorderPoint: num.tryParse(_reorderPoint.text.trim()) ?? 0,
          )
        : await controller.updateProduct(
            productId: widget.product!.id,
            name: _name.text,
            brand: _brand.text,
            category: _category.text,
            barcode: _barcode.text,
            sku: _sku.text,
            warrantyMonths: _warrantyMonths,
            salePrice: num.tryParse(_price.text.trim()),
            costPrice: cost,
            trackInventory: _trackInventory,
            isSerialized: _isSerialized,
            reorderPoint: num.tryParse(_reorderPoint.text.trim()) ?? 0,
          );
    final branch = controller.activeBranch;
    if (product != null &&
        branch != null &&
        _trackInventory &&
        quantity != _initialQuantity) {
      await controller.adjustInventory(
        branchId: branch.id,
        productId: product.id,
        newQuantity: quantity,
        unitCost: cost ?? product.costPrice ?? 0,
        note: widget.product == null
            ? 'رصيد أولي عند إضافة المنتج'
            : 'تعديل الرصيد من بطاقة المنتج',
      );
    }
    if (mounted && product != null) Navigator.of(context).pop(product);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final currency = currencyInfo(controller.store!.currencyCode);
    final editing = widget.product != null;
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'تعديل المنتج' : 'منتج جديد')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MessageBanner(),
                    Text(
                      editing
                          ? 'غيّر ما تحتاجه فقط.'
                          : 'الاسم والسعر والكمية تكفي للبدء.',
                      style: TextStyle(
                        color: context.colors.onSurfaceVariant,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'اسم المنتج',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _price,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textDirection: TextDirection.ltr,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: 'سعر البيع',
                                      suffixText: currency.symbol,
                                    ),
                                    validator: (value) {
                                      final amount = num.tryParse(
                                        value?.trim() ?? '',
                                      );
                                      return amount == null || amount <= 0
                                          ? 'أدخل سعراً صحيحاً'
                                          : null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _quantity,
                                    enabled: _trackInventory,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    textDirection: TextDirection.ltr,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'الكمية الحالية',
                                    ),
                                    validator: _nonNegative,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _barcode,
                              textDirection: TextDirection.ltr,
                              textInputAction: TextInputAction.done,
                              decoration: InputDecoration(
                                labelText: 'الباركود (اختياري)',
                                prefixIcon: const Icon(Icons.qr_code_2_rounded),
                                suffixIcon: IconButton(
                                  tooltip: 'مسح الباركود',
                                  onPressed: _scanBarcode,
                                  icon: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: _warrantyMonths,
                              decoration: const InputDecoration(
                                labelText: 'الضمان',
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                              items: const [0, 3, 6, 12, 18, 24, 36, 60]
                                  .map(
                                    (months) => DropdownMenuItem(
                                      value: months,
                                      child: Text(
                                        months == 0
                                            ? 'بلا ضمان'
                                            : '$months شهراً',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) =>
                                  setState(() => _warrantyMonths = value ?? 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _showAdvanced = !_showAdvanced),
                      icon: Icon(
                        _showAdvanced
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.tune_rounded,
                      ),
                      label: Text(
                        _showAdvanced
                            ? 'إخفاء الخيارات الإضافية'
                            : 'علامة تجارية وتكلفة وخيارات مخزون',
                      ),
                    ),
                    if (_showAdvanced) ...[
                      const SizedBox(height: 6),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _brand,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'العلامة التجارية',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _category,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'التصنيف',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _sku,
                                textDirection: TextDirection.ltr,
                                textInputAction: TextInputAction.next,
                                decoration: const InputDecoration(
                                  labelText: 'رمز المخزون (اختياري)',
                                  prefixIcon: Icon(Icons.tag_outlined),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cost,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      textDirection: TextDirection.ltr,
                                      decoration: InputDecoration(
                                        labelText: 'تكلفة الشراء',
                                        suffixText: currency.symbol,
                                      ),
                                      validator: _optionalNonNegative,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _reorderPoint,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      textDirection: TextDirection.ltr,
                                      decoration: const InputDecoration(
                                        labelText: 'تنبيه عند كمية',
                                      ),
                                      validator: _nonNegative,
                                    ),
                                  ),
                                ],
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: _trackInventory,
                                title: const Text('تتبّع الكمية'),
                                subtitle: const Text(
                                  'أوقفه للخدمات أو المنتجات غير المخزنة.',
                                ),
                                onChanged: (value) => setState(() {
                                  _trackInventory = value;
                                  if (!value) _isSerialized = false;
                                }),
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                value: _isSerialized,
                                title: const Text('رقم تسلسلي لكل قطعة'),
                                subtitle: const Text(
                                  'للهواتف والأجهزة التي تحتاج تتبعاً فردياً.',
                                ),
                                onChanged: _trackInventory
                                    ? (value) =>
                                          setState(() => _isSerialized = value)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: controller.busy ? null : _save,
                        icon: const Icon(Icons.check_rounded),
                        label: Text(
                          controller.busy
                              ? 'جارٍ الحفظ…'
                              : editing
                              ? 'حفظ التعديلات'
                              : 'حفظ المنتج',
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
      value == null || value.trim().isEmpty ? 'أدخل اسم المنتج' : null;

  String? _nonNegative(String? value) {
    final number = num.tryParse(value?.trim() ?? '');
    return number == null || number < 0 ? 'أدخل رقماً صحيحاً' : null;
  }

  String? _optionalNonNegative(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    return _nonNegative(value);
  }

  String _numberText(num value) =>
      value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
}
