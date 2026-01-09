import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isActive;
  final Color color;

  const WaveformVisualizer({
    super.key,
    this.isActive = false,
    this.color = ThemeConstants.polyMint400,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final value = widget.isActive
                  ? (math.sin(_controller.value * 2 * math.pi + index) + 1) / 2
                  : 0.1;
              return Container(
                width: 4,
                height: 10 + (value * 40),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
