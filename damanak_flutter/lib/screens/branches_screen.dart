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
                            branch.city,
                            branch.code,
                            branch.phone,
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
    final draft = await showDialog<_BranchDraft>(
      context: context,
      builder: (_) => _BranchEditor(branch: branch),
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
  late bool _isMain;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.branch?.name ?? '');
    _code = TextEditingController(text: widget.branch?.code ?? '');
    _city = TextEditingController(text: widget.branch?.city ?? '');
    _address = TextEditingController(text: widget.branch?.address ?? '');
    _phone = TextEditingController(text: widget.branch?.phone ?? '');
    _isMain = widget.branch?.isMain ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _city.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.branch == null ? 'فرع جديد' : 'تعديل الفرع'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'اسم الفرع'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'رمز الفرع',
                    hintText: 'RUH-01',
                  ),
                  validator: (value) =>
                      RegExp(
                        r'^[A-Za-z0-9-]{2,12}$',
                      ).hasMatch(value?.trim() ?? '')
                      ? null
                      : 'استخدم 2–12 حرفاً أو رقماً لاتينياً',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _city,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'المدينة'),
                  validator: _required,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  minLines: 2,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'العنوان التفصيلي (اختياري)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  decoration: const InputDecoration(
                    labelText: 'رقم الفرع (اختياري)',
                  ),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _isMain,
                  title: const Text('الفرع الرئيسي'),
                  subtitle: const Text(
                    'سيصبح الاختيار الافتراضي عند إصدار الضمان.',
                  ),
                  onChanged: (value) => setState(() => _isMain = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _BranchDraft(
                name: _name.text,
                code: _code.text,
                city: _city.text,
                address: _address.text,
                phone: _phone.text,
                isMain: _isMain,
              ),
            );
          },
          child: const Text('حفظ الفرع'),
        ),
      ],
    );
  }

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
    required this.isMain,
  });

  final String name;
  final String code;
  final String city;
  final String address;
  final String phone;
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
