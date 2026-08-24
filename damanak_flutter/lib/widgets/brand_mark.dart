import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 38 : 46,
          height: compact ? 38 : 46,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(compact ? 12 : 15),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.verified_user_rounded,
                color: Colors.white,
                size: compact ? 22 : 27,
              ),
              Positioned(
                left: compact ? 6 : 7,
                bottom: compact ? 5 : 6,
                child: Container(
                  width: compact ? 7 : 8,
                  height: compact ? 7 : 8,
                  decoration: const BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ضمانك',
              style: TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w900,
                fontSize: compact ? 19 : 23,
                height: 1,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              const Text(
                'ثقة موثّقة، خدمة أسهل',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
