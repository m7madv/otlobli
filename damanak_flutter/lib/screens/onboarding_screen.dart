import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';
import '../widgets/message_banner.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _createKey = GlobalKey<FormState>();
  final _joinKey = GlobalKey<FormState>();
  final _storeName = TextEditingController();
  final _phone = TextEditingController();
  final _city = TextEditingController();
  final _invite = TextEditingController();
  bool _joining = false;
  String _country = 'QA';
  String? _loadedInvitationCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pendingCode = AppScope.of(context).pendingInvitationCode;
    if (pendingCode == null || pendingCode == _loadedInvitationCode) return;
    _loadedInvitationCode = pendingCode;
    _invite.text = pendingCode;
    _joining = true;
  }

  @override
  void dispose() {
    _storeName.dispose();
    _phone.dispose();
    _city.dispose();
    _invite.dispose();
    super.dispose();
  }

  Future<void> _createStore() async {
    if (!_createKey.currentState!.validate()) return;
    await AppScope.of(context).createStore(
      name: _storeName.text,
      phone: _phone.text,
      city: _city.text,
      countryCode: _country,
    );
  }

  Future<void> _joinStore() async {
    if (!_joinKey.currentState!.validate()) return;
    await AppScope.of(context).joinStore(_invite.text);
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: BrandMark()),
                      TextButton.icon(
                        onPressed: controller.busy ? null : controller.signOut,
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('خروج'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'كيف ستعمل مع ضمانك؟',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'أنشئ مساحة لمتجرك إذا كنت المالك، أو انضم إلى متجر قائم برمز يرسله لك المدير.',
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 18),
                  const MessageBanner(),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        icon: Icon(Icons.add_business_rounded),
                        label: Text('إنشاء متجر'),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: Icon(Icons.group_add_outlined),
                        label: Text('الانضمام لمتجر'),
                      ),
                    ],
                    selected: {_joining},
                    showSelectedIcon: false,
                    onSelectionChanged: (value) {
                      controller.clearMessages();
                      setState(() => _joining = value.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    child: _joining
                        ? _JoinForm(
                            key: const ValueKey('join'),
                            formKey: _joinKey,
                            invite: _invite,
                            invitationRole: controller.pendingInvitationRole,
                            busy: controller.busy,
                            onSubmit: _joinStore,
                          )
                        : _CreateStoreForm(
                            key: const ValueKey('create'),
                            formKey: _createKey,
                            storeName: _storeName,
                            phone: _phone,
                            city: _city,
                            country: _country,
                            busy: controller.busy,
                            onCountryChanged: (value) =>
                                setState(() => _country = value),
                            onSubmit: _createStore,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CreateStoreForm extends StatelessWidget {
  const _CreateStoreForm({
    required this.formKey,
    required this.storeName,
    required this.phone,
    required this.city,
    required this.country,
    required this.busy,
    required this.onCountryChanged,
    required this.onSubmit,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController storeName;
  final TextEditingController phone;
  final TextEditingController city;
  final String country;
  final bool busy;
  final ValueChanged<String> onCountryChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بيانات المتجر',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: storeName,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'اسم المتجر',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? 'أدخل اسم المتجر'
                    : null,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final countryField = DropdownButtonFormField<String>(
                    initialValue: country,
                    decoration: const InputDecoration(labelText: 'الدولة'),
                    items: const [
                      DropdownMenuItem(value: 'QA', child: Text('قطر')),
                      DropdownMenuItem(value: 'SA', child: Text('السعودية')),
                      DropdownMenuItem(value: 'AE', child: Text('الإمارات')),
                      DropdownMenuItem(value: 'KW', child: Text('الكويت')),
                      DropdownMenuItem(value: 'BH', child: Text('البحرين')),
                      DropdownMenuItem(value: 'OM', child: Text('عُمان')),
                    ],
                    onChanged: (value) {
                      if (value != null) onCountryChanged(value);
                    },
                  );
                  final cityField = TextFormField(
                    controller: city,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'المدينة'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'أدخل المدينة'
                        : null,
                  );
                  if (constraints.maxWidth < 440) {
                    return Column(
                      children: [
                        countryField,
                        const SizedBox(height: 12),
                        cityField,
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: countryField),
                      const SizedBox(width: 10),
                      Expanded(child: cityField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: phone,
                keyboardType: TextInputType.phone,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit(),
                decoration: const InputDecoration(
                  labelText: 'رقم تواصل المتجر',
                  hintText: '+974 0000 0000',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 7
                    ? 'أدخل رقم تواصل صحيحاً'
                    : null,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onSubmit,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(
                    busy ? 'جارٍ إنشاء المتجر…' : 'إنشاء المتجر وبدء التجربة',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JoinForm extends StatelessWidget {
  const _JoinForm({
    required this.formKey,
    required this.invite,
    required this.invitationRole,
    required this.busy,
    required this.onSubmit,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController invite;
  final MemberRole? invitationRole;
  final bool busy;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'رمز دعوة الفريق',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 7),
              Text(
                invitationRole == null
                    ? 'افتح ضمانك وأدخل رمز الدعوة الذي أرسله المدير. لا تحتاج إلى كلمة مرور المالك.'
                    : 'تم تحميل الدعوة. صلاحيتك بعد الانضمام: ${invitationRole!.label}.',
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: invite,
                textCapitalization: TextCapitalization.characters,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit(),
                decoration: const InputDecoration(
                  labelText: 'رمز الدعوة',
                  hintText: 'DMN-A1B2C3D4E5',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 6
                    ? 'أدخل رمز الدعوة كاملاً'
                    : null,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onSubmit,
                  icon: const Icon(Icons.group_add_rounded),
                  label: Text(busy ? 'جارٍ الانضمام…' : 'تأكيد الانضمام'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
