import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';
import '../widgets/message_banner.dart';
import 'branches_screen.dart';
import 'customers_screen.dart';
import 'point_of_sale_screen.dart';
import 'procurement_screen.dart';
import 'products_screen.dart';
import 'register_screen.dart';
import 'reports_screen.dart';
import 'sales_screen.dart';
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
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 34),
          children: [
            if (MediaQuery.sizeOf(context).width < 820) ...[
              const BrandMark(compact: true),
              const SizedBox(height: 18),
            ],
            const MessageBanner(),
            Text('الإدارة', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: colors.primaryContainer,
                    foregroundColor: colors.onPrimaryContainer,
                    child: Text(
                      account.fullName.trim().isEmpty
                          ? '؟'
                          : account.fullName.trim()[0],
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account.fullName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${controller.membership!.role.label} • ${store.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _HubSection(
              title: 'أدوات المتجر',
              children: [
                _HubTile(
                  icon: Icons.point_of_sale_outlined,
                  title: 'نقطة البيع',
                  subtitle: 'بيع سريع وإيصال داخلي',
                  onTap: () => _open(context, const PointOfSaleScreen()),
                ),
                _HubTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'المنتجات',
                  subtitle: '${controller.products.length} منتج في الكتالوج',
                  onTap: () => _open(context, const ProductsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HubSection(
              title: 'العمل اليومي',
              children: [
                _HubTile(
                  icon: Icons.receipt_long_outlined,
                  title: 'المبيعات والمرتجعات',
                  subtitle: '${controller.sales.length} عملية',
                  onTap: () => _open(context, const SalesScreen()),
                ),
                _HubTile(
                  icon: Icons.people_outline_rounded,
                  title: 'العملاء',
                  subtitle: '${controller.customers.length} عميل',
                  onTap: () => _open(context, const CustomersScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HubSection(
              title: 'إدارة المتجر',
              children: [
                _HubTile(
                  icon: Icons.store_mall_directory_outlined,
                  title: 'الفروع',
                  subtitle: '${controller.branches.length} فرع',
                  onTap: () => _open(context, const BranchesScreen()),
                ),
                _HubTile(
                  icon: Icons.point_of_sale_outlined,
                  title: 'الصندوق والورديات',
                  subtitle: 'فتح وإغلاق وجرد النقد',
                  onTap: () => _open(context, const RegisterScreen()),
                ),
                _HubTile(
                  icon: Icons.local_shipping_outlined,
                  title: 'الموردون والمشتريات',
                  subtitle: '${controller.suppliers.length} مورد',
                  onTap: () => _open(context, const ProcurementScreen()),
                ),
                _HubTile(
                  icon: Icons.analytics_outlined,
                  title: 'التقارير',
                  subtitle: 'المبيعات وطرق الدفع والتصدير',
                  onTap: () => _open(context, const ReportsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HubSection(
              title: 'الحساب',
              children: [
                _HubTile(
                  icon: Icons.groups_2_outlined,
                  title: 'الفريق والصلاحيات',
                  subtitle: '${controller.team.length} أعضاء',
                  onTap: () => _open(context, const TeamScreen()),
                ),
                _HubTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'الاشتراك',
                  subtitle: 'خطة ${controller.subscription!.plan.name}',
                  onTap: () => _open(context, const SubscriptionScreen()),
                ),
                _HubTile(
                  icon: Icons.storefront_outlined,
                  title: 'بيانات المتجر',
                  subtitle: '${store.city} • ${store.phone}',
                  onTap: () => _open(context, const SettingsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: controller.busy ? null : controller.signOut,
              style: OutlinedButton.styleFrom(foregroundColor: colors.error),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                controller.isDemo ? 'إغلاق العرض التشغيلي' : 'تسجيل الخروج',
              ),
            ),
            if (!controller.isDemo) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: controller.busy
                    ? null
                    : () => _confirmDelete(context),
                style: TextButton.styleFrom(foregroundColor: colors.error),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const Text('حذف الحساب نهائياً'),
              ),
            ],
            const SizedBox(height: 14),
            Center(
              child: Text(
                'ضمانك للأعمال 4.3.1',
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

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف الحساب نهائياً؟'),
        content: const Text(
          'إذا كنت المالك الوحيد فسيُحذف المتجر وبياناته. وإذا وُجد عضو آخر فستُنقل الملكية إليه قبل حذف حسابك. لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('حذف نهائي'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await AppScope.of(context).deleteAccount();
    }
  }
}

class _HubSection extends StatelessWidget {
  const _HubSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      ),
      Card(
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1)
                const Divider(height: 1, indent: 62),
            ],
          ],
        ),
      ),
    ],
  );
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
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    minTileHeight: 64,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    leading: Icon(icon, color: context.colors.primary),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
  );
}
