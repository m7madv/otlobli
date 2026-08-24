import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/date_utils.dart';
import '../models/warranty.dart';
import 'status_chip.dart';

class WarrantyCard extends StatelessWidget {
  const WarrantyCard({
    required this.warranty,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final Warranty warranty;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final status = warranty.statusAt();
    final colors = context.colors;
    return Semantics(
      button: true,
      label: 'ضمان ${warranty.productName} للعميل ${warranty.customerName}',
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(
                  width: 6,
                  color: switch (status) {
                    WarrantyStatus.active => colors.primary,
                    WarrantyStatus.expiringSoon => colors.outline,
                    WarrantyStatus.expired => colors.error,
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 14 : 17),
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
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    warranty.customerName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            WarrantyStatusChip(status: status),
                          ],
                        ),
                        SizedBox(height: compact ? 12 : 16),
                        Wrap(
                          spacing: 14,
                          runSpacing: 8,
                          children: [
                            _Meta(
                              icon: Icons.event_available_outlined,
                              text: 'حتى ${formatDate(warranty.expiryDate)}',
                            ),
                            _Meta(
                              icon: Icons.badge_outlined,
                              text: warranty.displayNumber,
                            ),
                          ],
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 11),
                          Text(
                            warrantyRemainingLabel(warranty.expiryDate),
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.primary, size: 16),
        const SizedBox(width: 5),
        Text(
          text,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
