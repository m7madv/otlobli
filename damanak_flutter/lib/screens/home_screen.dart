import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/account.dart';
import '../models/maintenance_request.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';
import '../widgets/message_banner.dart';
import '../widgets/page_frame.dart';
import '../widgets/status_chip.dart';
import 'claim_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onCreateWarranty,
    required this.onScan,
    required this.onShowAllWarranties,
    required this.onShowRequests,
    required this.onShowAdmin,
    super.key,
  });

  final VoidCallback onCreateWarranty;
  final VoidCallback onScan;
  final VoidCallback onShowAllWarranties;
  final VoidCallback onShowRequests;
  final VoidCallback onShowAdmin;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final subscription = controller.subscription!;
    final warranties = controller.warranties;
    final requests = controller.requests;
    final activeCount = warranties
        .where((item) => item.statusAt() == WarrantyStatus.active)
        .length;
    final expiringCount = warranties
        .where((item) => item.statusAt() == WarrantyStatus.expiringSoon)
        .length;
    final openRequests = requests.where((item) => !item.status.isClosed).length;
    final overdueRequests = requests.where((item) => item.isOverdue).length;
    final unassignedRequests = requests
        .where((item) => !item.status.isClosed && item.assignedTo == null)
        .length;
    final readyRequests = requests
        .where((item) => item.status == MaintenanceStatus.readyForPickup)
        .length;
    final recentRequests = requests
        .where((item) => controller.warrantyById(item.warrantyId) != null)
        .take(3)
        .toList();

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MobileHeader(),
            if (controller.isDemo) const _DemoRibbon(),
            const MessageBanner(),
            _WorkspaceHeading(
              storeName: controller.store!.name,
              role: controller.membership!.role.label,
            ),
            if (overdueRequests + unassignedRequests + readyRequests > 0) ...[
              const SizedBox(height: 14),
              _TodayWorkCard(
                overdue: overdueRequests,
                unassigned: unassignedRequests,
                ready: readyRequests,
                onOpen: onShowRequests,
              ),
            ],
            const SizedBox(height: 18),
            _WarrantyStarter(onScan: onScan, onManual: onCreateWarranty),
            const SizedBox(height: 12),
            const _WarrantyPath(),
            const SizedBox(height: 12),
            _WarrantyPulse(
              active: activeCount,
              expiring: expiringCount,
              openRequests: openRequests,
              onShowWarranties: onShowAllWarranties,
              onShowRequests: onShowRequests,
            ),
            const SizedBox(height: 6),
            Text(
              'الأعداد حسب السجل المحمّل حالياً.',
              style: TextStyle(
                color: context.colors.onSurfaceVariant,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 12),
            _UsageStrip(
              used: subscription.usedWarranties,
              limit: subscription.plan.monthlyWarranties,
              trialDays: subscription.remainingTrialDays,
              isTrial: subscription.status == 'trialing',
              onTap: onShowAdmin,
            ),
            const SizedBox(height: 26),
            _SectionHeading(
              title: 'مطالبات الضمان الحديثة',
              actionLabel: 'عرض الكل',
              onAction: onShowRequests,
            ),
            const SizedBox(height: 10),
            if (recentRequests.isEmpty)
              _EmptyRequests(onOpen: onShowRequests)
            else
              ...recentRequests.map((request) {
                final warranty = controller.warrantyById(request.warrantyId)!;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RecentRequest(
                    request: request,
                    warranty: warranty,
                    onOpen: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ClaimDetailScreen(requestId: request.id),
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 820) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: BrandMark(compact: true),
    );
  }
}

