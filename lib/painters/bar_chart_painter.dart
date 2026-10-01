import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';

class BarChartItem {
  final String label; // e.g. "T5", "Th 08", "Th 09"
  final double value;
  final bool isCurrentPeriod;

  BarChartItem({
    required this.label,
    required this.value,
    this.isCurrentPeriod = false,
  });
}

class BarChartPainter extends CustomPainter {
  final List<BarChartItem> items;
  final double animationProgress;
  final int? selectedIndex;
  final double maxValue;

  BarChartPainter({
    required this.items,
    required this.animationProgress,
    this.selectedIndex,
    double? maxValue,
  }) : maxValue = maxValue ?? _calculateDefaultMax(items);

  static double _calculateDefaultMax(List<BarChartItem> items) {
    if (items.isEmpty) return 1000000.0;
    final maxVal = items.map((e) => e.value).reduce(max);
    return maxVal > 0 ? maxVal * 1.25 : 1000000.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelHeight = 28.0;
    const topMargin = 30.0;
    const leftMargin = 38.0;
    const rightMargin = 12.0;

    final chartWidth = size.width - leftMargin - rightMargin;
    final chartHeight = size.height - topMargin - bottomLabelHeight;

    if (items.isEmpty) {
      _paintEmptyState(canvas, size);
      return;
    }

    // 1. Draw horizontal grid lines & Y labels
    _paintGridLines(canvas, size, leftMargin, topMargin, chartWidth, chartHeight);

    // 2. Draw bars
    final totalBars = items.length;
    final availableBarArea = chartWidth / totalBars;
    final barWidth = min(28.0, availableBarArea * 0.55);

    for (int i = 0; i < totalBars; i++) {
      final item = items[i];
      final isSelected = selectedIndex == i;
      final centerX = leftMargin + (i * availableBarArea) + (availableBarArea / 2);

      // Background Track
      final trackPaint = Paint()
        ..color = Colors.white.withOpacity(0.04)
        ..style = PaintingStyle.fill;
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - (barWidth / 2),
          topMargin,
          barWidth,
          chartHeight,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(trackRect, trackPaint);

      // Active Value Bar
      final scaledValue = (item.value / maxValue).clamp(0.0, 1.0);
      final barHeight = scaledValue * chartHeight * animationProgress;
      final barTop = topMargin + chartHeight - barHeight;

      if (barHeight > 0) {
        final barRect = Rect.fromLTWH(
          centerX - (barWidth / 2),
          barTop,
          barWidth,
          barHeight,
        );

        final barRRect = RRect.fromRectAndRadius(
          barRect,
          const Radius.circular(8),
        );

        // Gradient shader
        final gradient = LinearGradient(
          colors: isSelected
              ? [const Color(0xFF00E676), const Color(0xFF00E5FF)]
              : item.isCurrentPeriod
                  ? [const Color(0xFF00E5FF), const Color(0xFF0072FF)]
                  : [const Color(0xFF38BDF8), const Color(0xFF1E3A8A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );

        final barPaint = Paint()
          ..shader = gradient.createShader(barRect)
          ..style = PaintingStyle.fill;

        // Glow for selected
        if (isSelected) {
          final glowPaint = Paint()
            ..color = const Color(0xFF00E676).withOpacity(0.4)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
          canvas.drawRRect(barRRect, glowPaint);
        }

        canvas.drawRRect(barRRect, barPaint);
      }

      // X-Axis Label
      final labelPainter = TextPainter(
        text: TextSpan(
          text: item.label,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFF00E5FF)
                : item.isCurrentPeriod
                    ? Colors.white
                    : Colors.white54,
            fontSize: 11,
            fontWeight: isSelected || item.isCurrentPeriod
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      labelPainter.paint(
        canvas,
        Offset(centerX - (labelPainter.width / 2), size.height - bottomLabelHeight + 6),
      );

      // Tooltip above selected bar
      if (isSelected) {
        _paintTooltip(canvas, centerX, barTop, item);
      }
    }
  }

  void _paintGridLines(Canvas canvas, Size size, double left, double top,
      double width, double height) {
    final linePaint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1.0;

    const steps = 4;
    for (int s = 0; s <= steps; s++) {
      final y = top + height - (s * (height / steps));
      canvas.drawLine(Offset(left, y), Offset(left + width, y), linePaint);

      final val = (maxValue / steps) * s;
      final yLabel = TextPainter(
        text: TextSpan(
          text: CurrencyFormatter.formatCompact(val),
          style: const TextStyle(
            color: Colors.white30,
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
      )..layout(maxWidth: left - 4);

      yLabel.paint(
        canvas,
        Offset(left - yLabel.width - 6, y - (yLabel.height / 2)),
      );
    }
  }

  void _paintTooltip(Canvas canvas, double centerX, double barTop, BarChartItem item) {
    final formatted = CurrencyFormatter.formatVND(item.value);
    final textPainter = TextPainter(
      text: TextSpan(
        text: formatted,
        style: const TextStyle(
          color: Color(0xFF0F172A),
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final paddingH = 8.0;
    final paddingV = 4.0;
    final tooltipWidth = textPainter.width + (paddingH * 2);
    final tooltipHeight = textPainter.height + (paddingV * 2);
    final tooltipTop = barTop - tooltipHeight - 8;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        centerX - (tooltipWidth / 2),
        tooltipTop,
        tooltipWidth,
        tooltipHeight,
      ),
      const Radius.circular(6),
    );

    final bgPaint = Paint()..color = const Color(0xFF00E676);
    canvas.drawRRect(bgRect, bgPaint);

    textPainter.paint(
      canvas,
      Offset(centerX - (textPainter.width / 2), tooltipTop + paddingV),
    );
  }

  void _paintEmptyState(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'Chưa có dữ liệu xu hướng',
        style: TextStyle(color: Colors.white38, fontSize: 13),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset((size.width - textPainter.width) / 2,
          (size.height - textPainter.height) / 2),
    );
  }

  static int? getTouchedIndex(Offset localPosition, Size size, int itemCount) {
    const leftMargin = 38.0;
    const rightMargin = 12.0;
    final chartWidth = size.width - leftMargin - rightMargin;

    if (localPosition.dx < leftMargin ||
        localPosition.dx > size.width - rightMargin) {
      return null;
    }

    final barAreaWidth = chartWidth / itemCount;
    final relativeX = localPosition.dx - leftMargin;
    final index = (relativeX / barAreaWidth).floor();

    if (index >= 0 && index < itemCount) {
      return index;
    }
    return null;
  }

  @override
  bool shouldRepaint(covariant BarChartPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.items != items ||
        oldDelegate.maxValue != maxValue;
  }
}
