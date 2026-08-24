import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/warranty_card.dart';
import 'warranty_detail_screen.dart';

class WarrantiesScreen extends StatefulWidget {
  const WarrantiesScreen({super.key});

  @override
  State<WarrantiesScreen> createState() => _WarrantiesScreenState();
}

class _WarrantiesScreenState extends State<WarrantiesScreen> {
  final _searchController = TextEditingController();
  WarrantyStatus? _filter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allWarranties = AppScope.of(context).warranties;
    final warranties = allWarranties.where((item) {
      return item.matches(_searchController.text) &&
          (_filter == null || item.statusAt() == _filter);
    }).toList();

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'سجل الضمانات',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${allWarranties.length} بطاقة محفوظة على هذا الجهاز',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: 'ابحث باسم العميل أو المنتج أو الرقم',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'مسح البحث',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {});
                                },
                                icon: const Icon(Icons.close_rounded),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'الكل',
                            selected: _filter == null,
                            onSelected: () => setState(() => _filter = null),
                          ),
                          ...WarrantyStatus.values.map(
                            (status) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _FilterChip(
                                label: status.label,
                                selected: _filter == status,
                                onSelected: () =>
                                    setState(() => _filter = status),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
              if (warranties.isEmpty)
                SliverToBoxAdapter(
                  child: _EmptyWarranties(
                    hasFilters:
                        _searchController.text.isNotEmpty || _filter != null,
                  ),
                )
              else
                SliverList.builder(
                  itemCount: warranties.length,
                  itemBuilder: (context, index) {
                    final warranty = warranties[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: WarrantyCard(
                        warranty: warranty,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                WarrantyDetailScreen(warrantyId: warranty.id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.ink,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.muted,
        fontWeight: FontWeight.w700,
      ),
      side: BorderSide(color: selected ? AppColors.ink : AppColors.line),
    );
  }
}

class _EmptyWarranties extends StatelessWidget {
  const _EmptyWarranties({required this.hasFilters});

  final bool hasFilters;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
        child: Center(
          child: Column(
            children: [
              const Icon(
                Icons.folder_off_outlined,
                size: 44,
                color: AppColors.muted,
              ),
              const SizedBox(height: 12),
              Text(
                hasFilters ? 'لا توجد نتائج مطابقة' : 'لا توجد ضمانات بعد',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                hasFilters
                    ? 'جرّب كلمة بحث أخرى أو غيّر حالة الضمان.'
                    : 'أنشئ أول ضمان من زر «ضمان جديد».',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