class _DemoRibbon extends StatelessWidget {
  const _DemoRibbon();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        'عرض تشغيلي — يمكنك تجربة المسار كاملاً دون إرسال بيانات إلى خادم.',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _WorkspaceHeading extends StatelessWidget {
  const _WorkspaceHeading({required this.storeName, required this.role});

  final String storeName;
  final String role;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          storeName,
          style: Theme.of(context).textTheme.headlineSmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          '$role • إصدار الضمان ومتابعة الصيانة من مكان واحد',
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _TodayWorkCard extends StatelessWidget {
  const _TodayWorkCard({
    required this.overdue,
    required this.unassigned,
    required this.ready,
    required this.onOpen,
  });

  final int overdue;
  final int unassigned;
  final int ready;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final parts = <String>[
      if (overdue > 0) '$overdue متأخرة',
      if (unassigned > 0) '$unassigned بلا مسؤول',
      if (ready > 0) '$ready جاهزة للاستلام',
    ];
    return Semantics(
      button: true,
      label: 'متابعة اليوم، ${parts.join('، ')}',
      child: Card(
        color: overdue > 0 ? colors.errorContainer : colors.primaryContainer,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  overdue > 0
                      ? Icons.notification_important_outlined
                      : Icons.notifications_active_outlined,
                  color: overdue > 0
                      ? colors.onErrorContainer
                      : colors.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'متابعة اليوم',
                        style: TextStyle(
                          color: overdue > 0
                              ? colors.onErrorContainer
                              : colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        parts.join(' • '),
                        style: TextStyle(
                          color: overdue > 0
                              ? colors.onErrorContainer
                              : colors.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_back_rounded,
                  color: overdue > 0
                      ? colors.onErrorContainer
                      : colors.onPrimaryContainer,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WarrantyStarter extends StatelessWidget {
  const _WarrantyStarter({required this.onScan, required this.onManual});

  final VoidCallback onScan;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      container: true,
      label: 'بدء إصدار ضمان جديد',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.center_focus_strong_rounded,
                  color: colors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'ابدأ بمسح المنتج',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'نطابق الباركود مع الكتالوج، ثم تكمل بيانات العميل وتصدر الضمان.',
                style: TextStyle(color: colors.onSurfaceVariant, height: 1.5),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('home-scan-warranty'),
                    onPressed: onScan,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('مسح المنتج'),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('home-manual-warranty'),
                    onPressed: onManual,
                    icon: const Icon(Icons.keyboard_alt_outlined),
                    label: const Text('إدخال يدوي'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WarrantyPath extends StatelessWidget {
  const _WarrantyPath();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const steps = [
      (Icons.qr_code_2_rounded, 'امسح المنتج'),
      (Icons.person_outline_rounded, 'أدخل العميل'),
      (Icons.verified_user_outlined, 'أصدر الضمان'),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              children: [
                for (var index = 0; index < steps.length; index++) ...[
                  _PathStep(
                    number: index + 1,
                    icon: steps[index].$1,
                    label: steps[index].$2,
                  ),
                  if (index < steps.length - 1)
                    Divider(
                      height: 14,
                      indent: 40,
                      color: colors.outlineVariant,
                    ),
                ],
              ],
            );
          }
          return Row(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                Expanded(
                  child: _PathStep(
                    number: index + 1,
                    icon: steps[index].$1,
                    label: steps[index].$2,
                  ),
                ),
                if (index < steps.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: colors.outline,
                      size: 18,
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _PathStep extends StatelessWidget {
  const _PathStep({
    required this.number,
    required this.icon,
    required this.label,
  });

  final int number;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 9),
        Icon(icon, color: colors.onSurfaceVariant, size: 20),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _WarrantyPulse extends StatelessWidget {
  const _WarrantyPulse({
    required this.active,
    required this.expiring,
    required this.openRequests,
    required this.onShowWarranties,
    required this.onShowRequests,
  });

  final int active;
  final int expiring;
  final int openRequests;
  final VoidCallback onShowWarranties;
  final VoidCallback onShowRequests;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final items = [
      _PulseData(
        icon: Icons.verified_user_outlined,
        value: active,
        label: 'ضمان ساري',
        onTap: onShowWarranties,
      ),
      _PulseData(
        icon: Icons.schedule_rounded,
        value: expiring,
        label: 'قريب الانتهاء',
        onTap: onShowWarranties,
      ),
      _PulseData(
        icon: Icons.build_outlined,
        value: openRequests,
        label: 'صيانة مفتوحة',
        onTap: onShowRequests,
      ),
    ];
    return Card(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 560) {
            return Column(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  _PulseItem(data: items[index]),
                  if (index < items.length - 1)
                    Divider(height: 1, color: colors.outlineVariant),
                ],
              ],
            );
          }
          return IntrinsicHeight(
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++) ...[
                  Expanded(child: _PulseItem(data: items[index])),
                  if (index < items.length - 1)
                    VerticalDivider(width: 1, color: colors.outlineVariant),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PulseData {
  const _PulseData({
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final int value;
  final String label;
  final VoidCallback onTap;
}

class _PulseItem extends StatelessWidget {
  const _PulseItem({required this.data});

  final _PulseData data;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: data.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(data.icon, color: colors.primary, size: 22),
            const SizedBox(width: 10),
            Text(
              '${data.value}',
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                data.label,
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colors.onSurfaceVariant,
              size: 13,
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageStrip extends StatelessWidget {
  const _UsageStrip({
    required this.used,
    required this.limit,
    required this.trialDays,
    required this.isTrial,
    required this.onTap,
  });

  final int used;
  final int limit;
  final int trialDays;
  final bool isTrial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final ratio = limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$used من $limit ضماناً هذا الشهر',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (isTrial) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$trialDays يوم متبقٍ في التجربة',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Icon(
                Icons.settings_outlined,
                color: colors.onSurfaceVariant,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}

class _RecentRequest extends StatelessWidget {
  const _RecentRequest({
    required this.request,
    required this.warranty,
    required this.onOpen,
  });

  final MaintenanceRequest request;
  final Warranty warranty;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          warranty.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          warranty.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MaintenanceStatusChip(status: request.status),
                ],
              ),
              const SizedBox(height: 11),
              Text(
                request.issue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 9),
              Text(
                'آخر تحديث ${formatDate(request.updatedAt)}',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.task_alt_rounded, color: colors.primary, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'لا توجد مطالبات ضمان حديثة',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'تظهر هنا المطالبات المسجلة من بطاقات الضمان.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'فتح مركز المطالبات',
              onPressed: onOpen,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
