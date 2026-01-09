import 'package:flutter/material.dart';

/// Gradient overlay for backgrounds
/// Creates the dark teal → warm sunset gradient
class GradientOverlay extends StatelessWidget {
  final Widget? child;
  final List<Color>? colors;
  final List<double>? stops;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;

  const GradientOverlay({
    super.key,
    this.child,
    this.colors,
    this.stops,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  /// Default dark gradient (like the fintech design)
  static const defaultColors = [
    Color(0xFF0A1628), // Deep Navy
    Color(0xFF1E3A5F), // Dark Teal
    Color(0xFF4A6B7C), // Steel Blue
    Color(0xFF8B7355), // Warm Taupe
    Color(0xFFC4A574), // Sunset Gold
  ];

  static const defaultStops = [0.0, 0.25, 0.5, 0.75, 1.0];

  /// Voice conversation gradient (simpler)
  static const voiceColors = [
    Color(0xFF2D3E50), // Dark Slate
    Color(0xFF5A6B7A), // Cool Gray
    Color(0xFF8E9EAD), // Soft Silver
  ];

  static const voiceStops = [0.0, 0.5, 1.0];

  /// Dashboard gradient (darker)
  static const dashboardColors = [
    Color(0xFF0F0F1A), // Deep Dark
    Color(0xFF1A1A2E), // Dark Purple
    Color(0xFF16213E), // Dark Blue
  ];

  static const dashboardStops = [0.0, 0.5, 1.0];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors ?? defaultColors,
          stops: stops ?? defaultStops,
        ),
      ),
      child: child,
    );
  }
}

/// Animated gradient background
class AnimatedGradientOverlay extends StatefulWidget {
  final Widget? child;
  final Duration duration;
  final List<List<Color>> colorSets;

  const AnimatedGradientOverlay({
    super.key,
    this.child,
    this.duration = const Duration(seconds: 10),
    this.colorSets = const [
      [Color(0xFF0A1628), Color(0xFF1E3A5F), Color(0xFF4A6B7C)],
      [Color(0xFF1E3A5F), Color(0xFF4A6B7C), Color(0xFF8B7355)],
      [Color(0xFF4A6B7C), Color(0xFF8B7355), Color(0xFFC4A574)],
    ],
  });

  @override
  State<AnimatedGradientOverlay> createState() =>
      _AnimatedGradientOverlayState();
}

class _AnimatedGradientOverlayState extends State<AnimatedGradientOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.colorSets.length;
          });
          _controller.forward(from: 0);
        }
      });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final nextIndex = (_currentIndex + 1) % widget.colorSets.length;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _lerpColors(
                widget.colorSets[_currentIndex],
                widget.colorSets[nextIndex],
                _controller.value,
              ),
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }

  List<Color> _lerpColors(List<Color> from, List<Color> to, double t) {
    return List.generate(
      from.length,
      (i) => Color.lerp(from[i], to[i], t)!,
    );
  }
}
