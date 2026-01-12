import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;
  final bool isActive;
  final bool usePadding;

  const IconBadge({
    super.key,
    required this.icon,
    this.color,
    this.backgroundColor,
    this.size = 40.0,
    this.iconSize = 20.0,
    this.isActive = true,
    this.usePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ThemeConstants.primaryColor;
    final effectiveBgColor = backgroundColor ?? effectiveColor.withValues(alpha: 0.1);

    return Container(
      width: size,
      height: size,
      padding: usePadding ? EdgeInsets.all(size * 0.25) : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isActive ? effectiveBgColor : ThemeConstants.glassBackgroundWeak,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          icon,
          color: isActive ? effectiveColor : ThemeConstants.textMuted,
          size: iconSize,
        ),
      ),
    );
  }
}
