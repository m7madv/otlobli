import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.compact = false, this.onDark = false, super.key});

  final bool compact;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final markBackground = onDark
        ? Colors.white.withValues(alpha: 0.12)
        : colors.primary;
    final markForeground = onDark ? AppColors.ivory : colors.onPrimary;
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
            width: compact ? 40 : 48,
            height: compact ? 40 : 48,
            decoration: BoxDecoration(
              color: markBackground,
              borderRadius: BorderRadius.circular(compact ? 13 : 16),
              border: onDark
                  ? Border.all(color: Colors.white.withValues(alpha: 0.18))
                  : null,
            ),
            child: Center(
              child: SizedBox(
                width: compact ? 25 : 30,
                height: compact ? 27 : 32,
                child: CustomPaint(
                  painter: _DamanakGlyphPainter(color: markForeground),
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

class _DamanakGlyphPainter extends CustomPainter {
  const _DamanakGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.width * 0.13;

    final shield = Path()
      ..moveTo(size.width * 0.24, size.height * 0.06)
      ..lineTo(size.width * 0.24, size.height * 0.39)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.59,
        size.width * 0.34,
        size.height * 0.73,
        size.width * 0.50,
        size.height * 0.88,
      )
      ..cubicTo(
        size.width * 0.66,
        size.height * 0.73,
        size.width * 0.76,
        size.height * 0.59,
        size.width * 0.76,
        size.height * 0.39,
      )
      ..lineTo(size.width * 0.76, size.height * 0.06);
    canvas.drawPath(shield, paint);

    final centerRail = Path()
      ..moveTo(size.width * 0.50, size.height * 0.06)
      ..lineTo(size.width * 0.50, size.height * 0.36)
      ..cubicTo(
        size.width * 0.50,
        size.height * 0.46,
        size.width * 0.46,
        size.height * 0.51,
        size.width * 0.39,
        size.height * 0.56,
      );
    canvas.drawPath(centerRail, paint);

    paint
      ..strokeCap = StrokeCap.square
      ..strokeWidth = size.width * 0.11;
    final check = Path()
      ..moveTo(size.width * 0.39, size.height * 0.65)
      ..lineTo(size.width * 0.49, size.height * 0.76)
      ..lineTo(size.width * 0.67, size.height * 0.54);
    canvas.drawPath(check, paint);
  }

  @override
  bool shouldRepaint(covariant _DamanakGlyphPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
