import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/account.dart';
import '../state/app_scope.dart';
import '../widgets/brand_mark.dart';
import '../widgets/message_banner.dart';
import 'requests_screen.dart';
import 'branches_screen.dart';
import 'customers_screen.dart';
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
              icon: Icons.receipt_long_outlined,
              title: 'المبيعات والمرتجعات',
              subtitle: '${controller.sales.length} فواتير • مرتجعات موثقة',
              onTap: () => _open(context, const SalesScreen()),
            ),
            _HubTile(
              icon: Icons.inventory_2_outlined,
              title: 'كتالوج المنتجات',
              subtitle:
                  '${controller.products.length} منتجات • أسعار وتكلفة وتسلسل',
              onTap: () => _open(context, const ProductsScreen()),
            ),
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
              icon: Icons.point_of_sale_outlined,
              title: 'جلسات الصندوق',
              subtitle:
                  '${controller.registerSessions.length} ورديات • جرد وفروقات',
              onTap: () => _open(context, const RegisterScreen()),
            ),
            _HubTile(
              icon: Icons.local_shipping_outlined,
              title: 'الموردون والمشتريات',
              subtitle:
                  '${controller.suppliers.length} موردين • ${controller.purchaseOrders.length} أوامر شراء',
              onTap: () => _open(context, const ProcurementScreen()),
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
                'ضمانك للأعمال 4.0.0',
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
