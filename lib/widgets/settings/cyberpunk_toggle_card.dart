import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';

class CyberpunkToggleCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isEnabled;
  final VoidCallback onToggle;
  final IconData icon;

  const CyberpunkToggleCard({
    super.key,
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.onToggle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.spacingMedium,
        vertical: ThemeConstants.spacingSmall,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: isEnabled
              ? ThemeConstants.primaryColor
              : ThemeConstants.borderColor,
          width: ThemeConstants.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(ThemeConstants.spacingMedium),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(ThemeConstants.spacingSmall),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isEnabled
                          ? ThemeConstants.primaryColor
                          : ThemeConstants.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isEnabled
                        ? ThemeConstants.primaryColor
                        : ThemeConstants.borderColor,
                  ),
                ),
                const SizedBox(width: ThemeConstants.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: GoogleFonts.pressStart2p(
                          color: isEnabled
                              ? ThemeConstants.primaryColor
                              : ThemeConstants.textColor,
                          fontSize: 12,
                          shadows: isEnabled ? ThemeConstants.textGlow : null,
                        ),
                      ),
                      const SizedBox(height: ThemeConstants.spacingSmall),
                      Text(
                        description,
                        style: GoogleFonts.pressStart2p(
                          color: ThemeConstants.secondaryTextColor,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isEnabled
                          ? ThemeConstants.primaryColor
                          : ThemeConstants.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Stack(
                    children: [
                      AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: isEnabled
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          width: 18,
                          height: 18,
                          color: isEnabled
                              ? ThemeConstants.primaryColor
                              : ThemeConstants.borderColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
