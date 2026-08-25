import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/brand_mark.dart';
import 'account_screen.dart';
import 'point_of_sale_screen.dart';
import 'products_screen.dart';
import 'warranties_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.point_of_sale_outlined),
      selectedIcon: Icon(Icons.point_of_sale_rounded),
      label: 'البيع',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2_rounded),
      label: 'المنتجات',
    ),
    NavigationDestination(
      icon: Icon(Icons.verified_user_outlined),
      selectedIcon: Icon(Icons.verified_user_rounded),
      label: 'الضمانات',
    ),
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'المزيد',
    ),
  ];

  Widget _currentPage() => switch (_index) {
    0 => const PointOfSaleScreen(),
    1 => const ProductsScreen(),
    2 => const WarrantiesScreen(),
    _ => const AccountScreen(),
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 820;
        final content = _currentPage();
        final colors = context.colors;
        if (useRail) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  Container(
                    width: 224,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      border: Border(
                        left: BorderSide(color: colors.outlineVariant),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(18, 24, 18, 18),
                          child: BrandMark(compact: true),
                        ),
                        Expanded(
                          child: NavigationRail(
                            extended: true,
                            selectedIndex: _index,
                            onDestinationSelected: (value) =>
                                setState(() => _index = value),
                            leading: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: FilledButton.icon(
                                onPressed: () => setState(() => _index = 0),
                                icon: const Icon(Icons.point_of_sale_rounded),
                                label: const Text('بيع جديد'),
                              ),
                            ),
                            labelType: NavigationRailLabelType.none,
                            destinations: _destinations
                                .map(
                                  (item) => NavigationRailDestination(
                                    icon: item.icon,
                                    selectedIcon: item.selectedIcon,
                                    label: Text(item.label),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: content),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          body: SafeArea(child: content),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (value) => setState(() => _index = value),
            destinations: _destinations,
          ),
        );
      },
    );
  }
}
