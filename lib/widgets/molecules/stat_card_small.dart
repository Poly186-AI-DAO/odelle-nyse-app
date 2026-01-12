import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

class StatCardSmall extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final String? trend;
  final bool isTrendPositive;
  final Color? color;

  const StatCardSmall({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.trend,
    this.isTrendPositive = true,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ThemeConstants.panelWhite,
        borderRadius: ThemeConstants.borderRadiusSmall,
        border: Border.all(color: ThemeConstants.glassBorderWeak),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: ThemeConstants.textMuted),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Text(
                  label,
                  style: ThemeConstants.captionStyle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: ThemeConstants.headingStyle.copyWith(
              fontSize: 18,
              color: ThemeConstants.textOnLight,
            ),
          ),
          if (trend != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  isTrendPositive ? Icons.trending_up : Icons.trending_down,
                  size: 12,
                  color: isTrendPositive ? ThemeConstants.accentGreen : ThemeConstants.uiError,
                ),
                const SizedBox(width: 2),
                Text(
                  trend!,
                  style: ThemeConstants.captionStyle.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isTrendPositive ? ThemeConstants.accentGreen : ThemeConstants.uiError,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
