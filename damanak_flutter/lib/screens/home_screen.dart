import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/maintenance_request.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';
import '../widgets/page_frame.dart';
import '../widgets/warranty_card.dart';
import 'warranty_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onCreateWarranty,
    required this.onShowAllWarranties,
    required this.onShowRequests,
    super.key,
  });

  final VoidCallback onCreateWarranty;
  final VoidCallback onShowAllWarranties;
  final VoidCallback onShowRequests;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final warranties = controller.warranties;
    final activeCount = warranties
        .where((item) => item.statusAt() == WarrantyStatus.active)
        .length;
    final expiringCount = warranties
        .where((item) => item.statusAt() == WarrantyStatus.expiringSoon)
        .length;
    final openRequests = controller.requests
        .where((item) => item.status != MaintenanceStatus.completed)
        .length;
    final recentWarranties = warranties.take(3).toList();

    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MobileHeader(),
          const SizedBox(height: 22),
          _WelcomePanel(
            storeName: controller.profile.name,
            onCreateWarranty: onCreateWarranty,
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = constraints.maxWidth >= 680
                  ? (constraints.maxWidth - 24) / 3
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    width: itemWidth,
                    label: 'ضمان ساري',
                    value: '$activeCount',
                    icon: Icons.verified_user_rounded,
                    color: AppColors.emerald,
                  ),
                  _StatCard(
                    width: itemWidth,
                    label: 'ينتهي قريباً',
                    value: '$expiringCount',
                    icon: Icons.schedule_rounded,
                    color: AppColors.gold,
                  ),
                  _StatCard(
                    width: itemWidth,
                    label: 'طلبات مفتوحة',
                    value: '$openRequests',
                    icon: Icons.build_circle_outlined,
                    color: const Color(0xFF47759E),
                    onTap: onShowRequests,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 28),
          _SectionHeader(
            title: 'أحدث الضمانات',
            actionLabel: warranties.isEmpty ? null : 'عرض الكل',
            onAction: warranties.isEmpty ? null : onShowAllWarranties,
          ),
          const SizedBox(height: 12),
          if (recentWarranties.isEmpty)
            _EmptyStart(onCreateWarranty: onCreateWarranty)
          else
            ...recentWarranties.map(
              (warranty) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: WarrantyCard(
                  warranty: warranty,
                  compact: true,
                  onTap: () => _openWarranty(context, warranty.id),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openWarranty(BuildContext context, String id) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => WarrantyDetailScreen(warrantyId: id),
      ),
    );
  }
}

class _MobileHeader extends StatelessWidget {
  const _MobileHeader();

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width >= 760) {
      return const SizedBox.shrink();
    }
    return const BrandMark(compact: true);
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({
    required this.storeName,
    required this.onCreateWarranty,
  });

  final String storeName;
  final VoidCallback onCreateWarranty;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -26,
            top: -42,
            child: Container(
              width: 126,
              height: 126,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 18,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                storeName,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'حوّل الفاتورة إلى\nضمان واضح وموثّق.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 25,
                  height: 1.25,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 9),
              Text(
                'أنشئ البطاقة وشاركها مع العميل خلال دقيقة.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onCreateWarranty,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.ink,
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('إنشاء ضمان جديد'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: AppColors.ink,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        label,
                        maxLines: 2,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _EmptyStart extends StatelessWidget {
  const _EmptyStart({required this.onCreateWarranty});

  final VoidCallback onCreateWarranty;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.emerald,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ابدأ بأول بطاقة ضمان',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'أدخل بيانات العميل والمنتج، وسيحفظها التطبيق على هذا الجهاز.',
                    style: TextStyle(color: AppColors.muted),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: onCreateWarranty,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('إنشاء البطاقة'),
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
