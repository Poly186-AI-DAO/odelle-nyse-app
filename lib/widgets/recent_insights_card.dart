import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:odelle_nyse/constants/colors.dart';
import 'package:odelle_nyse/models/insights_model.dart';
import 'package:odelle_nyse/widgets/glassmorphism.dart';

class RecentInsightsCard extends StatelessWidget {
  final InsightEntry insightEntry;

  const RecentInsightsCard({
    super.key,
    required this.insightEntry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassMorphism(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 240, // Increased height to accommodate radar chart
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Insights",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "${insightEntry.date.day}/${insightEntry.date.month}/${insightEntry.date.year}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _RadarChart(dimensions: insightEntry.dimensions),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var dimension in insightEntry.dimensions)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: _InsightItem(dimension: dimension),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              insightEntry.summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 800.ms, curve: Curves.easeOutQuad)
      .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOutQuad);
  }
}

class _InsightItem extends StatelessWidget {
  final InsightDimension dimension;

  const _InsightItem({required this.dimension});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getDimensionColor(dimension.name),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            dimension.name,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _RadarChart extends StatelessWidget {
  final List<InsightDimension> dimensions;

  const _RadarChart({required this.dimensions});

  @override
  Widget build(BuildContext context) {
    // Create a simplified visualization instead of RadarChart due to API compatibility issues
    return Container(
      padding: const EdgeInsets.all(8),
      child: CustomPaint(
        painter: _InsightRadarPainter(
          dimensions: dimensions,
          colors: [
            AppColors.primary,
            AppColors.secondary,
            AppColors.accent1,
            AppColors.accent2,
            AppColors.lightPurple,
          ],
        ),
        child: const SizedBox.expand(),
      ),
    ).animate().fadeIn(
          duration: 1200.ms,
          delay: 300.ms,
          curve: Curves.easeOutQuad,
        );
  }
}

class _InsightRadarPainter extends CustomPainter {
  final List<InsightDimension> dimensions;
  final List<Color> colors;

  _InsightRadarPainter({
    required this.dimensions,
    required this.colors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 * 0.8 : size.height / 2 * 0.8;
    
    // Draw outer circle
    final outerCirclePaint = Paint()
      ..color = AppColors.secondary.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius, outerCirclePaint);

    // Draw inner circles (grid)
    for (double r = radius * 0.2; r < radius; r += radius * 0.2) {
      canvas.drawCircle(
        center, 
        r, 
        Paint()
          ..color = AppColors.secondary.withOpacity(0.1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5,
      );
    }

    // Draw dimension lines
    final count = dimensions.length;
    for (int i = 0; i < count; i++) {
      final angle = 2 * 3.14159 * i / count - 3.14159 / 2; // Start from top
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      
      canvas.drawLine(
        center, 
        Offset(x, y), 
        Paint()
          ..color = AppColors.secondary.withOpacity(0.2)
          ..strokeWidth = 1,
      );
    }

    // Draw data points and fill
    final path = Path();
    final pointPaint = Paint()
      ..color = AppColors.secondary
      ..style = PaintingStyle.fill;
    
    for (int i = 0; i < count; i++) {
      final angle = 2 * 3.14159 * i / count - 3.14159 / 2; // Start from top
      final value = dimensions[i].value;
      final pointRadius = radius * value;
      final x = center.dx + pointRadius * cos(angle);
      final y = center.dy + pointRadius * sin(angle);
      
      // Draw point
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
      
      // Add point to path
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    // Close the path
    path.close();
    
    // Draw filled area
    canvas.drawPath(
      path, 
      Paint()
        ..color = AppColors.lightPurple.withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );
    
    // Draw outline
    canvas.drawPath(
      path, 
      Paint()
        ..color = AppColors.secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

Color _getDimensionColor(String dimensionName) {
  switch (dimensionName) {
    case 'Awareness':
      return AppColors.primary;
    case 'Acceptance':
      return AppColors.secondary;
    case 'Compassion':
      return AppColors.accent1;
    case 'Gratitude':
      return AppColors.accent2;
    case 'Resilience':
      return AppColors.lightPurple;
    default:
      return AppColors.secondary;
  }
}
