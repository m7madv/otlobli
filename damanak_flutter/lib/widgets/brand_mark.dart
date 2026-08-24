import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.compact = false, this.onDark = false, super.key});

  final bool compact;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final markBackground = onDark ? Colors.white : colors.primary;
    final markForeground = onDark ? AppColors.accent : colors.onPrimary;
    final titleColor = onDark ? Colors.white : colors.onSurface;
    final subtitleColor = onDark
        ? Colors.white.withValues(alpha: 0.72)
        : colors.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: 'شعار ضمانك',
          image: true,
          child: Container(
            width: compact ? 38 : 46,
            height: compact ? 38 : 46,
            decoration: BoxDecoration(
              color: markBackground,
              borderRadius: BorderRadius.circular(compact ? 12 : 15),
            ),
            child: Center(
              child: SizedBox(
                width: compact ? 23 : 28,
                height: compact ? 20 : 24,
                child: CustomPaint(
                  painter: _WarrantySealPainter(color: markForeground),
                ),
              ),
            ),
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
                color: titleColor,
                fontWeight: FontWeight.w700,
                fontSize: compact ? 19 : 23,
                height: 1,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                'ثقة موثّقة، خدمة أسهل',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _WarrantySealPainter extends CustomPainter {
  const _WarrantySealPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round;
    final widths = <double>[0.08, 0.14, 0.07, 0.18, 0.09];
    var x = 0.0;
    for (final width in widths) {
      final barWidth = size.width * width;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 0, barWidth, size.height * 0.68),
          Radius.circular(barWidth / 2),
        ),
        paint,
      );
      x += barWidth + size.width * 0.065;
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08;
    final path = Path()
      ..moveTo(size.width * 0.34, size.height * 0.82)
      ..lineTo(size.width * 0.46, size.height * 0.94)
      ..lineTo(size.width * 0.70, size.height * 0.70);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WarrantySealPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
