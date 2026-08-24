import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../models/maintenance_request.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';
import '../widgets/message_banner.dart';
import '../widgets/page_frame.dart';
import '../widgets/warranty_card.dart';
import 'warranty_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onCreateWarranty,
    required this.onScan,
    required this.onShowAllWarranties,
    required this.onShowProducts,
    required this.onShowMore,
    super.key,
  });

  final VoidCallback onCreateWarranty;
  final VoidCallback onScan;
  final VoidCallback onShowAllWarranties;
  final VoidCallback onShowProducts;
  final VoidCallback onShowMore;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final subscription = controller.subscription!;
    final warranties = controller.warranties;
    final activeCount = warranties
        .where((item) => item.statusAt() == WarrantyStatus.active)
        .length;
    final openRequests = controller.requests
        .where((item) => item.status != MaintenanceStatus.completed)
        .length;

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: PageFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _MobileHeader(),
            if (controller.isDemo) const _DemoRibbon(),
            const MessageBanner(),
            _StoreHeader(
              storeName: controller.store!.name,
              role: controller.membership!.role.label,
              planName: subscription.plan.name,
            ),
            const SizedBox(height: 16),
            _ScanHero(onScan: onScan, onManual: onCreateWarranty),
            const SizedBox(height: 14),
            _UsageLedger(
              used: subscription.usedWarranties,
              limit: subscription.plan.monthlyWarranties,
              trialDays: subscription.remainingTrialDays,
              isTrial: subscription.status == 'trialing',
              onOpenSubscription: onShowMore,
            ),
            const SizedBox(height: 24),
            Text('وردية اليوم', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 11),
            LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth >= 620
                    ? (constraints.maxWidth - 24) / 3
                    : (constraints.maxWidth - 10) / 2;
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Metric(
                      width: itemWidth,
                      label: 'ضمان ساري',
                      value: '$activeCount',
                      icon: Icons.verified_user_outlined,
                      onTap: onShowAllWarranties,
                    ),
                    _Metric(
                      width: itemWidth,
                      label: 'منتج في الكتالوج',
                      value: '${controller.products.length}',
                      icon: Icons.inventory_2_outlined,
                      onTap: onShowProducts,
                    ),
                    _Metric(
                      width: itemWidth,
                      label: 'طلب صيانة مفتوح',
                      value: '$openRequests',
                      icon: Icons.build_circle_outlined,
                      onTap: onShowMore,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'آخر الضمانات',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: onShowAllWarranties,
                  child: const Text('عرض السجل'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (warranties.isEmpty)
              _EmptyWarranty(onCreate: onCreateWarranty)
            else
              ...warranties
                  .take(3)
                  .map(
                    (warranty) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: WarrantyCard(
                        warranty: warranty,
                        compact: true,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                WarrantyDetailScreen(warrantyId: warranty.id),
                          ),
                        ),
                      ),
                    ),
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Text(
        'عرض تشغيلي — جرّب كل الوظائف؛ لن تُرسل البيانات إلى خادم.',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({
    required this.storeName,
    required this.role,
    required this.planName,
  });

  final String storeName;
  final String role;
  final String planName;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'مساحة المتجر',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Text(storeName, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Column(
            children: [
              Text(
                role,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.onSurface,
                ),
              ),
              Text(
                'خطة $planName',
                style: TextStyle(fontSize: 11, color: colors.primary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanHero extends StatelessWidget {
  const _ScanHero({required this.onScan, required this.onManual});

  final VoidCallback onScan;
  final VoidCallback onManual;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 74,
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: 34,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'امسح. طابِق. أصدر.',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'يتعرّف ضمانك على المنتج ويجهّز مدة الضمان تلقائياً.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: onScan,
                        icon: const Icon(Icons.center_focus_strong_rounded),
                        label: const Text('فتح الماسح'),
                      ),
                      OutlinedButton(
                        onPressed: onManual,
                        child: const Text('إدخال يدوي'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageLedger extends StatelessWidget {
  const _UsageLedger({
    required this.used,
    required this.limit,
    required this.trialDays,
    required this.isTrial,
    required this.onOpenSubscription,
  });

  final int used;
  final int limit;
  final int trialDays;
  final bool isTrial;
  final VoidCallback onOpenSubscription;

  @override
  Widget build(BuildContext context) {
    final ratio = limit == 0 ? 0.0 : (used / limit).clamp(0.0, 1.0);
    final colors = context.colors;
    return Card(
      child: InkWell(
        onTap: onOpenSubscription,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.receipt_long_outlined, color: colors.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '$used من $limit ضماناً هذا الشهر',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (isTrial)
                    Text(
                      '$trialDays يوم متبقٍ',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                ],
              ),
              const SizedBox(height: 11),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 7,
                  backgroundColor: colors.surfaceContainerHighest,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: colors.primary, size: 22),
                const SizedBox(height: 15),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w700,
                    height: 1,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 2,
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

class _EmptyWarranty extends StatelessWidget {
  const _EmptyWarranty({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: colors.primary, size: 34),
            const SizedBox(width: 13),
            const Expanded(
              child: Text(
                'لا توجد ضمانات بعد. ابدأ بمسح منتج أو إدخاله يدوياً.',
              ),
            ),
            IconButton(
              tooltip: 'إنشاء ضمان',
              onPressed: onCreate,
              icon: const Icon(Icons.add_circle_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
