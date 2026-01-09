import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stat card for displaying protocol stats
/// Matches the fintech design with label above value
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final bool showBorder;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.showBorder = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showBorder
              ? Border.all(
                  color: const Color(0xFFE5E7EB),
                  width: 1,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Label (uppercase, small)
            Text(
              label.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            // Value (large, bold)
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF1A1A1A),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Row of stat cards
class StatCardRow extends StatelessWidget {
  final List<StatCardData> stats;
  final double spacing;

  const StatCardRow({
    super.key,
    required this.stats,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : spacing / 2,
              right: index == stats.length - 1 ? 0 : spacing / 2,
            ),
            child: StatCard(
              label: stat.label,
              value: stat.value,
              subtitle: stat.subtitle,
              valueColor: stat.valueColor,
              showBorder: stat.showBorder,
              onTap: stat.onTap,
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Data class for stat card
class StatCardData {
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final bool showBorder;
  final VoidCallback? onTap;

  const StatCardData({
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.showBorder = true,
    this.onTap,
  });
}
