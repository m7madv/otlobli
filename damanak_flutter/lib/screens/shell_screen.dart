import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../widgets/brand_mark.dart';
import 'home_screen.dart';
import 'requests_screen.dart';
import 'settings_screen.dart';
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
      icon: Icon(Icons.build_outlined),
      selectedIcon: Icon(Icons.build_rounded),
      label: 'الصيانة',
    ),
    NavigationDestination(
      icon: Icon(Icons.storefront_outlined),
      selectedIcon: Icon(Icons.storefront_rounded),
      label: 'المتجر',
    ),
  ];

  Future<void> _openNewWarranty() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const WarrantyFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onCreateWarranty: _openNewWarranty,
        onShowAllWarranties: () => setState(() => _index = 1),
        onShowRequests: () => setState(() => _index = 2),
      ),
      const WarrantiesScreen(),
      const RequestsScreen(),
      const SettingsScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 760;
        final content = IndexedStack(index: _index, children: pages);

        if (useRail) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  Container(
                    width: 210,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: AppColors.line)),
                    ),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(18, 24, 18, 20),
                          child: BrandMark(compact: true),
                        ),
                        Expanded(
                          child: NavigationRail(
                            extended: true,
                            backgroundColor: Colors.white,
                            selectedIndex: _index,
                            onDestinationSelected: (value) {
                              setState(() => _index = value);
                            },
                            leading: Padding(
                              padding: const EdgeInsets.only(bottom: 18),
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
          floatingActionButton: _index == 1
              ? FloatingActionButton.extended(
                  onPressed: _openNewWarranty,
                  backgroundColor: AppColors.emerald,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'ضمان جديد',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                )
              : null,
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
