import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/design_constants.dart';

class GlassCardModern extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blurStrength;
  final Color? backgroundColor;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool showGlow;

  const GlassCardModern({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = DesignConstants.radiusLarge,
    this.blurStrength = DesignConstants.blurMedium,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.onTap,
    this.showGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(DesignConstants.spaceM),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color:
            backgroundColor, // Allow override, but default to null to use gradient
        gradient: gradient ??
            LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.05),
              ],
            ),
        border: Border.all(
          color: Colors
              .transparent, // Use transparent border to allow gradient border if we implemented it, but for now standard border
          width: 0,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ?? Colors.white.withOpacity(0.2),
            width: 1.0,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.transparent,
            ],
            stops: const [0.0, 0.4],
          ),
        ),
        child: child,
      ),
    );

    // Apply blur effect
    Widget glassEffect = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
        child: cardContent,
      ),
    );

    if (margin != null) {
      glassEffect = Padding(padding: margin!, child: glassEffect);
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: glassEffect,
      );
    }

    return glassEffect;
  }
}
