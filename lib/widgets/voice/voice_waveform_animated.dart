import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated waveform visualizer for voice button
/// Shows dynamic bars when actively listening
class VoiceWaveformAnimated extends StatefulWidget {
  final bool isActive;
  final Color color;
  final double size;
  final int barCount;

  const VoiceWaveformAnimated({
    super.key,
    this.isActive = false,
    this.color = const Color(0xFF1A1A1A),
    this.size = 24,
    this.barCount = 5,
  });

  @override
  State<VoiceWaveformAnimated> createState() => _VoiceWaveformAnimatedState();
}

class _VoiceWaveformAnimatedState extends State<VoiceWaveformAnimated>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(VoiceWaveformAnimated oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(widget.barCount, (index) {
              final phase = index * (math.pi / widget.barCount);
              final animValue = widget.isActive
                  ? (math.sin(_controller.value * math.pi * 2 + phase) + 1) / 2
                  : 0.3;
              final height = 0.2 + (0.8 * animValue);

              return Container(
                width: widget.size / (widget.barCount * 2),
                height: widget.size * height,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(
                      widget.size / (widget.barCount * 4)),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
