import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';
import 'warranty_detail_screen.dart';

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
  final _productName = TextEditingController();
  final _barcode = TextEditingController();
  final _serialNumber = TextEditingController();
  final _notes = TextEditingController();
  Product? _selectedProduct;
  DateTime _purchaseDate = DateTime.now();
  int _durationMonths = 12;

  DateTime get _expiryDate => addMonths(_purchaseDate, _durationMonths);

  @override
  void initState() {
    super.initState();
    _selectProduct(widget.product);
    if (widget.scannedBarcode.isNotEmpty) _barcode.text = widget.scannedBarcode;
  }

  void _selectProduct(Product? product) {
    _selectedProduct = product;
    if (product != null) {
      _productName.text = product.name;
      _barcode.text = product.barcode;
      _durationMonths = product.warrantyMonths;
    }
  }

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _productName.dispose();
    _barcode.dispose();
    _serialNumber.dispose();
    _notes.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = AppScope.of(context);
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
    final warranty = await controller.addWarranty(
      productId: _selectedProduct?.id,
      customerName: _customerName.text,
      customerPhone: _customerPhone.text,
      productName: _productName.text,
      barcode: _barcode.text,
      serialNumber: _serialNumber.text,
      purchaseDate: _purchaseDate,
      expiryDate: _expiryDate,
      notes: _notes.text,
    );
    if (!mounted || warranty == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            WarrantyDetailScreen(warrantyId: warranty.id, justCreated: true),
      ),
    );
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('إصدار ضمان')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 740),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MessageBanner(),
                    _IssueHeader(
                      product: _selectedProduct,
                      expiryDate: _expiryDate,
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      title: 'المنتج',
                      icon: Icons.inventory_2_outlined,
                      child: Column(
                        children: [
                          DropdownButtonFormField<Product?>(
                            initialValue: _selectedProduct,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'اختيار من الكتالوج',
                            ),
                            items: [
                              const DropdownMenuItem<Product?>(
                                value: null,
                                child: Text('منتج غير مسجل — إدخال يدوي'),
                              ),
                              ...controller.products.map(
                                (product) => DropdownMenuItem<Product?>(
                                  value: product,
                                  child: Text(
                                    '${product.name} • ${product.barcode}',
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
                            controller: _productName,
                            readOnly: _selectedProduct != null,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'اسم المنتج',
                              prefixIcon: Icon(Icons.devices_other_outlined),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _barcode,
                            readOnly: _selectedProduct != null,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'الباركود (اختياري)',
                              prefixIcon: Icon(Icons.qr_code_2_rounded),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _serialNumber,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'الرقم التسلسلي (اختياري)',
                              prefixIcon: Icon(Icons.tag_rounded),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      title: 'العميل',
                      icon: Icons.person_outline_rounded,
                      child: Column(
                        children: [
                          TextFormField(
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
                      title: 'مدة الضمان',
                      icon: Icons.calendar_month_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _pickPurchaseDate,
                            borderRadius: BorderRadius.circular(13),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'تاريخ الشراء',
                                prefixIcon: Icon(Icons.event_outlined),
                              ),
                              child: Text(
                                '${_purchaseDate.day}/${_purchaseDate.month}/${_purchaseDate.year}',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'المدة',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [3, 6, 12, 18, 24, 36]
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
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _notes,
                            minLines: 2,
                            maxLines: 4,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              labelText: 'شروط أو ملاحظات (اختياري)',
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
                        onPressed: controller.busy ? null : _save,
                        icon: const Icon(Icons.verified_user_outlined),
                        label: Text(
                          controller.busy
                              ? 'جارٍ الإصدار…'
                              : 'إصدار بطاقة الضمان',
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
}

class _IssueHeader extends StatelessWidget {
  const _IssueHeader({required this.product, required this.expiryDate});

  final Product? product;
  final DateTime expiryDate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 56,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(Icons.receipt_long_rounded, color: colors.primary),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product?.name ?? 'ضمان بإدخال يدوي',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'ينتهي في ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
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
                Icon(icon, color: colors.primary, size: 21),
                const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
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
