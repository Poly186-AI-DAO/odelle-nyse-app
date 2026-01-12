import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/theme_constants.dart';
import '../../../models/tracking/meal_log.dart';

/// Rich meal card with photo, overlaid title, and stats.
/// Based on the reference design showing meal cards with food images.
class MealCard extends StatelessWidget {
  final MealLog meal;
  final VoidCallback? onTap;
  final String? timeUntil;

  const MealCard({
    super.key,
    required this.meal,
    this.onTap,
    this.timeUntil,
  });

  @override
  Widget build(BuildContext context) {
    final time = _formatTime(meal.timestamp);
    final mealType = meal.type.displayName;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Time + Meal Type + "in Xh Xm"
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: ThemeConstants.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      mealType,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeConstants.textOnLight,
                      ),
                    ),
                  ],
                ),
                if (timeUntil != null)
                  Text(
                    timeUntil!,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
              ],
            ),
          ),

          // Photo card with overlaid title
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF5F5F5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo or placeholder
                  if (meal.photoPath != null)
                    Image.asset(
                      meal.photoPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  else
                    _buildPlaceholder(),

                  // Gradient overlay at bottom
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Title overlay
                  Positioned(
                    left: 16,
                    right: 50,
                    bottom: 16,
                    child: Text(
                      _buildTitle(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  // Arrow icon
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Stats row below card
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Row(
              children: [
                if (meal.calories != null) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6B35),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${meal.calories} kcal',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                ],
                if (meal.proteinGrams != null) ...[
                  const SizedBox(width: 16),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${meal.proteinGrams}g protein',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ThemeConstants.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFE8E8E8),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getMealEmoji(),
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 8),
            Text(
              meal.type.displayName,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ThemeConstants.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMealEmoji() {
    switch (meal.type) {
      case MealType.breakfast:
        return '🍳';
      case MealType.lunch:
        return '🥗';
      case MealType.dinner:
        return '🥩';
      case MealType.snack:
        return '🍎';
      case MealType.preworkout:
        return '⚡';
      case MealType.postworkout:
        return '💪';
      case MealType.other:
        return '🍽️';
    }
  }

  String _buildTitle() {
    // If we have a description, use it as title
    if (meal.description != null && meal.description!.isNotEmpty) {
      return meal.description!;
    }
    // Otherwise use meal type
    return meal.type.displayName;
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
