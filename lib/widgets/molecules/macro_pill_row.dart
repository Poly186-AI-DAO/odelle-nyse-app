import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';
import '../atoms/macro_pill.dart';

class MacroPillRow extends StatelessWidget {
  final double? protein;
  final double? fats;
  final double? carbs;
  final double spacing;

  const MacroPillRow({
    super.key,
    this.protein,
    this.fats,
    this.carbs,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        if (protein != null)
          MacroPill(
            label: 'P',
            value: protein!.toStringAsFixed(1),
            color: ThemeConstants.accentColor,
          ),
        if (fats != null)
          MacroPill(
            label: 'F',
            value: fats!.toStringAsFixed(1),
            color: ThemeConstants.uiWarning,
          ),
        if (carbs != null)
          MacroPill(
            label: 'C',
            value: carbs!.toStringAsFixed(1),
            color: ThemeConstants.accentBlue,
          ),
      ],
    );
  }
}
