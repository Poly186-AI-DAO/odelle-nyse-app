import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

class MacroProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final String unit;
  final Color color;

  const MacroProgressBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    this.unit = 'g',
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / target).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: ThemeConstants.captionStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: ThemeConstants.textSecondary,
              ),
            ),
            Text(
              '${current.toInt()}/${target.toInt()}$unit',
              style: ThemeConstants.captionStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeConstants.textOnLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: ThemeConstants.glassBorderWeak,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
