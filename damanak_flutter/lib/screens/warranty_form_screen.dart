import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';
import 'warranty_detail_screen.dart';

class WarrantyFormScreen extends StatefulWidget {
  const WarrantyFormScreen({super.key});

  @override
  State<WarrantyFormScreen> createState() => _WarrantyFormScreenState();
}

class _WarrantyFormScreenState extends State<WarrantyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerName = TextEditingController();
  final _customerPhone = TextEditingController();
  final _productName = TextEditingController();
  final _serialNumber = TextEditingController();
  final _notes = TextEditingController();
  DateTime _purchaseDate = DateTime.now();
  int _durationMonths = 12;
  bool _saving = false;

  DateTime get _expiryDate => addMonths(_purchaseDate, _durationMonths);

  @override
  void dispose() {
    _customerName.dispose();
    _customerPhone.dispose();
    _productName.dispose();
    _serialNumber.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickPurchaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2015),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'اختر تاريخ الشراء',
      cancelText: 'إلغاء',
      confirmText: 'اختيار',
    );
    if (picked != null && mounted) setState(() => _purchaseDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    final warranty = await AppScope.of(context).addWarranty(
      customerName: _customerName.text,
      customerPhone: _customerPhone.text,
      productName: _productName.text,
      serialNumber: _serialNumber.text,
      purchaseDate: _purchaseDate,
      expiryDate: _expiryDate,
      notes: _notes.text,
    );
    if (!mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) =>
            WarrantyDetailScreen(warrantyId: warranty.id, justCreated: true),
      ),
    );
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) return 'هذا الحقل مطلوب';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ضمان جديد')),
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
                      const _FormIntro(),
                      const SizedBox(height: 26),
                      _FormSection(
                        number: '01',
                        title: 'بيانات العميل',
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
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              decoration: const InputDecoration(
                                labelText: 'رقم الجوال',
                                hintText: '05xxxxxxxx',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (value) {
                                final requiredError = _required(value);
                                if (requiredError != null) return requiredError;
                                if (value!.trim().length < 8) {
                                  return 'أدخل رقم جوال صحيحاً';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _FormSection(
                        number: '02',
                        title: 'بيانات المنتج',
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _productName,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'اسم المنتج',
                                hintText: 'مثال: مكيف سبليت 18 ألف وحدة',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _serialNumber,
                              textDirection: TextDirection.ltr,
                              decoration: const InputDecoration(
                                labelText: 'الرقم التسلسلي (اختياري)',
                                prefixIcon: Icon(Icons.qr_code_2_rounded),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _FormSection(
                        number: '03',
                        title: 'مدة الضمان',
                        child: Column(
                          children: [
                            InkWell(
                              onTap: _pickPurchaseDate,
                              borderRadius: BorderRadius.circular(14),
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'تاريخ الشراء',
                                  prefixIcon: Icon(
                                    Icons.calendar_month_outlined,
                                  ),
                                  suffixIcon: Icon(
                                    Icons.edit_calendar_outlined,
                                  ),
                                ),
                                child: Text(formatDate(_purchaseDate)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: _durationMonths,
                              decoration: const InputDecoration(
                                labelText: 'مدة الضمان',
                                prefixIcon: Icon(
                                  Icons.hourglass_bottom_rounded,
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 3,
                                  child: Text('3 أشهر'),
                                ),
                                DropdownMenuItem(
                                  value: 6,
                                  child: Text('6 أشهر'),
                                ),
                                DropdownMenuItem(
                                  value: 12,
                                  child: Text('سنة واحدة'),
                                ),
                                DropdownMenuItem(
                                  value: 24,
                                  child: Text('سنتان'),
                                ),
                                DropdownMenuItem(
                                  value: 36,
                                  child: Text('3 سنوات'),
                                ),
                                DropdownMenuItem(
                                  value: 60,
                                  child: Text('5 سنوات'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _durationMonths = value);
                                }
                              },
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.emerald,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'الضمان صالح حتى ${formatDate(_expiryDate)}',
                                      style: const TextStyle(
                                        color: AppColors.emeraldDark,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _FormSection(
                        number: '04',
                        title: 'ملاحظات',
                        child: TextFormField(
                          controller: _notes,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'شروط أو تفاصيل إضافية (اختياري)',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.verified_user_rounded),
                          label: Text(
                            _saving ? 'جارٍ الحفظ…' : 'إصدار بطاقة الضمان',
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
      ),
    );
  }
}

class _FormIntro extends StatelessWidget {
  const _FormIntro();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandMark(compact: true),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'أدخل معلومات الشراء مرة واحدة، ثم شارك البطاقة الرقمية مع العميل.',
              style: TextStyle(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.number,
    required this.title,
    required this.child,
  });

  final String number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              number,
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                color: AppColors.emerald,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 9),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
