import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/maintenance_request.dart';
import '../models/warranty.dart';
import '../state/app_scope.dart';
import '../widgets/status_chip.dart';
import 'warranty_detail_screen.dart';

class RequestsScreen extends StatelessWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final requests = controller.requests;

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
                      'طلبات الصيانة',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'تابع الطلب من تسجيله حتى اكتمال الخدمة.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
              if (requests.isEmpty)
                const SliverToBoxAdapter(child: _EmptyRequests())
              else
                SliverList.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    final warranty = controller.warrantyById(
                      request.warrantyId,
                    );
                    if (warranty == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 11),
                      child: _RequestCard(
                        request: request,
                        warranty: warranty,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                WarrantyDetailScreen(warrantyId: warranty.id),
                          ),
                        ),
                        onStatusChanged: (status) {
                          controller.updateMaintenanceStatus(
                            request.id,
                            status,
                          );
                        },
                      ),
                    );
                  },
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
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
    required this.onOpen,
    required this.onStatusChanged,
  });

  final MaintenanceRequest request;
  final Warranty warranty;
  final VoidCallback onOpen;
  final ValueChanged<MaintenanceStatus> onStatusChanged;

  @override
  Widget build(BuildContext context) {
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
                          warranty.productName,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${warranty.customerName} • ${request.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  MaintenanceStatusChip(status: request.status),
                ],
              ),
              const Divider(height: 26),
              Text(
                request.issue,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 15,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatDate(request.createdAt),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  PopupMenuButton<MaintenanceStatus>(
                    tooltip: 'تغيير حالة الطلب',
                    onSelected: onStatusChanged,
                    itemBuilder: (_) => MaintenanceStatus.values
                        .map(
                          (status) => PopupMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                if (status == request.status)
                                  const Icon(Icons.check_rounded, size: 18)
                                else
                                  const SizedBox(width: 18),
                                const SizedBox(width: 8),
                                Text(status.label),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 10,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'تحديث الحالة',
                            style: TextStyle(
                              color: AppColors.emerald,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 3),
                          Icon(
                            Icons.expand_more_rounded,
                            color: AppColors.emerald,
                          ),
                        ],
                      ),
                    ),
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

class _EmptyRequests extends StatelessWidget {
  const _EmptyRequests();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 42),
        child: Center(
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.build_outlined,
                  size: 30,
                  color: AppColors.emerald,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'لا توجد طلبات صيانة',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              const Text(
                'يمكن تسجيل الطلب من داخل بطاقة ضمان العميل.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
