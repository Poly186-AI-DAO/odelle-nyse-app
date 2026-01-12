import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

class MacroPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final double fontSize;

  const MacroPill({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.fontSize = 11.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: fontSize * 0.9,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: ThemeConstants.captionStyle.copyWith(
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
