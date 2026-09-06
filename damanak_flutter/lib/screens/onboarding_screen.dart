import 'package:damanak/l10n/l10n.dart';
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
    L10n.watch(context);
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
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final compact =
                          constraints.maxWidth < 420 || textScale >= 1.3;
                      final iconOnly =
                          constraints.maxWidth < 320 && textScale >= 1.6;
                      return Row(
                        children: [
                          Expanded(
                            child: BrandMark(
                              compact: compact,
                              iconOnly: iconOnly,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: controller.busy
                                ? null
                                : controller.signOut,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: Text(L10n.current.msg39db927c23ae),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    L10n.current.msg1779ceec5eef,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 7),
                  Text(
                    L10n.current.msg0580a86e3e83,
                    style: TextStyle(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 18),
                  const MessageBanner(),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale = MediaQuery.textScalerOf(
                        context,
                      ).scale(1);
                      final stackChoices =
                          constraints.maxWidth < 360 || textScale >= 1.6;
                      return SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<bool>(
                          direction: stackChoices
                              ? Axis.vertical
                              : Axis.horizontal,
                          segments: [
                            ButtonSegment(
                              value: false,
                              icon: Icon(Icons.add_business_rounded),
                              label: Text(L10n.current.msg1bd5869117c2),
                            ),
                            ButtonSegment(
                              value: true,
                              icon: Icon(Icons.group_add_outlined),
                              label: Text(L10n.current.msg92ed9866f7c3),
                            ),
                          ],
                          selected: {_joining},
                          showSelectedIcon: false,
                          onSelectionChanged: (value) {
                            controller.clearMessages();
                            setState(() => _joining = value.first);
                          },
                        ),
                      );
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
    L10n.watch(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                L10n.current.msg97432797c672,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: storeName,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: L10n.current.msga9ac0e475f40,
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
                validator: (value) => value == null || value.trim().length < 2
                    ? L10n.current.msg3a8d048d5e4d
                    : null,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final countryField = DropdownButtonFormField<String>(
                    initialValue: country,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: L10n.current.msgc431df1c0011,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'QA',
                        child: Text(L10n.current.msg8305ce4b9abd),
                      ),
                      DropdownMenuItem(
                        value: 'SA',
                        child: Text(L10n.current.msg1f95822cfb7d),
                      ),
                      DropdownMenuItem(
                        value: 'AE',
                        child: Text(L10n.current.msgdd3c0e93e763),
                      ),
                      DropdownMenuItem(
                        value: 'KW',
                        child: Text(L10n.current.msg3c35f06de352),
                      ),
                      DropdownMenuItem(
                        value: 'BH',
                        child: Text(L10n.current.msg5cd57d0c88af),
                      ),
                      DropdownMenuItem(
                        value: 'OM',
                        child: Text(L10n.current.msg0686c80527f1),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) onCountryChanged(value);
                    },
                  );
                  final cityField = TextFormField(
                    controller: city,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: L10n.current.msg23ee0d351c7b,
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? L10n.current.msg37214777bc9f
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
                decoration: InputDecoration(
                  labelText: L10n.current.msgf88494098b0b,
                  hintText: '+974 0000 0000',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 7
                    ? L10n.current.msgbe10c77a7a79
                    : null,
              ),
              const SizedBox(height: 18),
              Text(
                L10n.current.msgf5696ee7fa28,
                style: TextStyle(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onSubmit,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(
                    busy
                        ? L10n.current.msg2e2581d7092a
                        : L10n.current.msg13243d6e07c6,
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
    L10n.watch(context);
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
                L10n.current.msgb0c1a6b0c3a3,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 7),
              Text(
                invitationRole == null
                    ? L10n.current.msg186d2c125047
                    : L10n.current.msgdb794a28a328(invitationRole!.label),
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: invite,
                textCapitalization: TextCapitalization.characters,
                textDirection: TextDirection.ltr,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => onSubmit(),
                decoration: InputDecoration(
                  labelText: L10n.current.msg6bdc508afffd,
                  hintText: 'DMN-A1B2C3D4E5',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 6
                    ? L10n.current.msg9bb061e26503
                    : null,
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onSubmit,
                  icon: const Icon(Icons.group_add_rounded),
                  label: Text(
                    busy
                        ? L10n.current.msg52892306c67a
                        : L10n.current.msgdea2b5ee4ce1,
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
