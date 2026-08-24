import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';
import '../widgets/message_banner.dart';
import 'requests_screen.dart';
import 'branches_screen.dart';
import 'customers_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';
import 'team_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final account = controller.account!;
    final store = controller.store!;
    final colors = context.colors;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 880),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 34),
          children: [
            if (MediaQuery.sizeOf(context).width < 820) ...[
              const BrandMark(compact: true),
              const SizedBox(height: 20),
            ],
            const MessageBanner(),
            Text(
              'الإدارة والحساب',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: Text(
                      account.fullName.trim().isEmpty
                          ? '؟'
                          : account.fullName.trim()[0],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.fullName,
                          style: TextStyle(
                            color: colors.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          account.email,
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${controller.membership!.role.label} • ${store.name}',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text('إدارة المتجر', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            _HubTile(
              icon: Icons.people_outline_rounded,
              title: 'دليل العملاء',
              subtitle:
                  '${controller.customers.length} عميلاً • بيانات موحدة لكل الضمانات',
              onTap: () => _open(context, const CustomersScreen()),
            ),
            _HubTile(
              icon: Icons.store_mall_directory_outlined,
              title: 'الفروع ونقاط البيع',
              subtitle:
                  '${controller.branches.length} فروع • ربط المبيعات بالفرع',
              onTap: () => _open(context, const BranchesScreen()),
            ),
            _HubTile(
              icon: Icons.analytics_outlined,
              title: 'التقارير والتصدير',
              subtitle: 'المبيعات والضريبة وطرق الدفع وتصدير CSV',
              onTap: () => _open(context, const ReportsScreen()),
            ),
            _HubTile(
              icon: Icons.groups_2_outlined,
              title: 'الفريق والصلاحيات',
              subtitle:
                  '${controller.team.length} أعضاء • دعوات وحسابات مستقلة',
              onTap: () => _open(context, const TeamScreen()),
            ),
            _HubTile(
              icon: Icons.workspace_premium_outlined,
              title: 'الاشتراك والاستخدام',
              subtitle:
                  'خطة ${controller.subscription!.plan.name} • ${controller.subscription!.remainingWarranties} ضماناً متبقياً',
              onTap: () => _open(context, const SubscriptionScreen()),
            ),
            _HubTile(
              icon: Icons.build_circle_outlined,
              title: 'طلبات الصيانة',
              subtitle: '${controller.requests.length} طلباً في السجل',
              onTap: () => _open(context, const RequestsScreen()),
            ),
            _HubTile(
              icon: Icons.storefront_outlined,
              title: 'بيانات المتجر',
              subtitle: '${store.city} • ${store.phone}',
              onTap: () => _open(context, const SettingsScreen()),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: controller.busy ? null : controller.signOut,
              style: OutlinedButton.styleFrom(foregroundColor: colors.error),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                controller.isDemo ? 'إغلاق العرض التشغيلي' : 'تسجيل الخروج',
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'ضمانك للأعمال 3.0.0',
                style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 7,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colors.primary),
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 15),
        ),
      ),
    );
  }
}
