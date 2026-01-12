import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';
import '../../molecules/macro_progress_bar.dart';

class NutritionOverviewCard extends StatelessWidget {
  final int caloriesConsumed;
  final int caloriesGoal;
  final int caloriesBurned;
  final double proteinConsumed;
  final double proteinGoal;
  final double fatsConsumed;
  final double fatsGoal;
  final double carbsConsumed;
  final double carbsGoal;

  const NutritionOverviewCard({
    super.key,
    required this.caloriesConsumed,
    required this.caloriesGoal,
    required this.caloriesBurned,
    required this.proteinConsumed,
    required this.proteinGoal,
    required this.fatsConsumed,
    required this.fatsGoal,
    required this.carbsConsumed,
    required this.carbsGoal,
  });

  @override
  Widget build(BuildContext context) {
    final diff = caloriesConsumed - caloriesGoal;
    final isOver = diff > 0;
    
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: ThemeConstants.panelWhite,
        borderRadius: ThemeConstants.borderRadiusXXL,
        border: Border.all(color: ThemeConstants.glassBorderWeak),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Today's Nutrition Overview",
            style: ThemeConstants.subheadingStyle.copyWith(
              color: ThemeConstants.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${diff.abs()}',
                style: ThemeConstants.headingStyle.copyWith(
                  fontSize: 48,
                  color: ThemeConstants.textOnLight,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'kcal ${isOver ? "over" : "under"}',
                  style: ThemeConstants.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Burned $caloriesBurned',
            style: ThemeConstants.captionStyle.copyWith(
              color: ThemeConstants.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: (caloriesConsumed / caloriesGoal).clamp(0.0, 1.0),
            backgroundColor: ThemeConstants.glassBorderWeak,
            color: isOver ? ThemeConstants.uiError : ThemeConstants.accentGreen,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: MacroProgressBar(
                  label: 'Carbs',
                  current: carbsConsumed,
                  target: carbsGoal,
                  color: ThemeConstants.accentBlue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MacroProgressBar(
                  label: 'Protein',
                  current: proteinConsumed,
                  target: proteinGoal,
                  color: ThemeConstants.accentColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: MacroProgressBar(
                  label: 'Fat',
                  current: fatsConsumed,
                  target: fatsGoal,
                  color: ThemeConstants.uiWarning,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
