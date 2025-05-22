import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:odelle_nyse/constants/colors.dart';
import 'package:odelle_nyse/models/cbt_model.dart';
import 'package:odelle_nyse/widgets/glassmorphism.dart';

class ThoughtEmotionBehaviorCard extends StatelessWidget {
  final ThoughtEmotionBehavior entry;

  const ThoughtEmotionBehaviorCard({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    return GlassMorphism(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "CBT Triangle",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Row(
                children: [
                  _CBTElement(
                    title: "Thought",
                    content: entry.thought,
                    color: AppColors.secondary,
                    icon: Icons.lightbulb_outline,
                  ),
                  _CBTElement(
                    title: "Emotion",
                    content: entry.emotion,
                    color: AppColors.accent1,
                    icon: Icons.favorite_border,
                  ),
                  _CBTElement(
                    title: "Behavior",
                    content: entry.behavior,
                    color: AppColors.primary,
                    icon: Icons.directions_walk,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(duration: 900.ms, curve: Curves.easeOutQuad)
      .slideY(begin: 0.2, end: 0, duration: 900.ms, curve: Curves.easeOutQuad);
  }
}

class _CBTElement extends StatelessWidget {
  final String title;
  final String content;
  final Color color;
  final IconData icon;

  const _CBTElement({
    required this.title,
    required this.content,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  content,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ).animate().fadeIn(
                    duration: 600.ms,
                    delay: 300.ms,
                    curve: Curves.easeOutQuad,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
