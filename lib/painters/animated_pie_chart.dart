import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pie_chart_painter.dart';
import '../models/category.dart';
import '../utils/currency_formatter.dart';

class AnimatedPieChart extends StatefulWidget {
  final Map<String, double> categoryTotals;
  final double size;
  final Function(ExpenseCategory?)? onCategorySelected;

  const AnimatedPieChart({
    Key? key,
    required this.categoryTotals,
    this.size = 240,
    this.onCategorySelected,
  }) : super(key: key);

  @override
  State<AnimatedPieChart> createState() => _AnimatedPieChartState();
}

class _AnimatedPieChartState extends State<AnimatedPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedPieChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryTotals != widget.categoryTotals) {
      _controller.reset();
      _controller.forward();
      setState(() {
        _selectedIndex = null;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<PieSegmentData> _buildSegments(double total) {
    if (total <= 0) return [];

    final list = <PieSegmentData>[];
    widget.categoryTotals.forEach((catId, amount) {
      if (amount > 0) {
        final category = ExpenseCategory.getById(catId);
        final pct = (amount / total) * 100.0;
        list.add(PieSegmentData(
          category: category,
          amount: amount,
          percentage: pct,
        ));
      }
    });

    list.sort((a, b) => b.amount.compareTo(a.amount));
    return list;
  }

  void _handleTap(TapUpDetails details, Size size, List<PieSegmentData> segments, double total) {
    final touched = PieChartPainter.getTouchedIndex(
      details.localPosition,
      size,
      segments,
      total,
      36.0,
    );

    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIndex == touched) {
        _selectedIndex = null;
        widget.onCategorySelected?.call(null);
      } else {
        _selectedIndex = touched;
        if (touched != null && touched < segments.length) {
          widget.onCategorySelected?.call(segments[touched].category);
        } else {
          widget.onCategorySelected?.call(null);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.categoryTotals.values.fold(0.0, (sum, val) => sum + val);
    final segments = _buildSegments(total);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTapUp: (details) => _handleTap(
            details,
            Size(widget.size, widget.size),
            segments,
            total,
          ),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: Size(widget.size, widget.size),
                painter: PieChartPainter(
                  segments: segments,
                  animationProgress: _animation.value,
                  selectedIndex: _selectedIndex,
                  totalAmount: total,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        // Interactive Category Chips Legend
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: List.generate(segments.length, (index) {
            final seg = segments[index];
            final isSelected = _selectedIndex == index;

            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _selectedIndex = isSelected ? null : index;
                  widget.onCategorySelected?.call(
                    _selectedIndex != null ? seg.category : null,
                  );
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? seg.category.color.withOpacity(0.25)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.Border.all(
                    color: isSelected ? seg.category.color : Colors.white10,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: seg.category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      seg.category.nameVi,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${seg.percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: seg.category.color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
