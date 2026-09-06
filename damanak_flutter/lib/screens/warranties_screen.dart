import 'package:damanak/l10n/l10n.dart';
import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/warranty_card.dart';
import 'warranty_detail_screen.dart';

class WarrantiesScreen extends StatefulWidget {
  const WarrantiesScreen({required this.onCreateWarranty, super.key});

  final VoidCallback onCreateWarranty;

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
    L10n.watch(context);
    final controller = AppScope.of(context);
    final colors = context.colors;
    final allWarranties = controller.warranties;
    final warranties = allWarranties.where((item) {
      return item.matches(_searchController.text) &&
          (_filter == null || item.statusAt() == _filter);
    }).toList();

    int countFor(WarrantyStatus status) =>
        allWarranties.where((item) => item.statusAt() == status).length;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: RefreshIndicator(
          onRefresh: controller.refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ScreenHeader(onCreate: widget.onCreateWarranty),
                      const SizedBox(height: 18),
                      TextField(
                        key: const ValueKey('warranty-search-field'),
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: L10n.current.msg1812652ef981,
                          hintText: L10n.current.msg330614ae4275,
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: L10n.current.msg2e58b72edf70,
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
                              label: L10n.current.msgbcda95d71da1(
                                allWarranties.length,
                              ),
                              selected: _filter == null,
                              onSelected: () => setState(() => _filter = null),
                            ),
                            ...WarrantyStatus.values.map(
                              (status) => Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 8,
                                ),
                                child: _FilterChip(
                                  label:
                                      '${_shortStatusLabel(status)} ${countFor(status)}',
                                  selected: _filter == status,
                                  onSelected: () =>
                                      setState(() => _filter = status),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 13),
                      Text(
                        warranties.length == allWarranties.length
                            ? L10n.current.msgc79378f26f35(warranties.length)
                            : L10n.current.msg3a30dd12ec9a(
                                warranties.length,
                                allWarranties.length,
                              ),
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              if (warranties.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyWarranties(
                      hasFilters:
                          _searchController.text.isNotEmpty || _filter != null,
                      onCreate: widget.onCreateWarranty,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  sliver: SliverList.builder(
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
                ),
              if (allWarranties.isNotEmpty || controller.hasMoreWarranties)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 7, 18, 0),
                  sliver: SliverToBoxAdapter(
                    child: _WarrantyPaginationFooter(
                      loadedCount: allWarranties.length,
                      hasMore: controller.hasMoreWarranties,
                      loading: controller.loadingMoreWarranties,
                      onLoadMore: controller.loadMoreWarranties,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  String _shortStatusLabel(WarrantyStatus status) => switch (status) {
    WarrantyStatus.active => L10n.current.msge7e4a3bf3fb7,
    WarrantyStatus.expiringSoon => L10n.current.msg027ea1355212,
    WarrantyStatus.expired => L10n.current.msg6217883aee8e,
  };
}

class _WarrantyPaginationFooter extends StatelessWidget {
  const _WarrantyPaginationFooter({
    required this.loadedCount,
    required this.hasMore,
    required this.loading,
    required this.onLoadMore,
  });

  final int loadedCount;
  final bool hasMore;
  final bool loading;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final colors = context.colors;
    return Column(
      children: [
        Text(
          hasMore
              ? L10n.current.msg05851e111cba(loadedCount)
              : L10n.current.msg403694008d29(loadedCount),
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
        if (hasMore) ...[
          const SizedBox(height: 10),
          OutlinedButton.icon(
            key: const ValueKey('warranties-load-more-button'),
            onPressed: loading ? null : onLoadMore,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            icon: loading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.expand_more_rounded),
            label: Text(
              loading
                  ? L10n.current.msgf769bd53e821
                  : L10n.current.msgdbcc30d597f2,
            ),
          ),
        ],
      ],
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final colors = context.colors;
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.current.msgc47227163f19,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 5),
        Text(
          L10n.current.msg48be88443098,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
    final action = FilledButton.icon(
      key: const ValueKey('warranties-create-button'),
      onPressed: onCreate,
      icon: const Icon(Icons.add_rounded),
      label: Text(L10n.current.msg92cb3a8b07d2),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [heading, const SizedBox(height: 14), action],
          );
        }
        return Row(
          children: [
            Expanded(child: heading),
            const SizedBox(width: 18),
            action,
          ],
        );
      },
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
    L10n.watch(context);
    final colors = context.colors;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: selected,
      selectedColor: colors.primaryContainer,
      backgroundColor: colors.surface,
      labelStyle: TextStyle(
        color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? colors.primary : colors.outlineVariant,
      ),
    );
  }
}

class _EmptyWarranties extends StatelessWidget {
  const _EmptyWarranties({required this.hasFilters, required this.onCreate});

  final bool hasFilters;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    L10n.watch(context);
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
        child: Center(
          child: Column(
            children: [
              Icon(
                hasFilters
                    ? Icons.search_off_rounded
                    : Icons.verified_user_outlined,
                size: 44,
                color: colors.onSurfaceVariant,
              ),
              const SizedBox(height: 12),
              Text(
                hasFilters
                    ? L10n.current.msgee6d68a794bb
                    : L10n.current.msgabb7c836381f,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 5),
              Text(
                hasFilters
                    ? L10n.current.msg0235e42eca52
                    : L10n.current.msg94bea9dd8ac6,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              if (!hasFilters) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded),
                  label: Text(L10n.current.msg92cb3a8b07d2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
