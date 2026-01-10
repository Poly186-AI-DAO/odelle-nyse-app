import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/theme_constants.dart';

/// Data class for pillar navigation items
class PillarItem {
  final IconData? icon;
  final IconData? activeIcon;
  final String? assetIcon;
  final String? assetActiveIcon;
  final String label;

  const PillarItem({
    this.icon,
    this.activeIcon,
    this.assetIcon,
    this.assetActiveIcon,
    required this.label,
  }) : assert(
          (icon != null && activeIcon != null) || assetIcon != null,
          'Provide either icon/activeIcon or assetIcon.',
        );
}

Widget _buildPillarIcon({
  required PillarItem pillar,
  required bool isActive,
  required double size,
  required double inactiveAlpha,
}) {
  final color = isActive
      ? ThemeConstants.textOnDark
      : ThemeConstants.textOnDark.withValues(alpha: inactiveAlpha);
  final assetPath =
      isActive ? (pillar.assetActiveIcon ?? pillar.assetIcon) : pillar.assetIcon;

  if (assetPath != null) {
    if (assetPath.toLowerCase().endsWith('.svg')) {
      return SvgPicture.asset(
        assetPath,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }

    return Image.asset(
      assetPath,
      width: size,
      height: size,
      color: color,
      colorBlendMode: BlendMode.srcIn,
    );
  }

  return Icon(
    isActive ? pillar.activeIcon : pillar.icon,
    size: size,
    color: color,
  );
}

/// Top navigation bar with thin icons and indicator underneath active icon
/// Matches fintech minimal design aesthetic
class PillarNavBar extends StatelessWidget {
  final List<PillarItem> pillars;
  final int currentIndex;
  final ValueChanged<int> onPillarTapped;

  const PillarNavBar({
    super.key,
    required this.pillars,
    required this.currentIndex,
    required this.onPillarTapped,
  });

  @override
  Widget build(BuildContext context) {
    const double itemSpacing = 44;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < pillars.length; index++) ...[
              if (index > 0) const SizedBox(width: itemSpacing),
              GestureDetector(
                onTap: () => onPillarTapped(index),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      child: _buildPillarIcon(
                        pillar: pillars[index],
                        isActive: index == currentIndex,
                        size: 28,
                        inactiveAlpha: 0.4,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Indicator dot underneath
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: index == currentIndex ? 4 : 0,
                      height: 4,
                      decoration: BoxDecoration(
                        color: ThemeConstants.textOnDark,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Alternative thin line style nav bar (matching fintech screenshots more closely)
class PillarNavBarThin extends StatelessWidget {
  final List<PillarItem> pillars;
  final int currentIndex;
  final ValueChanged<int> onPillarTapped;

  const PillarNavBarThin({
    super.key,
    required this.pillars,
    required this.currentIndex,
    required this.onPillarTapped,
  });

  @override
  Widget build(BuildContext context) {
    const double itemSpacing = 44;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < pillars.length; index++) ...[
              if (index > 0) const SizedBox(width: itemSpacing),
              GestureDetector(
                onTap: () => onPillarTapped(index),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Thin icon with animated opacity
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: index == currentIndex ? 1.0 : 0.5,
                      child: _buildPillarIcon(
                        pillar: pillars[index],
                        isActive: index == currentIndex,
                        size: 24,
                        inactiveAlpha: 0.35,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Thin line indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: index == currentIndex ? 16 : 0,
                      height: 2,
                      decoration: BoxDecoration(
                        color: ThemeConstants.textOnDark,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
