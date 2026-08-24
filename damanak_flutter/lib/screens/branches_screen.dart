import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/branch.dart';
import '../models/account.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';

class BranchesScreen extends StatelessWidget {
  const BranchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final canEdit = controller.membership!.role.canManageTeam;
    return Scaffold(
      appBar: AppBar(
        title: const Text('الفروع ونقاط البيع'),
        actions: [
          if (canEdit)
            IconButton(
              tooltip: 'إضافة فرع',
              onPressed: controller.busy ? null : () => _editBranch(context),
              icon: const Icon(Icons.add_business_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                const MessageBanner(),
                Text(
                  'اربط كل ضمان بالفرع الذي نفّذ البيع حتى تصبح التقارير دقيقة.',
                  style: TextStyle(color: context.colors.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                if (controller.branches.isEmpty)
                  _EmptyBranches(
                    canEdit: canEdit,
                    onCreate: () => _editBranch(context),
                  )
                else
                  ...controller.branches.map(
                    (branch) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: canEdit
                            ? () => _editBranch(context, branch)
                            : null,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.colors.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.store_mall_directory_outlined,
                            color: context.colors.primary,
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                branch.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (branch.isMain) const _MainBranchBadge(),
                          ],
                        ),
                        subtitle: Text(
                          [
                            branch.type.label,
                            branch.city,
                            branch.code,
                            '${branch.opensAt}–${branch.closesAt}',
                          ].where((value) => value.isNotEmpty).join(' • '),
                        ),
                        trailing: canEdit
                            ? const Icon(Icons.edit_outlined)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: canEdit
          ? FloatingActionButton.extended(
              onPressed: controller.busy ? null : () => _editBranch(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('فرع جديد'),
            )
          : null,
    );
  }

  Future<void> _editBranch(BuildContext context, [StoreBranch? branch]) async {
    final draft = await Navigator.of(context).push<_BranchDraft>(
      MaterialPageRoute(builder: (_) => _BranchEditor(branch: branch)),
    );
    if (draft == null || !context.mounted) return;
    await AppScope.of(context).saveBranch(
      branchId: branch?.id,
      name: draft.name,
      code: draft.code,
      city: draft.city,
      address: draft.address,
      phone: draft.phone,
      isMain: draft.isMain,
      email: draft.email,
      managerName: draft.managerName,
      receiptPrefix: draft.receiptPrefix,
      timezone: draft.timezone,
      opensAt: draft.opensAt,
      closesAt: draft.closesAt,
      type: draft.type,
      acceptsSales: draft.acceptsSales,
      handlesService: draft.handlesService,
    );
  }
}

class _BranchEditor extends StatefulWidget {
  const _BranchEditor({this.branch});

  final StoreBranch? branch;

  @override
  State<_BranchEditor> createState() => _BranchEditorState();
}

class _BranchEditorState extends State<_BranchEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _city;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _managerName;
  late final TextEditingController _receiptPrefix;
  late final TextEditingController _timezone;
  late final TextEditingController _opensAt;
  late final TextEditingController _closesAt;
  late bool _isMain;
  late BranchType _type;
  late bool _acceptsSales;
  late bool _handlesService;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.branch?.name ?? '');
    _code = TextEditingController(text: widget.branch?.code ?? '');
    _city = TextEditingController(text: widget.branch?.city ?? '');
    _address = TextEditingController(text: widget.branch?.address ?? '');
    _phone = TextEditingController(text: widget.branch?.phone ?? '');
    _email = TextEditingController(text: widget.branch?.email ?? '');
    _managerName = TextEditingController(
      text: widget.branch?.managerName ?? '',
    );
    _receiptPrefix = TextEditingController(
      text: widget.branch?.receiptPrefix.isNotEmpty == true
          ? widget.branch!.receiptPrefix
          : widget.branch?.code ?? 'POS',
    );
    _timezone = TextEditingController(
      text: widget.branch?.timezone ?? 'Asia/Riyadh',
    );
    _opensAt = TextEditingController(text: widget.branch?.opensAt ?? '09:00');
    _closesAt = TextEditingController(text: widget.branch?.closesAt ?? '23:00');
    _isMain = widget.branch?.isMain ?? false;
    _type = widget.branch?.type ?? BranchType.retail;
    _acceptsSales = widget.branch?.acceptsSales ?? true;
    _handlesService = widget.branch?.handlesService ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _city.dispose();
    _address.dispose();
    _phone.dispose();
    _email.dispose();
    _managerName.dispose();
    _receiptPrefix.dispose();
    _timezone.dispose();
    _opensAt.dispose();
    _closesAt.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branch == null ? 'فرع جديد' : 'تعديل الفرع'),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هوية الفرع',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _name,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'اسم الفرع',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _code,
                                textCapitalization:
                                    TextCapitalization.characters,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'رمز الفرع',
                                  hintText: 'RUH-01',
                                ),
                                validator: _codeValidator,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<BranchType>(
                                initialValue: _type,
                                decoration: const InputDecoration(
                                  labelText: 'نوع الموقع',
                                ),
                                items: BranchType.values
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item,
                                        child: Text(item.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) =>
                                    setState(() => _type = value!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _managerName,
                          decoration: const InputDecoration(
                            labelText: 'مدير الفرع أو المسؤول',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'العنوان والتواصل',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _city,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'المدينة',
                          ),
                          validator: _required,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _address,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'العنوان التفصيلي',
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'رقم الفرع',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'بريد الفرع',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'نقطة البيع وساعات العمل',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _receiptPrefix,
                                textCapitalization:
                                    TextCapitalization.characters,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'بادئة الفاتورة',
                                  hintText: 'RUH',
                                ),
                                validator: _prefixValidator,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _timezone,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'المنطقة الزمنية',
                                ),
                                validator: _required,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _opensAt,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'يفتح',
                                  hintText: '09:00',
                                ),
                                validator: _timeValidator,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _closesAt,
                                textDirection: TextDirection.ltr,
                                decoration: const InputDecoration(
                                  labelText: 'يغلق',
                                  hintText: '23:00',
                                ),
                                validator: _timeValidator,
                              ),
                            ),
                          ],
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _acceptsSales,
                          title: const Text('يقبل عمليات البيع'),
                          subtitle: const Text(
                            'يظهر ضمن نقاط البيع ويمكن فتح صندوق له.',
                          ),
                          onChanged: (value) =>
                              setState(() => _acceptsSales = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _handlesService,
                          title: const Text('يستقبل الصيانة والضمان'),
                          subtitle: const Text(
                            'يمكن ربط طلبات الخدمة بهذا الموقع.',
                          ),
                          onChanged: (value) =>
                              setState(() => _handlesService = value),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: _isMain,
                          title: const Text('الفرع الرئيسي'),
                          subtitle: const Text(
                            'يصبح الاختيار الافتراضي للعمليات.',
                          ),
                          onChanged: (value) => setState(() => _isMain = value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('حفظ الفرع ونقطة البيع'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _BranchDraft(
        name: _name.text,
        code: _code.text,
        city: _city.text,
        address: _address.text,
        phone: _phone.text,
        email: _email.text,
        managerName: _managerName.text,
        receiptPrefix: _receiptPrefix.text,
        timezone: _timezone.text,
        opensAt: _opensAt.text,
        closesAt: _closesAt.text,
        type: _type,
        acceptsSales: _acceptsSales,
        handlesService: _handlesService,
        isMain: _isMain,
      ),
    );
  }

  String? _codeValidator(String? value) =>
      RegExp(r'^[A-Za-z0-9-]{2,12}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'استخدم 2–12 حرفاً أو رقماً لاتينياً';
  String? _prefixValidator(String? value) =>
      RegExp(r'^[A-Za-z0-9]{2,8}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'استخدم 2–8 أحرف أو أرقام';
  String? _timeValidator(String? value) =>
      RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(value?.trim() ?? '')
      ? null
      : 'استخدم صيغة 09:00';

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'هذا الحقل مطلوب' : null;
}

class _BranchDraft {
  const _BranchDraft({
    required this.name,
    required this.code,
    required this.city,
    required this.address,
    required this.phone,
    required this.email,
    required this.managerName,
    required this.receiptPrefix,
    required this.timezone,
    required this.opensAt,
    required this.closesAt,
    required this.type,
    required this.acceptsSales,
    required this.handlesService,
    required this.isMain,
  });

  final String name;
  final String code;
  final String city;
  final String address;
  final String phone;
  final String email;
  final String managerName;
  final String receiptPrefix;
  final String timezone;
  final String opensAt;
  final String closesAt;
  final BranchType type;
  final bool acceptsSales;
  final bool handlesService;
  final bool isMain;
}

class _MainBranchBadge extends StatelessWidget {
  const _MainBranchBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'رئيسي',
        style: TextStyle(
          color: colors.onPrimaryContainer,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyBranches extends StatelessWidget {
  const _EmptyBranches({required this.canEdit, required this.onCreate});

  final bool canEdit;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.store_mall_directory_outlined),
            const SizedBox(height: 10),
            const Text('لم يُسجل أي فرع بعد.'),
            if (canEdit) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة الفرع الأول'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
