import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:odelle_nyse/constants/colors.dart';
import 'package:odelle_nyse/models/affirmation_model.dart';
import 'package:odelle_nyse/widgets/glassmorphism.dart';

class DailyAffirmationCard extends StatelessWidget {
  final Affirmation affirmation;

  const DailyAffirmationCard({
    super.key,
    required this.affirmation,
  });

  @override
  Widget build(BuildContext context) {
    return GlassMorphism(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 130, // Increased height to fix overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Daily Affirmation",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    affirmation.theme.toUpperCase(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _AnimatedAffirmationText(
                text: affirmation.text,
              ),
            ),
            const Spacer(),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "~ ${affirmation.author}",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 700.ms, curve: Curves.easeOutQuad)
      .slideY(begin: 0.2, end: 0, duration: 700.ms, curve: Curves.easeOutQuad);
  }
}

class _AnimatedAffirmationText extends StatelessWidget {
  final String text;

  const _AnimatedAffirmationText({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
      textAlign: TextAlign.center,
    ).animate()
      .fadeIn(duration: 800.ms, curve: Curves.easeOutQuad)
      .scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1, 1),
        duration: 800.ms,
        curve: Curves.easeOutQuad,
      );
  }
}
