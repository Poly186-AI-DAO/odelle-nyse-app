import 'package:flutter/material.dart';
import '../../../constants/theme_constants.dart';
import '../../molecules/macro_pill_row.dart';

class DetailedFoodItemRow extends StatelessWidget {
  final String name;
  final String quantity;
  final int calories;
  final double protein;
  final double fats;
  final double carbs;
  final VoidCallback? onTap;

  const DetailedFoodItemRow({
    super.key,
    required this.name,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.fats,
    required this.carbs,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ThemeConstants.glassBorderWeak, width: 0.5),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: ThemeConstants.bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ThemeConstants.textOnLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      quantity,
                      style: ThemeConstants.captionStyle,
                    ),
                  ],
                ),
                Text(
                  '$calories',
                  style: ThemeConstants.headingStyle.copyWith(
                    fontSize: 16,
                    color: ThemeConstants.textOnLight,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: MacroPillRow(
                protein: protein,
                fats: fats,
                carbs: carbs,
                spacing: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
