import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/store_profile.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';
import '../widgets/page_frame.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final profile = AppScope.of(context).profile;
    _name.text = profile.name;
    _phone.text = profile.phone;
    _city.text = profile.city;
    _loaded = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    await AppScope.of(context).updateProfile(
      StoreProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        city: _city.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ بيانات المتجر.')));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    return PageFrame(
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'بيانات المتجر',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          const Text(
            'تظهر هذه البيانات عند مشاركة بطاقة الضمان.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerRight,
                      child: BrandMark(),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'اسم المتجر',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'اسم المتجر مطلوب';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(
                        labelText: 'رقم التواصل (اختياري)',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _city,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _save(),
                      decoration: const InputDecoration(
                        labelText: 'المدينة (اختياري)',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(_saving ? 'جارٍ الحفظ…' : 'حفظ البيانات'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  color: AppColors.emerald,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'بياناتك تبقى على جهازك',
                        style: TextStyle(
                          color: AppColors.emeraldDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'لا توجد حسابات أو خوادم أو رسوم اشتراك. حذف التطبيق قد يحذف البيانات المحلية، لذلك احتفظ بنسخة من البطاقات المهمة عبر المشاركة.',
                        style: TextStyle(
                          color: AppColors.emeraldDark,
                          fontSize: 12,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${controller.warranties.length} ضمان • ${controller.requests.length} طلب صيانة',
                        style: const TextStyle(
                          color: AppColors.emeraldDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'ضمانك 1.0.0',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
