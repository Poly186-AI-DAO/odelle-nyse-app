import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

/// Data class for pillar navigation items
class PillarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const PillarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
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
                      child: Icon(
                        index == currentIndex
                            ? pillars[index].activeIcon
                            : pillars[index].icon,
                        size: 24,
                        color: index == currentIndex
                            ? ThemeConstants.textOnDark
                            : ThemeConstants.textOnDark.withValues(alpha: 0.4),
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
                    // Thin icon with subtle styling
                    Icon(
                      index == currentIndex
                          ? pillars[index].activeIcon
                          : pillars[index].icon,
                      size: 20,
                      color: index == currentIndex
                          ? ThemeConstants.textOnDark
                          : ThemeConstants.textOnDark.withValues(alpha: 0.35),
                    ),

                    const SizedBox(height: 8),

                    // Thin line indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
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
