import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';
import '../../atoms/tag.dart';
import '../../atoms/avatar.dart';

class ExerciseListItem extends StatelessWidget {
  final String name;
  final String? equipment;
  final String sets;
  final String reps;
  final String? weight;
  final String? imageUrl;
  final bool isCompleted;
  final VoidCallback? onTap;

  const ExerciseListItem({
    super.key,
    required this.name,
    this.equipment,
    required this.sets,
    required this.reps,
    this.weight,
    this.imageUrl,
    this.isCompleted = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: ThemeConstants.borderRadius,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: ThemeConstants.panelWhite,
          borderRadius: ThemeConstants.borderRadius,
          border: Border.all(
            color: isCompleted ? ThemeConstants.accentGreen.withValues(alpha: 0.3) : ThemeConstants.glassBorderWeak,
          ),
        ),
        child: Row(
          children: [
            Avatar(
              imageUrl: imageUrl,
              fallbackText: name,
              size: 48,
              backgroundColor: ThemeConstants.glassBackgroundWeak,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    name,
                    style: ThemeConstants.bodyStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ThemeConstants.textOnLight,
                      fontSize: 15,
                    ),
                  ),
                  if (equipment != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      equipment!,
                      style: ThemeConstants.captionStyle.copyWith(
                        color: ThemeConstants.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      '$sets Sets',
                      style: ThemeConstants.captionStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: ThemeConstants.textOnLight,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 10, color: ThemeConstants.glassBorderStrong),
                    const SizedBox(width: 8),
                    Text(
                      '$reps reps',
                      style: ThemeConstants.captionStyle.copyWith(
                        color: ThemeConstants.textSecondary,
                      ),
                    ),
                  ],
                ),
                if (weight != null) ...[
                  const SizedBox(height: 4),
                  Tag(
                    text: weight!,
                    color: ThemeConstants.steelBlue,
                    variant: TagVariant.outline,
                    fontSize: 10,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
