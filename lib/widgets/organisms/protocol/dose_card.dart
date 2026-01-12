import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';
import '../../atoms/icon_badge.dart';
import '../../atoms/status_dot.dart';

class DoseCard extends StatelessWidget {
  final String supplementName;
  final String dosage;
  final String scheduledTime;
  final bool isTaken;
  final VoidCallback? onToggle;
  final IconData icon;
  final Color? accentColor;

  const DoseCard({
    super.key,
    required this.supplementName,
    required this.dosage,
    required this.scheduledTime,
    this.isTaken = false,
    this.onToggle,
    this.icon = Icons.medication_liquid,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = accentColor ?? ThemeConstants.accentBlue;
    
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ThemeConstants.panelWhite,
        borderRadius: ThemeConstants.borderRadiusLarge,
        border: Border.all(
          color: isTaken ? effectiveColor.withValues(alpha: 0.3) : ThemeConstants.glassBorderWeak,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          IconBadge(
            icon: icon,
            color: effectiveColor,
            size: 48,
            isActive: !isTaken,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  supplementName,
                  style: ThemeConstants.headingStyle.copyWith(
                    fontSize: 16,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      scheduledTime,
                      style: ThemeConstants.captionStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: ThemeConstants.textMuted,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      dosage,
                      style: ThemeConstants.captionStyle.copyWith(
                        color: ThemeConstants.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggle,
            icon: StatusDot(
              status: isTaken ? StatusType.complete : StatusType.empty,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
