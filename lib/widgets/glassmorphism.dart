import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:odelle_nyse/constants/colors.dart';

class GlassMorphism extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color color;
  final BorderRadius? borderRadius;
  final double borderWidth;
  final Color? borderColor;

  const GlassMorphism({
    super.key,
    required this.child,
    this.blur = 20,
    this.opacity = 0.18,
    this.color = AppColors.background,
    this.borderRadius,
    this.borderWidth = 1.5,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color.withAlpha((opacity * 255).round()),
            borderRadius: borderRadius ?? BorderRadius.circular(24),
            border: Border.all(
              color: borderColor ?? Colors.white.withAlpha((0.22 * 255).round()),
              width: borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha((0.08 * 255).round()),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
