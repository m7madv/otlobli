import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';

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
  String _country = 'SA';
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final store = AppScope.of(context).store!;
    _name.text = store.name;
    _phone.text = store.phone;
    _city.text = store.city;
    _country = store.countryCode;
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
    if (!_formKey.currentState!.validate()) return;
    await AppScope.of(context).updateStore(
      name: _name.text,
      phone: _phone.text,
      city: _city.text,
      countryCode: _country,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colors = context.colors;
    final canEdit = controller.membership!.role.canManageTeam;
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات المتجر')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MessageBanner(),
                    if (!canEdit)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'تعديل بيانات المتجر متاح للمالك والمدير فقط.',
                        ),
                      ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _name,
                              enabled: canEdit,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'اسم المتجر',
                                prefixIcon: Icon(Icons.storefront_outlined),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'اسم المتجر مطلوب'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              initialValue: _country,
                              decoration: const InputDecoration(
                                labelText: 'الدولة',
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'SA',
                                  child: Text('السعودية'),
                                ),
                                DropdownMenuItem(
                                  value: 'AE',
                                  child: Text('الإمارات'),
                                ),
                                DropdownMenuItem(
                                  value: 'KW',
                                  child: Text('الكويت'),
                                ),
                                DropdownMenuItem(
                                  value: 'QA',
                                  child: Text('قطر'),
                                ),
                                DropdownMenuItem(
                                  value: 'BH',
                                  child: Text('البحرين'),
                                ),
                                DropdownMenuItem(
                                  value: 'OM',
                                  child: Text('عُمان'),
                                ),
                              ],
                              onChanged: canEdit
                                  ? (value) => setState(
                                      () => _country = value ?? _country,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _city,
                              enabled: canEdit,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'المدينة',
                                prefixIcon: Icon(Icons.location_city_outlined),
                              ),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty
                                  ? 'المدينة مطلوبة'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _phone,
                              enabled: canEdit,
                              keyboardType: TextInputType.phone,
                              textDirection: TextDirection.ltr,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _save(),
                              decoration: const InputDecoration(
                                labelText: 'رقم التواصل',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 7
                                  ? 'أدخل رقم تواصل صحيحاً'
                                  : null,
                            ),
                            if (canEdit) ...[
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: controller.busy ? null : _save,
                                  icon: const Icon(Icons.save_outlined),
                                  label: Text(
                                    controller.busy
                                        ? 'جارٍ الحفظ…'
                                        : 'حفظ بيانات المتجر',
                                  ),
                                ),
                              ),
                            ],
                          ],
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
}
