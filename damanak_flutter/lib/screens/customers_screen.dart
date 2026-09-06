import 'package:damanak/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/customer.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    final query = _search.text;
    final customers = controller.customers
        .where((item) => item.matches(query))
        .toList();
    final warrantyCounts = <String, int>{};
    for (final warranty in controller.warranties) {
      final key = warranty.customerId ?? 'phone:${warranty.customerPhone}';
      warrantyCounts[key] = (warrantyCounts[key] ?? 0) + 1;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.current.msg8f965fa8332e),
        actions: [
          IconButton(
            tooltip: L10n.current.msgbf5ecb5e2537,
            onPressed: controller.busy ? null : () => _editCustomer(),
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const MessageBanner(),
                        TextField(
                          controller: _search,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: L10n.current.msg72cd9e69b93e,
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: L10n.current.msg2e58b72edf70,
                                    onPressed: () {
                                      _search.clear();
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                L10n.current.msg3b446588152c,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            Text('${customers.length}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (customers.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                    sliver: SliverToBoxAdapter(
                      child: _EmptyCustomers(onCreate: () => _editCustomer()),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                    sliver: SliverList.separated(
                      itemCount: customers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        final count =
                            (warrantyCounts[customer.id] ?? 0) +
                            (warrantyCounts['phone:${customer.phone}'] ?? 0);
                        return _CustomerTile(
                          customer: customer,
                          warrantyCount: count,
                          onTap: () => _editCustomer(customer),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.busy ? null : () => _editCustomer(),
        icon: const Icon(Icons.add_rounded),
        label: Text(L10n.current.msg9f73e063ae8d),
      ),
    );
  }

  Future<void> _editCustomer([CustomerProfile? customer]) async {
    final draft = await showDialog<_CustomerDraft>(
      context: context,
      builder: (_) => _CustomerEditor(customer: customer),
    );
    if (draft == null || !mounted) return;
    await AppScope.of(context).saveCustomer(
      customerId: customer?.id,
      name: draft.name,
      phone: draft.phone,
      email: draft.email,
      notes: draft.notes,
    );
  }
}

class _CustomerTile extends StatelessWidget {
  const _CustomerTile({
    required this.customer,
    required this.warrantyCount,
    required this.onTap,
  });

  final CustomerProfile customer;
  final int warrantyCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final colors = context.colors;
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Text(
            customer.name.trim().isEmpty
                ? L10n.current.msg7d06b69aad65
                : customer.name[0],
          ),
        ),
        title: Text(
          customer.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 3),
            Text(customer.phone, textDirection: TextDirection.ltr),
            Text(L10n.current.msgcda60f94083b(warrantyCount)),
          ],
        ),
        trailing: const Icon(Icons.edit_outlined),
      ),
    );
  }
}

class _CustomerEditor extends StatefulWidget {
  const _CustomerEditor({this.customer});

  final CustomerProfile? customer;

  @override
  State<_CustomerEditor> createState() => _CustomerEditorState();
}

class _CustomerEditorState extends State<_CustomerEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _notes;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.customer?.name ?? '');
    _phone = TextEditingController(text: widget.customer?.phone ?? '');
    _email = TextEditingController(text: widget.customer?.email ?? '');
    _notes = TextEditingController(text: widget.customer?.notes ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    return AlertDialog(
      title: Text(
        widget.customer == null
            ? L10n.current.msg9f73e063ae8d
            : L10n.current.msgd21f656a885f,
      ),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: L10n.current.msg70771eb8320f,
                  ),
                  validator: (value) => value == null || value.trim().length < 2
                      ? L10n.current.msg149beb2779d5
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: L10n.current.msg6dbe8474b01b,
                  ),
                  validator: (value) => (value?.trim().length ?? 0) < 7
                      ? L10n.current.msg1635df2532a1
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: L10n.current.msg58d4f0f4cb39,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: L10n.current.msg651b7866185a,
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(L10n.current.msg9a30dc2a96b8),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _CustomerDraft(
                name: _name.text,
                phone: _phone.text,
                email: _email.text,
                notes: _notes.text,
              ),
            );
          },
          child: Text(L10n.current.msgc68629028b85),
        ),
      ],
    );
  }
}

class _CustomerDraft {
  const _CustomerDraft({
    required this.name,
    required this.phone,
    required this.email,
    required this.notes,
  });

  final String name;
  final String phone;
  final String email;
  final String notes;
}

class _EmptyCustomers extends StatelessWidget {
  const _EmptyCustomers({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.people_outline_rounded, color: colors.onSurfaceVariant),
            const SizedBox(height: 10),
            Text(L10n.current.msg6df30df80b8a),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: Text(L10n.current.msgbf5ecb5e2537),
            ),
          ],
        ),
      ),
    );
  }
}
