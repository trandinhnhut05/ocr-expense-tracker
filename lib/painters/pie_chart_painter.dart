import 'dart:math';
import 'package:flutter/material.dart';
import '../models/category.dart';

class PieSegmentData {
  final ExpenseCategory category;
  final double amount;
  final double percentage;

  PieSegmentData({
    required this.category,
    required this.amount,
    required this.percentage,
  });
}

class PieChartPainter extends CustomPainter {
  final List<PieSegmentData> segments;
  final double animationProgress; // 0.0 to 1.0
  final int? selectedIndex;
  final double strokeWidth;
  final double totalAmount;

  PieChartPainter({
    required this.segments,
    required this.animationProgress,
    this.selectedIndex,
    this.strokeWidth = 36.0,
    required this.totalAmount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (segments.isEmpty || totalAmount <= 0) {
      _paintEmptyState(canvas, size);
      return;
    }

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) / 2 - 12;
    final innerRadius = outerRadius - strokeWidth;

    double currentAngle = -pi / 2; // Start from top 12 o'clock

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sweepAngle = (segment.percentage / 100.0) * 2 * pi * animationProgress;

      if (sweepAngle <= 0.001) continue;

      final isSelected = selectedIndex == i;
      final currentStroke = isSelected ? strokeWidth + 8.0 : strokeWidth;
      final currentRadius = isSelected ? outerRadius + 4.0 : outerRadius;

      final rect = Rect.fromCircle(
        center: center,
        radius: currentRadius - (currentStroke / 2),
      );

      // Selected slice glow shadow
      if (isSelected) {
        final shadowPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = currentStroke + 6.0
          ..color = segment.category.color.withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawArc(rect, currentAngle, sweepAngle, false, shadowPaint);
      }

      final slicePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = currentStroke
        ..strokeCap = StrokeCap.butt
        ..color = segment.category.color;

      canvas.drawArc(rect, currentAngle, sweepAngle, false, slicePaint);

      // White separator line between slices
      if (segments.length > 1) {
        final gapPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = const Color(0xFF0F172A);
        canvas.drawArc(rect, currentAngle, 0.02, false, gapPaint);
      }

      currentAngle += sweepAngle;
    }

    // Paint center text (Donut hole details)
    _paintCenterText(canvas, center, innerRadius);
  }

  void _paintCenterText(Canvas canvas, Offset center, double innerRadius) {
    String titleText = 'Tổng Chi Tiêu';
    String valueText = _formatCompactNumber(totalAmount);
    Color textColor = Colors.white;

    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < segments.length) {
      final seg = segments[selectedIndex!];
      titleText = seg.category.nameVi;
      valueText = '${seg.percentage.toStringAsFixed(1)}%';
      textColor = seg.category.color;
    }

    final titlePainter = TextPainter(
      text: TextSpan(
        text: titleText,
        style: TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: innerRadius * 1.8);

    final valuePainter = TextPainter(
      text: TextSpan(
        text: valueText,
        style: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: innerRadius * 1.8);

    final totalHeight = titlePainter.height + valuePainter.height + 4;
    final startY = center.dy - (totalHeight / 2);

    titlePainter.paint(
      canvas,
      Offset(center.dx - (titlePainter.width / 2), startY),
    );
    valuePainter.paint(
      canvas,
      Offset(center.dx - (valuePainter.width / 2), startY + titlePainter.height + 4),
    );
  }

  void _paintEmptyState(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 12;

    final emptyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = Colors.white12;

    canvas.drawCircle(center, radius - (strokeWidth / 2), emptyPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Chưa có dữ liệu',
        style: TextStyle(color: Colors.white38, fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(center.dx - (textPainter.width / 2), center.dy - (textPainter.height / 2)),
    );
  }

  /// Interactive Hit Testing: Resolves touched segment index from tap coordinate
  static int? getTouchedIndex(
    Offset localPosition,
    Size size,
    List<PieSegmentData> segments,
    double totalAmount,
    double strokeWidth,
  ) {
    if (segments.isEmpty || totalAmount <= 0) return null;

    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) / 2 - 12;
    final innerRadius = outerRadius - strokeWidth;

    final dx = localPosition.dx - center.dx;
    final dy = localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    // Check if tap fell inside donut ring
    if (distance < innerRadius - 10 || distance > outerRadius + 15) {
      return null;
    }

    // Calculate angle in radians [0, 2*pi], starting from 12 o'clock (-pi/2)
    double angle = atan2(dy, dx); // [-pi, pi]
    // Normalize so that -pi/2 is 0
    angle += pi / 2;
    if (angle < 0) {
      angle += 2 * pi;
    }

    double currentAngle = 0.0;
    for (int i = 0; i < segments.length; i++) {
      final sweepAngle = (segments[i].percentage / 100.0) * 2 * pi;
      if (angle >= currentAngle && angle <= currentAngle + sweepAngle) {
        return i;
      }
      currentAngle += sweepAngle;
    }

    return null;
  }

  String _formatCompactNumber(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}tr ₫';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}k ₫';
    }
    return '${amount.toStringAsFixed(0)} ₫';
  }

  @override
  bool shouldRepaint(covariant PieChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.segments != segments ||
        oldDelegate.totalAmount != totalAmount;
  }
}
