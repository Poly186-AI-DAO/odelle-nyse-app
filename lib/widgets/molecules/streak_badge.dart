import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

class StreakBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color? color;

  const StreakBadge({
    super.key,
    required this.count,
    this.label = 'Day Streak',
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ThemeConstants.polyPink500;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: effectiveColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: effectiveColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            '$count $label',
            style: ThemeConstants.captionStyle.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
