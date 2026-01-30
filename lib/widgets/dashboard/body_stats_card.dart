import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';
import 'package:google_fonts/google_fonts.dart';

/// Full body stats card - shown when panel is collapsed
/// Matches CosmicStatsCard styling (translucent, no shadow)
class BodyStatsCard extends StatelessWidget {
  final int trainingReadiness;
  final int caloriesConsumed;
  final int caloriesBurned;
  final int sleepDurationMinutes;
  final double currentWeight;
  final double currentBodyFat;
  final double heightInches;
  final VoidCallback? onTap;

  const BodyStatsCard({
    super.key,
    required this.trainingReadiness,
    required this.caloriesConsumed,
    required this.caloriesBurned,
    required this.sleepDurationMinutes,
    this.currentWeight = 0.0,
    this.currentBodyFat = 0.0,
    this.heightInches = 72.0,
    this.onTap,
  });

  String _formatSleepDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: ThemeConstants.borderRadiusXL,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PHYSICAL METRICS',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getReadinessColor(trainingReadiness)
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getReadinessColor(trainingReadiness)
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    'READINESS: $trainingReadiness%',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getReadinessColor(trainingReadiness),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 1: Weight, Body Fat, BMI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatValue(
                    'WEIGHT', currentWeight.toStringAsFixed(1), 'lbs'),
                _buildStatValue(
                    'BODY FAT', currentBodyFat.toStringAsFixed(1), '%'),
                _buildStatValue(
                    'BMI', _calculateBMI(currentWeight).toStringAsFixed(1), ''),
              ],
            ),

            const SizedBox(height: 16),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 16),

            // Row 2: Calories Consumed, Sleep Duration, Calories Burned
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatValue(
                    'CONSUMED', caloriesConsumed.toString(), 'kcal'),
                _buildStatValue(
                    'SLEEP', _formatSleepDuration(sleepDurationMinutes), ''),
                _buildStatValue('BURNED', caloriesBurned.toString(), 'kcal',
                    valueColor:
                        caloriesBurned > 0 ? ThemeConstants.uiSuccess : null),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatValue(String label, String value, String unit,
      {Color? valueColor}) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Colors.white54,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: valueColor ?? Colors.white,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 2),
              Text(
                unit,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  double _calculateBMI(double weightLbs) {
    // Formula: 703 * weight(lbs) / height(in)^2
    if (heightInches <= 0 || weightLbs <= 0) return 0.0;
    return 703 * weightLbs / (heightInches * heightInches);
  }

  Color _getReadinessColor(int score) {
    if (score >= 80) return ThemeConstants.uiSuccess;
    if (score >= 50) return ThemeConstants.uiWarning;
    return ThemeConstants.uiError;
  }
}

/// Compact stats bar - shown when panel is expanded
/// Just the 3 key metrics: Consumed, Sleep, Burned
class CompactBodyStatsBar extends StatelessWidget {
  final int caloriesConsumed;
  final int sleepDurationMinutes;
  final int caloriesBurned;
  final VoidCallback? onTap;

  const CompactBodyStatsBar({
    super.key,
    required this.caloriesConsumed,
    required this.sleepDurationMinutes,
    required this.caloriesBurned,
    this.onTap,
  });

  String _formatSleepDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildCompactStat('🍽️', '$caloriesConsumed', 'kcal'),
            Container(
                width: 1,
                height: 24,
                color: Colors.white.withValues(alpha: 0.1)),
            _buildCompactStat(
                '😴', _formatSleepDuration(sleepDurationMinutes), ''),
            Container(
                width: 1,
                height: 24,
                color: Colors.white.withValues(alpha: 0.1)),
            _buildCompactStat('🔥', '$caloriesBurned', 'kcal',
                highlight: caloriesBurned > 0),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStat(String emoji, String value, String unit,
      {bool highlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: highlight ? ThemeConstants.uiSuccess : Colors.white,
          ),
        ),
        if (unit.isNotEmpty) ...[
          const SizedBox(width: 2),
          Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white54,
            ),
          ),
        ],
      ],
    );
  }
}
