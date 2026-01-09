import 'package:flutter/material.dart';
import '../constants/design_constants.dart';
import '../constants/theme_constants.dart';
import 'glass/glass_card.dart';

class DashboardCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;

  const DashboardCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color:
                    (iconColor ?? ThemeConstants.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: iconColor ?? ThemeConstants.primaryColor,
                size: 24,
              ),
            ),
            const Spacer(),
            Text(
              title,
              style: DesignConstants.bodyL.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: DesignConstants.bodyS.copyWith(
                color: ThemeConstants.textColor.withOpacity(0.7),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
