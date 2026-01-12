import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';

enum TagVariant { filled, outline }

class Tag extends StatelessWidget {
  final String text;
  final Color? color;
  final TagVariant variant;
  final double fontSize;
  final EdgeInsets padding;

  const Tag({
    super.key,
    required this.text,
    this.color,
    this.variant = TagVariant.filled,
    this.fontSize = 10.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? ThemeConstants.steelBlue;
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: variant == TagVariant.filled 
            ? effectiveColor.withValues(alpha: 0.1) 
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4.0),
        border: variant == TagVariant.outline
            ? Border.all(color: effectiveColor.withValues(alpha: 0.3))
            : null,
      ),
      child: Text(
        text.toUpperCase(),
        style: ThemeConstants.captionStyle.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: effectiveColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
