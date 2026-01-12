import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';
import '../../atoms/icon_badge.dart';
import '../../atoms/tag.dart';

class SupplementListItem extends StatelessWidget {
  final String name;
  final String brand;
  final String dosage;
  final String frequency;
  final IconData icon;
  final Color? accentColor;
  final VoidCallback? onTap;

  const SupplementListItem({
    super.key,
    required this.name,
    required this.brand,
    required this.dosage,
    required this.frequency,
    this.icon = Icons.medication,
    this.accentColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = accentColor ?? ThemeConstants.accentBlue;
    
    return InkWell(
      onTap: onTap,
      borderRadius: ThemeConstants.borderRadius,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ThemeConstants.glassBorderWeak, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            IconBadge(
              icon: icon,
              color: effectiveColor,
              size: 40,
              iconSize: 18,
            ),
            const SizedBox(width: 16),
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
                  const SizedBox(height: 2),
                  Text(
                    brand,
                    style: ThemeConstants.captionStyle.copyWith(
                      color: ThemeConstants.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  dosage,
                  style: ThemeConstants.captionStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                const SizedBox(height: 4),
                Tag(
                  text: frequency,
                  color: ThemeConstants.steelBlue,
                  fontSize: 9,
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: ThemeConstants.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
