import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedScanlines extends StatefulWidget {
  final Color color;
  final double opacity;
  final double speed;
  final double lineSpacing;

  const AnimatedScanlines({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.03,
    this.speed = 1.0,
    this.lineSpacing = 4.0,
  });

  @override
  State<AnimatedScanlines> createState() => _AnimatedScanlinesState();
}

class _AnimatedScanlinesState extends State<AnimatedScanlines>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (5000 ~/ widget.speed)),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanlinePainter(
            color: widget.color,
            opacity: widget.opacity,
            offset: _controller.value,
            lineSpacing: widget.lineSpacing,
          ),
          child: child,
        );
      },
      child: Container(),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  final Color color;
  final double opacity;
  final double offset;
  final double lineSpacing;

  _ScanlinePainter({
    required this.color,
    required this.opacity,
    required this.offset,
    required this.lineSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final startOffset = (offset * lineSpacing * 2) - lineSpacing;

    for (var y = startOffset; y < size.height + lineSpacing; y += lineSpacing) {
      // Create a slight wave effect
      final wave = math.sin(y * 0.1 + offset * math.pi * 2) * 2;
      canvas.drawLine(
        Offset(0, y + wave),
        Offset(size.width, y + wave),
        paint,
      );
    }

    // Add subtle vertical noise
    final noisePaint = Paint()
      ..color = color.withValues(alpha: opacity * 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final random = math.Random(offset.toInt());
    for (var x = 0; x < size.width; x += 20) {
      if (random.nextBool()) {
        canvas.drawLine(
          Offset(x.toDouble(), 0),
          Offset(x.toDouble(), size.height),
          noisePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ScanlinePainter oldDelegate) =>
      oldDelegate.offset != offset ||
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity ||
      oldDelegate.lineSpacing != lineSpacing;
}
