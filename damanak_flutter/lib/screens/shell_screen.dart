import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/brand_mark.dart';
import 'account_screen.dart';
import 'home_screen.dart';
import 'requests_screen.dart';
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
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home_rounded),
      label: 'الرئيسية',
    ),
    NavigationDestination(
      icon: Icon(Icons.verified_user_outlined),
      selectedIcon: Icon(Icons.verified_user_rounded),
      label: 'الضمانات',
    ),
    NavigationDestination(
      icon: Icon(Icons.fact_check_outlined),
      selectedIcon: Icon(Icons.fact_check_rounded),
      label: 'المطالبات',
    ),
    NavigationDestination(
      icon: Icon(Icons.admin_panel_settings_outlined),
      selectedIcon: Icon(Icons.admin_panel_settings_rounded),
      label: 'الإدارة',
    ),
  ];

  Widget _currentPage() => switch (_index) {
    0 => HomeScreen(
      onCreateWarranty: _openWarrantyForm,
      onScan: _openScanner,
      onShowAllWarranties: () => _selectDestination(1),
      onShowRequests: () => _selectDestination(2),
      onShowAdmin: () => _selectDestination(3),
    ),
    1 => WarrantiesScreen(onCreateWarranty: _openWarrantyForm),
    2 => const RequestsScreen(),
    _ => const AccountScreen(),
  };

  void _selectDestination(int value) {
    if (_index == value) return;
    setState(() => _index = value);
  }

  void _openWarrantyForm() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const WarrantyFormScreen()));
  }

  void _openScanner() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ScannerScreen()));
  }

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
                            onDestinationSelected: _selectDestination,
                            leading: Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: FilledButton.icon(
                                onPressed: _openWarrantyForm,
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                ),
                                label: const Text('إصدار ضمان'),
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
            onDestinationSelected: _selectDestination,
            destinations: _destinations,
          ),
        );
      },
    );
  }
}
