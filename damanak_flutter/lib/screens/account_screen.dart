import 'package:damanak/l10n/l10n.dart';
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
import 'notifications_screen.dart';
import 'integrations_screen.dart';
import 'subscription_screen.dart';
import 'team_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
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
            const Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Material(
                color: Colors.transparent,
                child: LanguagePicker(),
              ),
            ),
            Text(
              L10n.current.msga3b53d11ac20,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
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
                          ? L10n.current.msg7d06b69aad65
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
              title: L10n.current.msgaf4d9ff5b4d2,
              children: [
                _HubTile(
                  icon: Icons.inventory_2_outlined,
                  title: L10n.current.msgc8775206b252,
                  subtitle: L10n.current.msg8be6cfd47c1b(
                    controller.products.length,
                  ),
                  onTap: () => _open(context, const ProductsScreen()),
                ),
                _HubTile(
                  icon: Icons.people_outline_rounded,
                  title: L10n.current.msg813d9a8a1065,
                  subtitle: L10n.current.msg4bd610b4702a(
                    controller.customers.length,
                  ),
                  onTap: () => _open(context, const CustomersScreen()),
                ),
                _HubTile(
                  icon: Icons.analytics_outlined,
                  title: L10n.current.msg038317a4bdae,
                  subtitle: L10n.current.msgd742d0ba9eb1,
                  onTap: () => _open(context, const ReportsScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HubSection(
              title: L10n.current.msgb332e76753b0,
              children: [
                _HubTile(
                  icon: Icons.store_mall_directory_outlined,
                  title: L10n.current.msg717d385ed755,
                  subtitle: L10n.current.msg44c9bd4c003e(
                    controller.branches.length,
                  ),
                  onTap: () => _open(context, const BranchesScreen()),
                ),
                _HubTile(
                  icon: Icons.groups_2_outlined,
                  title: L10n.current.msgfae07b10b96b,
                  subtitle: L10n.current.msg8b885d3f2a38(
                    controller.team.length,
                  ),
                  onTap: () => _open(context, const TeamScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HubSection(
              title: L10n.current.msg73a2f189121f,
              children: [
                _HubTile(
                  icon: Icons.point_of_sale_outlined,
                  title: L10n.current.msg019fbfd1d736,
                  subtitle: L10n.current.msgf9e6b8346033,
                  onTap: () => _open(context, const PointOfSaleScreen()),
                ),
                _HubTile(
                  icon: Icons.receipt_long_outlined,
                  title: L10n.current.msgc3fdd6caa7c1,
                  subtitle: L10n.current.msgb2a0b8ca5be1(
                    controller.sales.length,
                  ),
                  onTap: () => _open(context, const SalesScreen()),
                ),
                _HubTile(
                  icon: Icons.point_of_sale_outlined,
                  title: L10n.current.msg76218d4ae22b,
                  subtitle: L10n.current.msg6b5d92b9084b,
                  onTap: () => _open(context, const RegisterScreen()),
                ),
                _HubTile(
                  icon: Icons.local_shipping_outlined,
                  title: L10n.current.msgb303479250b4,
                  subtitle: L10n.current.msg53b2c0902636(
                    controller.suppliers.length,
                  ),
                  onTap: () => _open(context, const ProcurementScreen()),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _HubSection(
              title: L10n.current.msg66dcee1f4616,
              children: [
                _HubTile(
                  icon: Icons.notifications_none_rounded,
                  title: L10n.current.msg8ce3e0cc0601,
                  subtitle: controller.unreadNotificationCount == 0
                      ? L10n.current.msg04cc60c136b6
                      : L10n.current.msgbfbe54647329(
                          controller.unreadNotificationCount,
                        ),
                  onTap: () => _open(context, const NotificationsScreen()),
                ),
                _HubTile(
                  icon: Icons.storefront_outlined,
                  title: L10n.current.msg97432797c672,
                  subtitle: '${store.city} • ${store.phone}',
                  onTap: () => _open(context, const SettingsScreen()),
                ),
                _HubTile(
                  icon: Icons.workspace_premium_outlined,
                  title: L10n.current.msg103acd5c93ee,
                  subtitle: L10n.current.msgb83c63d8ca1b(
                    controller.subscription!.plan.displayName,
                  ),
                  onTap: () => _open(context, const SubscriptionScreen()),
                ),
                if (controller.membership!.role.canManageSubscription)
                  _HubTile(
                    icon: Icons.hub_outlined,
                    title: L10n.current.msgc82e99cb1b8b,
                    subtitle: controller.subscription!.plan.apiAccess
                        ? L10n.current.msgc255231e3d75
                        : L10n.current.msgd28cd531b9d1,
                    onTap: () => _open(context, const IntegrationsScreen()),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: controller.busy ? null : controller.signOut,
              style: OutlinedButton.styleFrom(foregroundColor: colors.error),
              icon: const Icon(Icons.logout_rounded),
              label: Text(
                controller.isDemo
                    ? L10n.current.msge2bd051450c6
                    : L10n.current.msg21f474427638,
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
                label: Text(L10n.current.msg0e37703ffce0),
              ),
            ],
            const SizedBox(height: 14),
            Center(
              child: Text(
                L10n.current.msge9a85ff0e478,
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
    final controller = AppScope.of(context);
    final hasStoreSubscription = controller.subscription?.source == 'store';
    final billingStore = switch (controller.subscription?.billingProvider) {
      'app_store' => 'App Store',
      'google_play' => 'Google Play',
      _ => L10n.current.msg91e7da5d592b,
    };
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        scrollable: true,
        title: Text(L10n.current.msg938d8775ee84),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(L10n.current.msg932dd1b45205),
            if (hasStoreSubscription) ...[
              const SizedBox(height: 12),
              Text(
                L10n.current.msgc40bf1a4b038(billingStore),
                style: TextStyle(
                  color: Theme.of(dialogContext).colorScheme.error,
                  fontWeight: FontWeight.w700,
                  height: 1.5,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(L10n.current.msg9a30dc2a96b8),
          ),
          if (hasStoreSubscription)
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext, false);
                await controller.openStoreSubscriptionManagement();
              },
              child: Text(L10n.current.msg432651e0ceb3),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(L10n.current.msgcd6f896cc0ee),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await controller.deleteAccount();
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
