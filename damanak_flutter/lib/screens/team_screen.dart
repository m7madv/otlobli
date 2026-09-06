import 'package:damanak/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';

class TeamScreen extends StatelessWidget {
  const TeamScreen({super.key});

  Future<void> _createInvite(BuildContext context) async {
    final controller = AppScope.of(context);
    MemberRole role = MemberRole.staff;
    final canInviteManager = controller.membership!.role == MemberRole.owner;
    final result = await showModalBottomSheet<MemberRole>(
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
                L10n.current.msg397e16a0e4a3,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                L10n.current.msg114968fff0a7,
                style: TextStyle(color: context.colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MemberRole>(
                isExpanded: true,
                initialValue: role,
                decoration: InputDecoration(
                  labelText: L10n.current.msg9f9b2c7c5fa3,
                ),
                items: [
                  DropdownMenuItem(
                    value: MemberRole.staff,
                    child: Text(L10n.current.msg47b852791fc9),
                  ),
                  if (canInviteManager)
                    DropdownMenuItem(
                      value: MemberRole.manager,
                      child: Text(L10n.current.msg37c0e9cb95c1),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setModalState(() => role = value);
                },
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lock_clock_outlined, size: 21),
                    SizedBox(width: 9),
                    Expanded(child: Text(L10n.current.msg97ca981f65f9)),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(role),
                  icon: const Icon(Icons.link_rounded),
                  label: Text(L10n.current.msgc6c9f3a75162),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    final invite = await controller.createInvite(result, 1);
    if (invite == null || !context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 40,
              color: sheetContext.colors.primary,
            ),
            const SizedBox(height: 9),
            Text(
              L10n.current.msgfd86392b6012,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 5),
            Text(
              L10n.current.msg7b625955c3da(
                invite.role.label,
                invite.expiresAt.day,
                invite.expiresAt.month,
              ),
              textAlign: TextAlign.center,
              style: TextStyle(color: sheetContext.colors.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Semantics(
              label: L10n.current.msg0f200a06edcd,
              image: true,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E5E3)),
                ),
                child: QrImageView(
                  data: invite.deepLink.toString(),
                  size: 146,
                  padding: EdgeInsets.zero,
                  semanticsLabel: L10n.current.msgabd2c43949e3,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              L10n.current.msgd082aef30638,
              textAlign: TextAlign.center,
              style: Theme.of(sheetContext).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: sheetContext.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    L10n.current.msg9d11c18a6282,
                    style: Theme.of(sheetContext).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 3),
                  SelectableText(
                    invite.code,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      fontSize: 21,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _shareInvite(
                  sheetContext,
                  storeName: controller.store!.name,
                  invite: invite,
                ),
                icon: const Icon(Icons.share_outlined),
                label: Text(L10n.current.msg350cf974d4f7),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: invite.code));
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(content: Text(L10n.current.msgd3890a3cd356)),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: Text(L10n.current.msg317f0d073ab6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareInvite(
    BuildContext context, {
    required String storeName,
    required StoreInvite invite,
  }) async {
    final box = context.findRenderObject() as RenderBox?;
    final text = L10n.current.msgc9fd72650eae(
      storeName,
      invite.role.label,
      invite.deepLink,
      invite.code,
    );
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: L10n.current.msgabd2c43949e3,
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final controller = AppScope.of(context);
    final canManage = controller.membership!.role.canManageTeam;
    final maxMembers = controller.subscription!.plan.maxMembers;
    return Scaffold(
      appBar: AppBar(title: Text(L10n.current.msgfae07b10b96b)),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: controller.busy ? null : () => _createInvite(context),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(L10n.current.msgb15038674e73),
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
                  L10n.current.msg23da27ce8a42,
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
    L10n.watch(context);
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
                  L10n.current.msgc81afcb062a9(used, limit),
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  L10n.current.msg29752ccea5d0,
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
                decoration: InputDecoration(
                  labelText: L10n.current.msg9f9b2c7c5fa3,
                ),
                items: [
                  DropdownMenuItem(
                    value: MemberRole.staff,
                    child: Text(L10n.current.msg45372718dd18),
                  ),
                  DropdownMenuItem(
                    value: MemberRole.manager,
                    child: Text(L10n.current.msg6a05608678d2),
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
                title: Text(L10n.current.msg200cab4b56b2),
                subtitle: Text(L10n.current.msg749800948e90),
                onChanged: member.role == MemberRole.owner
                    ? null
                    : (value) => setModalState(() => active = value),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop((role, active)),
                  child: Text(L10n.current.msgae3c6021608f),
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
    L10n.watch(context);
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
            member.fullName.trim().isEmpty
                ? L10n.current.msg7d06b69aad65
                : member.fullName.trim()[0],
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
                L10n.current.msg85742d892694,
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
          '${member.email}\n${member.role.label} • ${L10n.knownLabel(active ? 'فعّال' : 'موقوف')}',
        ),
        isThreeLine: true,
        trailing: canManage && !isCurrentUser
            ? IconButton(
                tooltip: L10n.current.msg914ac743e9ca,
                onPressed: () => _edit(context),
                icon: const Icon(Icons.manage_accounts_outlined),
              )
            : null,
      ),
    );
  }
}
