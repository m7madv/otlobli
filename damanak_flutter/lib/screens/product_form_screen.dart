import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';

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
  final _brand = TextEditingController();
  final _category = TextEditingController();
  final _barcode = TextEditingController();
  final _sku = TextEditingController();
  final _price = TextEditingController();
  final _cost = TextEditingController();
  final _reorderPoint = TextEditingController(text: '2');
  int _warrantyMonths = 12;
  bool _trackInventory = true;
  bool _isSerialized = false;
  bool _loadedDefaults = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedDefaults) return;
    _warrantyMonths = AppScope.of(context).store!.defaultWarrantyMonths;
    _loadedDefaults = true;
  }

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product == null) {
      _barcode.text = widget.initialBarcode;
    } else {
      _name.text = product.name;
      _brand.text = product.brand;
      _category.text = product.category;
      _barcode.text = product.barcode;
      _sku.text = product.sku;
      _price.text = product.salePrice == null ? '' : '${product.salePrice}';
      _cost.text = product.costPrice == null ? '' : '${product.costPrice}';
      _reorderPoint.text = '${product.reorderPoint}';
      _trackInventory = product.trackInventory;
      _isSerialized = product.isSerialized;
      _warrantyMonths = product.warrantyMonths;
      _loadedDefaults = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _category.dispose();
    _barcode.dispose();
    _sku.dispose();
    _price.dispose();
    _cost.dispose();
    _reorderPoint.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = AppScope.of(context);
    final product = widget.product == null
        ? await controller.addProduct(
            name: _name.text,
            brand: _brand.text,
            category: _category.text,
            barcode: _barcode.text,
            sku: _sku.text,
            warrantyMonths: _warrantyMonths,
            salePrice: num.tryParse(_price.text.trim()),
            costPrice: num.tryParse(_cost.text.trim()),
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
            costPrice: num.tryParse(_cost.text.trim()),
            trackInventory: _trackInventory,
            isSerialized: _isSerialized,
            reorderPoint: num.tryParse(_reorderPoint.text.trim()) ?? 0,
          );
    if (mounted && product != null) {
      Navigator.of(context).pop(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colors = context.colors;
    final currency = currencyInfo(controller.store!.currencyCode);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'إضافة منتج للكتالوج' : 'تعديل المنتج',
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MessageBanner(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: colors.primary,
                            size: 30,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Text(
                              widget.product == null
                                  ? 'سجّل المنتج مرة واحدة؛ بعدها يكفي مسح باركوده لتعبئة اسمه ومدة ضمانه.'
                                  : 'حدّث بيانات البيع والضمان من دون تغيير سجلات الضمان السابقة.',
                              style: const TextStyle(
                                height: 1.55,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _Section(
                      title: 'تعريف المنتج',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _name,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'اسم المنتج',
                              prefixIcon: Icon(Icons.devices_other_outlined),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
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
                              labelText: 'رمز المخزون',
                              prefixIcon: Icon(Icons.tag_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _barcode,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'الباركود',
                              prefixIcon: Icon(Icons.qr_code_2_rounded),
                              helperText: 'يجب أن يكون فريداً داخل متجرك.',
                            ),
                            validator: (value) {
                              final code = value?.trim() ?? '';
                              if (code.isEmpty) {
                                return 'الباركود مطلوب للعثور السريع';
                              }
                              if (code.length < 4) {
                                return 'الباركود قصير جداً';
                              }
                              return null;
                            },
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
                                    labelText: 'حد إعادة الطلب',
                                  ),
                                  validator: (value) {
                                    final number = num.tryParse(value ?? '');
                                    return number == null || number < 0
                                        ? 'أدخل رقماً صحيحاً'
                                        : null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _trackInventory,
                            title: const Text('تتبّع مخزون هذا المنتج'),
                            subtitle: const Text(
                              'يمنع البيع عند نفاد الكمية ويُسجل كل حركة.',
                            ),
                            onChanged: (value) =>
                                setState(() => _trackInventory = value),
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            value: _isSerialized,
                            title: const Text('لكل قطعة رقم تسلسلي'),
                            subtitle: const Text(
                              'مناسب للهواتف والأجهزة؛ يطلب الرقم عند البيع.',
                            ),
                            onChanged: _trackInventory
                                ? (value) =>
                                      setState(() => _isSerialized = value)
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Section(
                      title: 'سياسة البيع والضمان',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'مدة الضمان الافتراضية',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [6, 12, 18, 24, 36]
                                .map(
                                  (months) => ChoiceChip(
                                    label: Text('$months شهراً'),
                                    selected: _warrantyMonths == months,
                                    onSelected: (_) => setState(
                                      () => _warrantyMonths = months,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _price,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: 'سعر البيع الافتراضي (اختياري)',
                              prefixIcon: const Icon(Icons.payments_outlined),
                              suffixText: currency.symbol,
                              helperText:
                                  'يُعرض ويُحفظ بعملة ${currency.name}.',
                            ),
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return null;
                              }
                              return num.tryParse(value!.trim()) == null
                                  ? 'أدخل رقماً صحيحاً'
                                  : null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: controller.busy ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          controller.busy
                              ? 'جارٍ الحفظ…'
                              : widget.product == null
                              ? 'حفظ المنتج'
                              : 'حفظ التعديلات',
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

  String? _optionalNonNegative(String? value) {
    if ((value ?? '').trim().isEmpty) return null;
    final number = num.tryParse(value!.trim());
    return number == null || number < 0 ? 'أدخل رقماً صحيحاً' : null;
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}
