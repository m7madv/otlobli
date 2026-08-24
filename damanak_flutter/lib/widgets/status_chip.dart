import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/maintenance_request.dart';
import '../models/warranty.dart';

class WarrantyStatusChip extends StatelessWidget {
  const WarrantyStatusChip({required this.status, super.key});

  final WarrantyStatus status;

  @override
  Widget build(BuildContext context) {
    final (foreground, background, icon) = switch (status) {
      WarrantyStatus.active => (
        AppColors.emeraldDark,
        AppColors.mint,
        Icons.check_circle_outline_rounded,
      ),
      WarrantyStatus.expiringSoon => (
        const Color(0xFF855B12),
        const Color(0xFFFFF2D8),
        Icons.schedule_rounded,
      ),
      WarrantyStatus.expired => (
        AppColors.danger,
        const Color(0xFFFBEAEA),
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
    final (foreground, background, icon) = switch (status) {
      MaintenanceStatus.newRequest => (
        const Color(0xFF315D86),
        const Color(0xFFEAF3FC),
        Icons.fiber_new_rounded,
      ),
      MaintenanceStatus.inProgress => (
        const Color(0xFF855B12),
        const Color(0xFFFFF2D8),
        Icons.build_circle_outlined,
      ),
      MaintenanceStatus.completed => (
        AppColors.emeraldDark,
        AppColors.mint,
        Icons.task_alt_rounded,
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
