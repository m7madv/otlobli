import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/maintenance_request.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/status_chip.dart';
import 'claim_detail_screen.dart';

enum _ClaimFilter { open, needsAction, overdue, closed, all }

enum _ClaimScope { team, mine, unassigned }

class RequestsScreen extends StatefulWidget {
  const RequestsScreen({super.key});

  @override
  State<RequestsScreen> createState() => _RequestsScreenState();
}

class _RequestsScreenState extends State<RequestsScreen> {
  final _searchController = TextEditingController();
  _ClaimFilter _filter = _ClaimFilter.open;
  _ClaimScope _scope = _ClaimScope.team;
  bool _initializedScope = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initializedScope) return;
    _initializedScope = true;
    if (AppScope.of(context).membership?.role.name == 'staff') {
      _scope = _ClaimScope.mine;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final requests = controller.requests;
    final visible = requests.where((request) {
      final warranty = controller.warrantyById(request.warrantyId);
      if (warranty == null ||
          !_matchesScope(request, controller.account?.id) ||
          !_matchesFilter(request)) {
        return false;
      }
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      return request.displayNumber.toLowerCase().contains(query) ||
          request.issue.toLowerCase().contains(query) ||
          warranty.productName.toLowerCase().contains(query) ||
          warranty.customerName.toLowerCase().contains(query) ||
          warranty.serialNumber.toLowerCase().contains(query);
    }).toList();

    final open = requests.where((item) => !item.status.isClosed).length;
    final needsAction = requests.where(_needsAction).length;
    final overdue = requests.where((item) => item.isOverdue).length;
    final closed = requests.where((item) => item.status.isClosed).length;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 22, 18, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'مركز المطالبات',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'راجع الطلب، عيّن المسؤول، واتخذ القرار حتى تسليم المنتج.',
                      style: TextStyle(
                        color: context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _SummaryGrid(
                      open: open,
                      needsAction: needsAction,
                      overdue: overdue,
                      closed: closed,
                      selected: _filter,
                      onSelected: (value) => setState(() => _filter = value),
                    ),
                    const SizedBox(height: 14),
                    _ScopeSelector(
                      value: _scope,
                      onChanged: (value) => setState(() => _scope = value),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        labelText: 'ابحث في المطالبات',
                        hintText:
                            'رقم المطالبة، المنتج، العميل أو الرقم التسلسلي',
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${visible.length} مطالبة',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (requests.isNotEmpty && _filter != _ClaimFilter.all)
                          TextButton(
                            onPressed: () =>
                                setState(() => _filter = _ClaimFilter.all),
                            child: const Text('عرض الكل'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
            if (requests.isEmpty)
              const SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(child: _EmptyRequests()),
              )
            else if (visible.isEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverToBoxAdapter(
                  child: _NoResults(
                    onReset: () {
                      _searchController.clear();
                      setState(() {
                        _filter = _ClaimFilter.all;
                        _scope = _ClaimScope.team;
                      });
                    },
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                sliver: SliverList.builder(
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final request = visible[index];
                    final warranty = controller.warrantyById(
                      request.warrantyId,
                    )!;
                    final assignee = controller.teamMemberById(
                      request.assignedTo,
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _RequestCard(
                        request: request,
                        warranty: warranty,
                        assigneeName: assignee?.fullName,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ClaimDetailScreen(requestId: request.id),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }

  bool _matchesFilter(MaintenanceRequest request) => switch (_filter) {
    _ClaimFilter.open => !request.status.isClosed,
    _ClaimFilter.needsAction => _needsAction(request),
    _ClaimFilter.overdue => request.isOverdue,
    _ClaimFilter.closed => request.status.isClosed,
    _ClaimFilter.all => true,
  };

  bool _matchesScope(MaintenanceRequest request, String? userId) =>
      switch (_scope) {
        _ClaimScope.team => true,
        _ClaimScope.mine => userId != null && request.assignedTo == userId,
        _ClaimScope.unassigned => request.assignedTo == null,
      };

  bool _needsAction(MaintenanceRequest request) =>
      request.status == MaintenanceStatus.newRequest ||
      request.status == MaintenanceStatus.needsReview ||
      request.status == MaintenanceStatus.readyForPickup;
}

class _ScopeSelector extends StatelessWidget {
  const _ScopeSelector({required this.value, required this.onChanged});

  final _ClaimScope value;
  final ValueChanged<_ClaimScope> onChanged;

  static const _segments = [
    ButtonSegment(
      value: _ClaimScope.team,
      icon: Icon(Icons.groups_outlined),
      label: Text('كل الفريق'),
    ),
    ButtonSegment(
      value: _ClaimScope.mine,
      icon: Icon(Icons.person_outline_rounded),
      label: Text('عملي'),
    ),
    ButtonSegment(
      value: _ClaimScope.unassigned,
      icon: Icon(Icons.person_off_outlined),
      label: Text('غير معيّن'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520 || textScaler.scale(14) > 19) {
          return DropdownButtonFormField<_ClaimScope>(
            key: ValueKey(value),
            initialValue: value,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'نطاق العمل',
              prefixIcon: Icon(Icons.filter_alt_outlined),
            ),
            items: _ClaimScope.values
                .map(
                  (scope) =>
                      DropdownMenuItem(value: scope, child: Text(scope.label)),
                )
                .toList(),
            onChanged: (scope) {
              if (scope != null) onChanged(scope);
            },
          );
        }
        return SegmentedButton<_ClaimScope>(
          showSelectedIcon: false,
          segments: _segments,
          selected: {value},
          onSelectionChanged: (selection) => onChanged(selection.first),
        );
      },
    );
  }
}

extension on _ClaimScope {
  String get label => switch (this) {
    _ClaimScope.team => 'كل الفريق',
    _ClaimScope.mine => 'عملي',
    _ClaimScope.unassigned => 'غير معيّن',
  };
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.open,
    required this.needsAction,
    required this.overdue,
    required this.closed,
    required this.selected,
    required this.onSelected,
  });

  final int open;
  final int needsAction;
  final int overdue;
  final int closed;
  final _ClaimFilter selected;
  final ValueChanged<_ClaimFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SummaryCard(
              width: width,
              label: 'مفتوحة',
              value: open,
              icon: Icons.inbox_outlined,
              selected: selected == _ClaimFilter.open,
              onTap: () => onSelected(_ClaimFilter.open),
            ),
            _SummaryCard(
              width: width,
              label: 'تحتاج إجراء',
              value: needsAction,
              icon: Icons.bolt_outlined,
              selected: selected == _ClaimFilter.needsAction,
              onTap: () => onSelected(_ClaimFilter.needsAction),
            ),
            _SummaryCard(
              width: width,
              label: 'متأخرة',
              value: overdue,
              icon: Icons.warning_amber_rounded,
              selected: selected == _ClaimFilter.overdue,
              isWarning: overdue > 0,
              onTap: () => onSelected(_ClaimFilter.overdue),
            ),
            _SummaryCard(
              width: width,
              label: 'مغلقة',
              value: closed,
              icon: Icons.task_alt_rounded,
              selected: selected == _ClaimFilter.closed,
              onTap: () => onSelected(_ClaimFilter.closed),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.isWarning = false,
  });

  final double width;
  final String label;
  final int value;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isWarning ? colors.error : colors.onSurface;
    final background = isWarning
        ? colors.errorContainer
        : selected
        ? colors.primaryContainer
        : colors.surface;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label، $value',
      child: SizedBox(
        width: width,
        child: Material(
          color: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected ? colors.primary : colors.outlineVariant,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Icon(icon, color: isWarning ? colors.error : colors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '$value',
                    style: TextStyle(
                      color: foreground,
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.warranty,
    required this.assigneeName,
    required this.onOpen,
  });

  final MaintenanceRequest request;
  final Warranty warranty;
  final String? assigneeName;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.displayNumber,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.end,
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          warranty.productName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          warranty.customerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MaintenanceStatusChip(status: request.status),
                ],
              ),
              const Divider(height: 24),
              Text(
                request.issue,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _CardMeta(
                    icon: Icons.flag_outlined,
                    label: request.priority.label,
                  ),
                  _CardMeta(
                    icon: Icons.person_outline_rounded,
                    label: assigneeName ?? 'غير معيّن',
                  ),
                  _CardMeta(
                    icon: Icons.calendar_today_outlined,
                    label: formatDate(request.createdAt),
                    ltr: true,
                  ),
                  if (request.isOverdue)
                    _CardMeta(
                      icon: Icons.warning_amber_rounded,
                      label: 'متأخرة',
                      color: colors.error,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardMeta extends StatelessWidget {
  const _CardMeta({
    required this.icon,
    required this.label,
    this.color,
    this.ltr = false,
  });

  final IconData icon;
  final String label;
  final Color? color;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? context.colors.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: foreground),
        const SizedBox(width: 5),
        Text(
          label,
          textDirection: ltr ? TextDirection.ltr : null,
          style: TextStyle(color: foreground, fontSize: 12),
        ),
      ],
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 38),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 30,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'لا توجد مطالبات ضمان',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'تُسجل المطالبة من بطاقة الضمان، وستظهر هنا للمتابعة والتعيين.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 34),
            const SizedBox(height: 10),
            Text(
              'لا توجد مطالبة تطابق البحث',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onReset,
              child: const Text('عرض كل المطالبات'),
            ),
          ],
        ),
      ),
    );
  }
}
