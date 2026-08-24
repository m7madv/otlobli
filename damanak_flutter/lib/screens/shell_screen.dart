import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/brand_mark.dart';
import 'account_screen.dart';
import 'home_screen.dart';
import 'products_screen.dart';
import 'scanner_screen.dart';
import 'warranties_screen.dart';
import 'warranty_form_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.space_dashboard_outlined),
      selectedIcon: Icon(Icons.space_dashboard_rounded),
      label: 'العمليات',
    ),
    NavigationDestination(
      icon: Icon(Icons.qr_code_scanner_rounded),
      selectedIcon: Icon(Icons.qr_code_scanner_rounded),
      label: 'مسح',
    ),
    NavigationDestination(
      icon: Icon(Icons.verified_user_outlined),
      selectedIcon: Icon(Icons.verified_user_rounded),
      label: 'الضمانات',
    ),
    NavigationDestination(
      icon: Icon(Icons.inventory_2_outlined),
      selectedIcon: Icon(Icons.inventory_2_rounded),
      label: 'المنتجات',
    ),
    NavigationDestination(
      icon: Icon(Icons.grid_view_outlined),
      selectedIcon: Icon(Icons.grid_view_rounded),
      label: 'المزيد',
    ),
  ];

  Future<void> _openNewWarranty() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const WarrantyFormScreen()));
  }

  Widget _currentPage() => switch (_index) {
    0 => HomeScreen(
      onCreateWarranty: _openNewWarranty,
      onScan: () => setState(() => _index = 1),
      onShowAllWarranties: () => setState(() => _index = 2),
      onShowProducts: () => setState(() => _index = 3),
      onShowMore: () => setState(() => _index = 4),
    ),
    1 => const ScannerScreen(),
    2 => const WarrantiesScreen(),
    3 => const ProductsScreen(),
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
                                onPressed: _openNewWarranty,
                                icon: const Icon(Icons.add_rounded),
                                label: const Text('ضمان جديد'),
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
