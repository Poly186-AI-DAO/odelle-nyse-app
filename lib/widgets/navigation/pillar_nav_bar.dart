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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(pillars.length, (index) {
          final pillar = pillars[index];
          final isActive = index == currentIndex;

          return GestureDetector(
            onTap: () => onPillarTapped(index),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isActive ? pillar.activeIcon : pillar.icon,
                    size: 24,
                    color: isActive
                        ? ThemeConstants.textOnDark
                        : ThemeConstants.textOnDark.withValues(alpha: 0.4),
                  ),
                ),

                const SizedBox(height: 6),

                // Indicator dot underneath
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isActive ? 4 : 0,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ThemeConstants.textOnDark,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          );
        }),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(pillars.length, (index) {
          final pillar = pillars[index];
          final isActive = index == currentIndex;

          return GestureDetector(
            onTap: () => onPillarTapped(index),
            behavior: HitTestBehavior.opaque,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thin icon with subtle styling
                Icon(
                  isActive ? pillar.activeIcon : pillar.icon,
                  size: 20,
                  color: isActive
                      ? ThemeConstants.textOnDark
                      : ThemeConstants.textOnDark.withValues(alpha: 0.35),
                ),

                const SizedBox(height: 8),

                // Thin line indicator
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: isActive ? 16 : 0,
                  height: 2,
                  decoration: BoxDecoration(
                    color: ThemeConstants.textOnDark,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
