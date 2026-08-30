import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
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
  final _address = TextEditingController();
  final _commercialRegistration = TextEditingController();
  final _invoicePrefix = TextEditingController();
  final _logoUrl = TextEditingController();
  final _customerPortalTitle = TextEditingController();
  final _warrantyPolicy = TextEditingController();
  final _warrantyExclusions = TextEditingController();
  String _country = 'SA';
  String _currency = 'SAR';
  int _defaultWarrantyMonths = 12;
  String _brandColor = '#087F5B';
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final store = AppScope.of(context).store!;
    _name.text = store.name;
    _phone.text = store.phone;
    _city.text = store.city;
    _address.text = store.address;
    _commercialRegistration.text = store.commercialRegistration;
    _invoicePrefix.text = store.invoicePrefix;
    _logoUrl.text = store.logoUrl;
    _customerPortalTitle.text = store.customerPortalTitle;
    _warrantyPolicy.text = store.warrantyPolicy;
    _warrantyExclusions.text = store.warrantyExclusions;
    _country = store.countryCode;
    _currency = store.currencyCode;
    _defaultWarrantyMonths = store.defaultWarrantyMonths;
    _brandColor = store.brandColor;
    _loaded = true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    _address.dispose();
    _commercialRegistration.dispose();
    _invoicePrefix.dispose();
    _logoUrl.dispose();
    _customerPortalTitle.dispose();
    _warrantyPolicy.dispose();
    _warrantyExclusions.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await AppScope.of(context).updateStore(
      name: _name.text,
      phone: _phone.text,
      city: _city.text,
      countryCode: _country,
      currencyCode: _currency,
      taxRate: 0,
      pricesIncludeTax: true,
      taxNumber: '',
      commercialRegistration: _commercialRegistration.text,
      address: _address.text,
      invoicePrefix: _invoicePrefix.text,
      defaultWarrantyMonths: _defaultWarrantyMonths,
      logoUrl: _logoUrl.text,
      brandColor: _brandColor,
      customerPortalTitle: _customerPortalTitle.text,
      warrantyPolicy: _warrantyPolicy.text,
      warrantyExclusions: _warrantyExclusions.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colors = context.colors;
    final canEdit = controller.membership!.role.canManageTeam;
    final canBrand = controller.subscription!.plan.customBranding;
    return Scaffold(
      appBar: AppBar(title: const Text('بيانات المتجر')),
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
                    if (!canEdit)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'تعديل إعدادات المتجر متاح للمالك والمدير فقط.',
                        ),
                      ),
                    _SettingsSection(
                      title: 'هوية المتجر',
                      icon: Icons.storefront_outlined,
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
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _country,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'الدولة',
                              prefixIcon: Icon(Icons.public_outlined),
                            ),
                            items: _countries.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                            onChanged: canEdit
                                ? (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _country = value;
                                      _currency = defaultCurrencyForCountry(
                                        value,
                                      );
                                    });
                                  }
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
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _address,
                            enabled: canEdit,
                            minLines: 2,
                            maxLines: 3,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              labelText: 'العنوان التفصيلي',
                              prefixIcon: Icon(Icons.location_on_outlined),
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _phone,
                            enabled: canEdit,
                            keyboardType: TextInputType.phone,
                            textDirection: TextDirection.ltr,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'رقم التواصل',
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) =>
                                (value?.trim().length ?? 0) < 7
                                ? 'أدخل رقم تواصل صحيحاً'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      title: 'هوية بطاقة العميل',
                      icon: Icons.verified_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!canBrand)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'الهوية المخصصة مشمولة في باقتي نمو وتوسع. ستبقى هوية ضمانك الافتراضية في الباقة الحالية.',
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          TextFormField(
                            controller: _customerPortalTitle,
                            enabled: canEdit && canBrand,
                            maxLength: 80,
                            decoration: const InputDecoration(
                              labelText: 'عنوان بطاقة الضمان',
                              hintText: 'بطاقة ضمان موثّقة',
                              prefixIcon: Icon(Icons.title_rounded),
                            ),
                            validator: (value) {
                              if (!canBrand) return null;
                              final length = value?.trim().length ?? 0;
                              return length < 3 ? 'اكتب عنواناً واضحاً' : null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _logoUrl,
                            enabled: canEdit && canBrand,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'رابط شعار HTTPS (اختياري)',
                              prefixIcon: Icon(Icons.image_outlined),
                              helperText:
                                  'استخدم رابط صورة ثابتاً ومشفراً. لن يظهر الرابط نفسه للعميل.',
                            ),
                            validator: (value) {
                              final url = value?.trim() ?? '';
                              if (url.isEmpty || !canBrand) return null;
                              final parsed = Uri.tryParse(url);
                              return parsed?.scheme == 'https' &&
                                      parsed!.host.isNotEmpty
                                  ? null
                                  : 'استخدم رابطاً يبدأ بـ https://';
                            },
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'لون واحد للهوية',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              for (final value in _brandColors)
                                _BrandColorButton(
                                  value: value,
                                  selected: value == _brandColor,
                                  enabled: canEdit && canBrand,
                                  onSelected: () =>
                                      setState(() => _brandColor = value),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      title: 'العملة والسجل',
                      icon: Icons.payments_outlined,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _currency,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'عملة المتجر الأساسية',
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            items: supportedCurrencies
                                .map(
                                  (currency) => DropdownMenuItem(
                                    value: currency.code,
                                    child: Text(
                                      '${currency.name} (${currency.symbol})',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: canEdit
                                ? (value) => setState(
                                    () => _currency = value ?? _currency,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _commercialRegistration,
                            enabled: canEdit,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              labelText: 'السجل التجاري (اختياري)',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      title: 'الإيصالات والضمان',
                      icon: Icons.receipt_outlined,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _invoicePrefix,
                            enabled: canEdit,
                            textCapitalization: TextCapitalization.characters,
                            textDirection: TextDirection.ltr,
                            decoration: const InputDecoration(
                              labelText: 'بادئة رقم الإيصال',
                              hintText: 'INV',
                              prefixIcon: Icon(Icons.numbers_rounded),
                              helperText: 'من 2 إلى 8 أحرف أو أرقام لاتينية.',
                            ),
                            validator: (value) {
                              final prefix = value?.trim() ?? '';
                              return RegExp(
                                    r'^[A-Za-z0-9]{2,8}$',
                                  ).hasMatch(prefix)
                                  ? null
                                  : 'استخدم 2–8 أحرف أو أرقام لاتينية';
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _defaultWarrantyMonths,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'مدة الضمان الافتراضية',
                              prefixIcon: Icon(Icons.event_repeat_outlined),
                            ),
                            items: const [3, 6, 12, 18, 24, 36, 60]
                                .map(
                                  (months) => DropdownMenuItem(
                                    value: months,
                                    child: Text('$months شهراً'),
                                  ),
                                )
                                .toList(),
                            onChanged: canEdit
                                ? (value) => setState(
                                    () => _defaultWarrantyMonths =
                                        value ?? _defaultWarrantyMonths,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _warrantyPolicy,
                            enabled: canEdit,
                            minLines: 3,
                            maxLines: 7,
                            maxLength: 4000,
                            decoration: const InputDecoration(
                              labelText: 'ما الذي يغطيه الضمان؟',
                              hintText:
                                  'مثال: عيوب الصناعة والأعطال الداخلية خلال مدة الضمان.',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.policy_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _warrantyExclusions,
                            enabled: canEdit,
                            minLines: 3,
                            maxLines: 7,
                            maxLength: 4000,
                            decoration: const InputDecoration(
                              labelText: 'الاستثناءات',
                              hintText:
                                  'مثال: الكسر، السوائل، وسوء الاستخدام ما لم يُذكر غير ذلك.',
                              alignLabelWithHint: true,
                              prefixIcon: Icon(Icons.gpp_bad_outlined),
                            ),
                          ),
                        ],
                      ),
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
                                : 'حفظ إعدادات المتجر',
                          ),
                        ),
                      ),
                    ],
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

const _countries = <String, String>{
  'SA': 'السعودية',
  'AE': 'الإمارات',
  'KW': 'الكويت',
  'QA': 'قطر',
  'BH': 'البحرين',
  'OM': 'عُمان',
  'SY': 'سوريا',
};

const _brandColors = <String>[
  '#087F5B',
  '#1D4ED8',
  '#6D28D9',
  '#9F1239',
  '#334155',
  '#7C2D12',
];

class _BrandColorButton extends StatelessWidget {
  const _BrandColorButton({
    required this.value,
    required this.selected,
    required this.enabled,
    required this.onSelected,
  });

  final String value;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final color = Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
    return Semantics(
      button: true,
      selected: selected,
      label: selected ? 'لون الهوية المحدد' : 'اختيار لون الهوية',
      child: InkWell(
        onTap: enabled ? onSelected : null,
        customBorder: const CircleBorder(),
        child: SizedBox.square(
          dimension: 48,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: enabled ? color : color.withValues(alpha: 0.35),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? context.colors.onSurface : Colors.transparent,
                width: 3,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
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
