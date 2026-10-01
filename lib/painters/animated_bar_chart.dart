import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'bar_chart_painter.dart';

class AnimatedBarChart extends StatefulWidget {
  final List<BarChartItem> items;
  final double height;

  const AnimatedBarChart({
    Key? key,
    required this.items,
    this.height = 200,
  }) : super(key: key);

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
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

  void _handleTap(TapUpDetails details, Size size) {
    final touched = BarChartPainter.getTouchedIndex(
      details.localPosition,
      size,
      widget.items.length,
    );

    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIndex == touched) {
        _selectedIndex = null;
      } else {
        _selectedIndex = touched;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = Size(constraints.maxWidth, widget.height);

        return GestureDetector(
          onTapUp: (details) => _handleTap(details, chartSize),
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                size: chartSize,
                painter: BarChartPainter(
                  items: widget.items,
                  animationProgress: _animation.value,
                  selectedIndex: _selectedIndex,
                ),
              );
            },
          ),
        );
      },
    );
  }
}
