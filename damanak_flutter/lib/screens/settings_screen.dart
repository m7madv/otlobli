import 'package:damanak/l10n/l10n.dart';
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
    L10n.watch(context);
    final controller = AppScope.of(context);
    final colors = context.colors;
    final canEdit = controller.membership!.role.canManageTeam;
    final canBrand = controller.subscription!.plan.customBranding;
    return Scaffold(
      appBar: AppBar(title: Text(L10n.current.msg97432797c672)),
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
                        child: Text(L10n.current.msg5b7c86ff0822),
                      ),
                    _SettingsSection(
                      title: L10n.current.msg6070d0810577,
                      icon: Icons.storefront_outlined,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _name,
                            enabled: canEdit,
                            textInputAction: TextInputAction.next,
                            decoration: InputDecoration(
                              labelText: L10n.current.msga9ac0e475f40,
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                            validator: _required,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _country,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: L10n.current.msgc431df1c0011,
                              prefixIcon: Icon(Icons.public_outlined),
                            ),
                            items: _countries.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(L10n.knownLabel(entry.value)),
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
                            decoration: InputDecoration(
                              labelText: L10n.current.msg23ee0d351c7b,
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
                            decoration: InputDecoration(
                              labelText: L10n.current.msg491712d63cd1,
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
                            decoration: InputDecoration(
                              labelText: L10n.current.msgb6dc7e167c03,
                              prefixIcon: Icon(Icons.phone_outlined),
                            ),
                            validator: (value) =>
                                (value?.trim().length ?? 0) < 7
                                ? L10n.current.msgbe10c77a7a79
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      title: L10n.current.msg166c2ffa66b6,
                      icon: Icons.verified_outlined,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!canBrand)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                L10n.current.msg54c0a3ec665a,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          TextFormField(
                            controller: _customerPortalTitle,
                            enabled: canEdit && canBrand,
                            maxLength: 80,
                            decoration: InputDecoration(
                              labelText: L10n.current.msgc0bf39194a34,
                              hintText: L10n.current.msge7139553cc0c,
                              prefixIcon: Icon(Icons.title_rounded),
                            ),
                            validator: (value) {
                              if (!canBrand) return null;
                              final length = value?.trim().length ?? 0;
                              return length < 3
                                  ? L10n.current.msgcb479a339dcd
                                  : null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _logoUrl,
                            enabled: canEdit && canBrand,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.url,
                            decoration: InputDecoration(
                              labelText: L10n.current.msg2436efa6ba23,
                              prefixIcon: Icon(Icons.image_outlined),
                              helperText: L10n.current.msg8c55f5ec55e5,
                            ),
                            validator: (value) {
                              final url = value?.trim() ?? '';
                              if (url.isEmpty || !canBrand) return null;
                              final parsed = Uri.tryParse(url);
                              return parsed?.scheme == 'https' &&
                                      parsed!.host.isNotEmpty
                                  ? null
                                  : L10n.current.msg36c629f2a1bb;
                            },
                          ),
                          const SizedBox(height: 14),
                          Text(
                            L10n.current.msg283f640cdd9a,
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
                      title: L10n.current.msg4dcfe919a879,
                      icon: Icons.payments_outlined,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            initialValue: _currency,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: L10n.current.msgaf4cf170eb41,
                              prefixIcon: Icon(Icons.payments_outlined),
                            ),
                            items: supportedCurrencies
                                .map(
                                  (currency) => DropdownMenuItem(
                                    value: currency.code,
                                    child: Text(
                                      '${currency.localizedName} (${currency.symbol})',
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
                            decoration: InputDecoration(
                              labelText: L10n.current.msg810d79d7b286,
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsSection(
                      title: L10n.current.msge5f551c71c20,
                      icon: Icons.receipt_outlined,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _invoicePrefix,
                            enabled: canEdit,
                            textCapitalization: TextCapitalization.characters,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(
                              labelText: L10n.current.msgad638a0ea91c,
                              hintText: 'INV',
                              prefixIcon: Icon(Icons.numbers_rounded),
                              helperText: L10n.current.msg21fa5d68e184,
                            ),
                            validator: (value) {
                              final prefix = value?.trim() ?? '';
                              return RegExp(
                                    r'^[A-Za-z0-9]{2,8}$',
                                  ).hasMatch(prefix)
                                  ? null
                                  : L10n.current.msgda983896ba06;
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            initialValue: _defaultWarrantyMonths,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: L10n.current.msg8b208f6650c6,
                              prefixIcon: Icon(Icons.event_repeat_outlined),
                            ),
                            items: const [3, 6, 12, 18, 24, 36, 60]
                                .map(
                                  (months) => DropdownMenuItem(
                                    value: months,
                                    child: Text(
                                      L10n.current.msg5ec8afa2a31e(months),
                                    ),
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
                            decoration: InputDecoration(
                              labelText: L10n.current.msgdcfacfb8d15b,
                              hintText: L10n.current.msg70a3b2113590,
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
                            decoration: InputDecoration(
                              labelText: L10n.current.msg4eafb03d32c3,
                              hintText: L10n.current.msg456150a31b87,
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
                                ? L10n.current.msg47d263ad0ba4
                                : L10n.current.msge3d20512e7c5,
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

  String? _required(String? value) => value == null || value.trim().isEmpty
      ? L10n.current.msgd5a02f880a17
      : null;
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
    L10n.watch(context);
    final color = Color(int.parse(value.substring(1), radix: 16) + 0xFF000000);
    return Semantics(
      button: true,
      selected: selected,
      label: selected
          ? L10n.current.msgbbc5a156723d
          : L10n.current.msg048375d837b9,
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
    L10n.watch(context);
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
