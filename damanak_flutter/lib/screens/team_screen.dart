import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  Future<void> _createInvite(BuildContext context) async {
    MemberRole role = MemberRole.staff;
    int maxUses = 1;
    final result = await showModalBottomSheet<(MemberRole, int)>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'دعوة عضو جديد',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'سيستخدم الموظف الرمز بعد إنشاء حسابه. لا تشارك كلمة مرورك أو جلستك.',
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MemberRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'الصلاحية'),
                items: const [
                  DropdownMenuItem(
                    value: MemberRole.staff,
                    child: Text('موظف — إصدار ضمانات وصيانة'),
                  ),
                  DropdownMenuItem(
                    value: MemberRole.manager,
                    child: Text('مدير — إدارة المنتجات والفريق'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setModalState(() => role = value);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: maxUses,
                decoration: const InputDecoration(
                  labelText: 'عدد مرات استخدام الرمز',
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('شخص واحد')),
                  DropdownMenuItem(value: 3, child: Text('3 أشخاص')),
                  DropdownMenuItem(value: 5, child: Text('5 أشخاص')),
                ],
                onChanged: (value) {
                  if (value != null) setModalState(() => maxUses = value);
                },
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop((role, maxUses)),
                  icon: const Icon(Icons.key_rounded),
                  label: const Text('إنشاء رمز الدعوة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final controller = AppScope.of(context);
    final invite = await controller.createInvite(result.$1, result.$2);
    if (invite == null || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 42,
              color: context.colors.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'رمز الدعوة جاهز',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              'صالح حتى ${invite.expiresAt.day}/${invite.expiresAt.month} ولعدد ${invite.maxUses} مستخدم.',
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: SelectableText(
                invite.code,
                textAlign: TextAlign.center,
                textDirection: TextDirection.ltr,
                style: const TextStyle(
                  fontSize: 24,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => SharePlus.instance.share(
                  ShareParams(
                    text:
                        'انضم إلى متجر ${controller.store!.name} في تطبيق ضمانك. أنشئ حسابك ثم اختر «الانضمام لمتجر» وأدخل الرمز: ${invite.code}',
                    subject: 'دعوة فريق ضمانك',
                  ),
                ),
                icon: const Icon(Icons.share_outlined),
                label: const Text('مشاركة الدعوة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final canManage = controller.membership!.role.canManageTeam;
    final maxMembers = controller.subscription!.plan.maxMembers;
    return Scaffold(
      appBar: AppBar(title: const Text('الفريق والصلاحيات')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: controller.busy ? null : () => _createInvite(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('دعوة عضو'),
            )
          : null,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 100),
              children: [
                const MessageBanner(),
                _SeatSummary(
                  used: controller.team
                      .where((item) => item.status == 'active')
                      .length,
                  limit: maxMembers,
                ),
                const SizedBox(height: 18),
                Text(
                  'أعضاء المتجر',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                ...controller.team.map(
                  (member) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _MemberCard(
                      member: member,
                      isCurrentUser: member.userId == controller.account!.id,
                      canManage: canManage,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SeatSummary extends StatelessWidget {
  const _SeatSummary({required this.used, required this.limit});

  final int used;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(Icons.groups_2_outlined, color: colors.primary, size: 31),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$used من $limit مقاعد مستخدمة',
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'كل شخص يدخل بحسابه؛ يمكن إيقافه دون تغيير كلمة مرور الآخرين.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.isCurrentUser,
    required this.canManage,
  });

  final TeamMember member;
  final bool isCurrentUser;
  final bool canManage;

  Future<void> _edit(BuildContext context) async {
    var role = member.role;
    var active = member.status == 'active';
    final result = await showModalBottomSheet<(MemberRole, bool)>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                member.fullName,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<MemberRole>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'الصلاحية'),
                items: const [
                  DropdownMenuItem(
                    value: MemberRole.staff,
                    child: Text('موظف'),
                  ),
                  DropdownMenuItem(
                    value: MemberRole.manager,
                    child: Text('مدير'),
                  ),
                ],
                onChanged: member.role == MemberRole.owner
                    ? null
                    : (value) {
                        if (value != null) setModalState(() => role = value);
                      },
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                value: active,
                contentPadding: EdgeInsets.zero,
                title: const Text('الحساب فعّال'),
                subtitle: const Text(
                  'عند الإيقاف يفقد العضو الوصول إلى المتجر.',
                ),
                onChanged: member.role == MemberRole.owner
                    ? null
                    : (value) => setModalState(() => active = value),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop((role, active)),
                  child: const Text('حفظ الصلاحيات'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result != null && context.mounted) {
      await AppScope.of(
        context,
      ).updateMember(userId: member.userId, role: result.$1, active: result.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = member.status == 'active';
    final colors = context.colors;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        leading: CircleAvatar(
          backgroundColor: active
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          foregroundColor: active ? colors.primary : colors.onSurfaceVariant,
          child: Text(
            member.fullName.trim().isEmpty ? '؟' : member.fullName.trim()[0],
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                member.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (isCurrentUser) ...[
              const SizedBox(width: 6),
              Text(
                'أنت',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${member.email}\n${member.role.label} • ${active ? 'فعّال' : 'موقوف'}',
        ),
        isThreeLine: true,
        trailing: canManage && !isCurrentUser
            ? IconButton(
                tooltip: 'تعديل الصلاحيات',
                onPressed: () => _edit(context),
                icon: const Icon(Icons.manage_accounts_outlined),
              )
            : null,
      ),
    );
  }
}
