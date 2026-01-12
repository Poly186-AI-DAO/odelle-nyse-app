import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';
import '../../atoms/timeline_node.dart';

class MealTimelineRow extends StatelessWidget {
  final String time;
  final String icon;
  final String mealName;
  final bool isFirst;
  final bool isLast;
  final bool isComplete;
  final String? calories;

  const MealTimelineRow({
    super.key,
    required this.time,
    required this.icon,
    required this.mealName,
    this.isFirst = false,
    this.isLast = false,
    this.isComplete = false,
    this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              time,
              style: ThemeConstants.captionStyle.copyWith(
                fontWeight: FontWeight.w700,
                color: ThemeConstants.textSecondary,
              ),
            ),
          ),
          TimelineNode(
            isFirst: isFirst,
            isLast: isLast,
            isActive: isComplete,
            color: ThemeConstants.accentGreen,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: ThemeConstants.panelWhite,
                  borderRadius: ThemeConstants.borderRadius,
                border: Border.all(color: ThemeConstants.glassBorderWeak),
              ),
              child: Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      mealName,
                      style: ThemeConstants.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeConstants.textOnLight,
                      ),
                    ),
                  ),
                  if (calories != null)
                    Text(
                      calories!,
                      style: ThemeConstants.captionStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ThemeConstants.textMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
