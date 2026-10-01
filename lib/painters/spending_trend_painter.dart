import 'dart:math';
import 'package:flutter/material.dart';

class SpendingTrendPainter extends CustomPainter {
  final List<double> dailySpending;
  final double animationProgress;
  final Color lineColor;

  SpendingTrendPainter({
    required this.dailySpending,
    required this.animationProgress,
    this.lineColor = const Color(0xFF00E5FF),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dailySpending.length < 2) return;

    final maxVal = dailySpending.reduce(max);
    final effectiveMax = maxVal > 0 ? maxVal * 1.15 : 100000.0;

    final path = Path();
    final fillPath = Path();

    final stepX = size.width / (dailySpending.length - 1);

    for (int i = 0; i < dailySpending.length; i++) {
      final x = i * stepX;
      final normalizedY = (dailySpending[i] / effectiveMax) * animationProgress;
      final y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        final prevX = (i - 1) * stepX;
        final prevNormalizedY =
            (dailySpending[i - 1] / effectiveMax) * animationProgress;
        final prevY = size.height - (prevNormalizedY * size.height);

        // Smooth cubic bezier control points
        final controlX1 = prevX + (stepX / 2);
        final controlY1 = prevY;
        final controlX2 = prevX + (stepX / 2);
        final controlY2 = y;

        path.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
        fillPath.cubicTo(controlX1, controlY1, controlX2, controlY2, x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // 1. Paint gradient area fill under line
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        lineColor.withOpacity(0.35),
        lineColor.withOpacity(0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = fillGradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 2. Paint smooth curve line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant SpendingTrendPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.dailySpending != dailySpending ||
        oldDelegate.lineColor != lineColor;
  }
}
