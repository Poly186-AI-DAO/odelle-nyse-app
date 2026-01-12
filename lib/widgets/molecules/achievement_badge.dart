import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

class AchievementBadge extends StatelessWidget {
  final String title;
  final String icon; // Emoji or asset path
  final Color? color;
  final bool isLocked;

  const AchievementBadge({
    super.key,
    required this.title,
    required this.icon,
    this.color,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ThemeConstants.polyGold500;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isLocked 
                ? ThemeConstants.glassBackgroundWeak 
                : effectiveColor.withValues(alpha: 0.1),
            border: Border.all(
              color: isLocked 
                  ? ThemeConstants.glassBorderWeak 
                  : effectiveColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: isLocked ? null : [
              BoxShadow(
                color: effectiveColor.withValues(alpha: 0.2),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Center(
            child: isLocked
                ? Icon(Icons.lock, color: ThemeConstants.textMuted, size: 24)
                : Text(icon, style: const TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: ThemeConstants.captionStyle.copyWith(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: isLocked ? ThemeConstants.textMuted : ThemeConstants.textSecondary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
