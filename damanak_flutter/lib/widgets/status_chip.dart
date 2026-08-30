import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/maintenance_request.dart';
import '../models/warranty.dart';

class WarrantyStatusChip extends StatelessWidget {
  const WarrantyStatusChip({required this.status, super.key});

  final WarrantyStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (foreground, background, icon) = switch (status) {
      WarrantyStatus.active => (
        colors.primary,
        colors.primaryContainer,
        Icons.check_circle_outline_rounded,
      ),
      WarrantyStatus.expiringSoon => (
        colors.onSurface,
        colors.surfaceContainerHighest,
        Icons.schedule_rounded,
      ),
      WarrantyStatus.expired => (
        colors.error,
        colors.errorContainer,
        Icons.cancel_outlined,
      ),
    };

    return _StatusPill(
      label: status.label,
      foreground: foreground,
      background: background,
      icon: icon,
    );
  }
}

class MaintenanceStatusChip extends StatelessWidget {
  const MaintenanceStatusChip({required this.status, super.key});

  final MaintenanceStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (foreground, background, icon) = switch (status) {
      MaintenanceStatus.newRequest => (
        colors.onSurface,
        colors.surfaceContainerHighest,
        Icons.fiber_new_rounded,
      ),
      MaintenanceStatus.needsReview => (
        colors.onSurface,
        colors.surfaceContainerHighest,
        Icons.fact_check_outlined,
      ),
      MaintenanceStatus.approved => (
        colors.primary,
        colors.primaryContainer,
        Icons.verified_outlined,
      ),
      MaintenanceStatus.inProgress => (
        colors.onSurface,
        colors.surfaceContainerHighest,
        Icons.build_circle_outlined,
      ),
      MaintenanceStatus.waitingForCustomer => (
        colors.onSurface,
        colors.surfaceContainerHighest,
        Icons.hourglass_top_rounded,
      ),
      MaintenanceStatus.readyForPickup => (
        colors.primary,
        colors.primaryContainer,
        Icons.inventory_2_outlined,
      ),
      MaintenanceStatus.completed => (
        colors.primary,
        colors.primaryContainer,
        Icons.task_alt_rounded,
      ),
      MaintenanceStatus.rejected => (
        colors.error,
        colors.errorContainer,
        Icons.block_rounded,
      ),
      MaintenanceStatus.cancelled => (
        colors.onSurfaceVariant,
        colors.surfaceContainerHighest,
        Icons.cancel_outlined,
      ),
    };

    return _StatusPill(
      label: status.label,
      foreground: foreground,
      background: background,
      icon: icon,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color foreground;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
