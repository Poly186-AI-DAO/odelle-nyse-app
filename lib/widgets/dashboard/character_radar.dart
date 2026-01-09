import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/character_stats.dart';

/// Radar chart for character stats visualization
/// Displays Strength, Intellect, Spirit, Sales as a polygon
class CharacterRadar extends StatefulWidget {
  final CharacterStats stats;
  final double size;
  final Color fillColor;
  final Color strokeColor;
  final Color labelColor;
  final bool animate;
  final Duration animationDuration;

  const CharacterRadar({
    super.key,
    required this.stats,
    this.size = 200,
    this.fillColor = const Color(0x403B82F6),
    this.strokeColor = const Color(0xFF3B82F6),
    this.labelColor = Colors.white,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<CharacterRadar> createState() => _CharacterRadarState();
}

class _CharacterRadarState extends State<CharacterRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CharacterRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stats != widget.stats) {
      _controller.forward(from: 0);
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
        animation: _animation,
        builder: (context, _) {
          return CustomPaint(
            painter: _RadarPainter(
              stats: widget.stats,
              progress: _animation.value,
              fillColor: widget.fillColor,
              strokeColor: widget.strokeColor,
              labelColor: widget.labelColor,
            ),
            size: Size(widget.size, widget.size),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final CharacterStats stats;
  final double progress;
  final Color fillColor;
  final Color strokeColor;
  final Color labelColor;

  // Stat labels and their positions (clockwise from top)
  static const labels = ['STRENGTH', 'INTELLECT', 'SALES', 'SPIRIT'];

  _RadarPainter({
    required this.stats,
    required this.progress,
    required this.fillColor,
    required this.strokeColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.35;

    // Draw grid circles
    _drawGrid(canvas, center, radius);

    // Draw axes
    _drawAxes(canvas, center, radius);

    // Draw data polygon
    _drawDataPolygon(canvas, center, radius);

    // Draw labels
    _drawLabels(canvas, center, radius, size);
  }

  void _drawGrid(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = labelColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw 3 concentric circles (33%, 66%, 100%)
    for (var i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * (i / 3), paint);
    }
  }

  void _drawAxes(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = labelColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 2; // Start from top
      final end = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(center, end, paint);
    }
  }

  void _drawDataPolygon(Canvas canvas, Offset center, double radius) {
    // Normalize stats to 0-1 range (assuming max 100)
    final values = [
      (stats.strength / 100).clamp(0.0, 1.0),
      (stats.intellect / 100).clamp(0.0, 1.0),
      (stats.sales / 100).clamp(0.0, 1.0),
      (stats.spirit / 100).clamp(0.0, 1.0),
    ];

    final path = Path();

    for (var i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 2;
      final value = values[i] * progress;
      final point = Offset(
        center.dx + radius * value * math.cos(angle),
        center.dy + radius * value * math.sin(angle),
      );

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    // Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, strokePaint);

    // Draw points at vertices
    final pointPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 2;
      final value = values[i] * progress;
      final point = Offset(
        center.dx + radius * value * math.cos(angle),
        center.dy + radius * value * math.sin(angle),
      );
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  void _drawLabels(Canvas canvas, Offset center, double radius, Size size) {
    final textStyle = TextStyle(
      color: labelColor.withValues(alpha: 0.7),
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
    );

    for (var i = 0; i < 4; i++) {
      final angle = (i * math.pi / 2) - math.pi / 2;
      final labelRadius = radius + 20;
      final point = Offset(
        center.dx + labelRadius * math.cos(angle),
        center.dy + labelRadius * math.sin(angle),
      );

      final textSpan = TextSpan(text: labels[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      // Center the text on the point
      final textOffset = Offset(
        point.dx - textPainter.width / 2,
        point.dy - textPainter.height / 2,
      );

      textPainter.paint(canvas, textOffset);
    }
  }

  @override
  bool shouldRepaint(_RadarPainter oldDelegate) {
    return oldDelegate.stats != stats || oldDelegate.progress != progress;
  }
}

/// Compact radar with stats summary below
class CharacterRadarCard extends StatelessWidget {
  final CharacterStats stats;
  final double radarSize;

  const CharacterRadarCard({
    super.key,
    required this.stats,
    this.radarSize = 160,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CharacterRadar(
          stats: stats,
          size: radarSize,
        ),
        const SizedBox(height: 16),
        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatPill(
                label: 'STR', value: stats.strength.toInt(), color: Colors.red),
            _StatPill(
                label: 'INT',
                value: stats.intellect.toInt(),
                color: Colors.blue),
            _StatPill(
                label: 'SPR',
                value: stats.spirit.toInt(),
                color: Colors.purple),
            _StatPill(
                label: 'SAL', value: stats.sales.toInt(), color: Colors.green),
          ],
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}
