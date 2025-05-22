import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:odelle_nyse/constants/colors.dart';
import 'package:odelle_nyse/models/journey_model.dart';
import 'package:odelle_nyse/widgets/glassmorphism.dart';

class HeroJourneyCard extends StatelessWidget {
  final HeroJourney journey;

  const HeroJourneyCard({
    super.key,
    required this.journey,
  });

  @override
  Widget build(BuildContext context) {
    final currentStage = journey.stages[journey.currentStageIndex];
    return GlassMorphism(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 180, // Increased height to fix overflow
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Hero's Journey",
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
                    "Stage ${currentStage.step} of ${journey.stages.length}",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              currentStage.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              currentStage.description,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Current Progress',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      '${(currentStage.progress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _AnimatedProgressBar(
                  progress: currentStage.progress,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Overall Journey',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    Text(
                      '${(journey.overallProgress * 100).toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                _AnimatedProgressBar(
                  progress: journey.overallProgress,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 600.ms, curve: Curves.easeOutQuad)
      .slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutQuad);
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  final double progress;
  final Color color;

  const _AnimatedProgressBar({
    required this.progress,
    this.color = AppColors.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            width: MediaQuery.of(context).size.width * progress * 0.75, // Account for padding
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.7),
                  color,
                ],
              ),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ).animate().fadeIn(
                duration: 1000.ms,
                delay: 300.ms,
                curve: Curves.easeOutQuad,
              ),
          if (progress < 1.0)
            Flexible(
              flex: ((1.0 - progress) * 100).toInt(),
              child: Container(),
            ),
        ],
      ),
    );
  }
}
