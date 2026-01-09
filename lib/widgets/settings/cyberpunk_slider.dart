import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';

class CyberpunkSlider extends StatelessWidget {
  final String label;
  final String? description;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String Function(double) valueLabel;
  final Function(double) onChanged;

  const CyberpunkSlider({
    super.key,
    required this.label,
    this.description,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: ThemeConstants.spacingMedium,
        vertical: ThemeConstants.spacingSmall,
      ),
      padding: const EdgeInsets.all(ThemeConstants.spacingMedium),
      decoration: BoxDecoration(
        border: Border.all(
          color: ThemeConstants.borderColor,
          width: ThemeConstants.borderWidth,
        ),
        color: Colors.black87,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.pressStart2p(
                  color: ThemeConstants.secondaryTextColor,
                  fontSize: 12,
                ),
              ),
              Text(
                valueLabel(value),
                style: GoogleFonts.pressStart2p(
                  color: ThemeConstants.primaryColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          if (description != null) ...[
            const SizedBox(height: ThemeConstants.spacingSmall),
            Text(
              description!,
              style: GoogleFonts.pressStart2p(
                color: ThemeConstants.secondaryTextColor.withOpacity(0.7),
                fontSize: 8,
              ),
            ),
          ],
          const SizedBox(height: ThemeConstants.spacingMedium),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: ThemeConstants.primaryColor,
              inactiveTrackColor: ThemeConstants.borderColor,
              thumbColor: ThemeConstants.primaryColor,
              overlayColor: ThemeConstants.primaryColor.withOpacity(0.2),
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 6,
              ),
              overlayShape: const RoundSliderOverlayShape(
                overlayRadius: 12,
              ),
            ),
            child: Slider(
              value: value,
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
