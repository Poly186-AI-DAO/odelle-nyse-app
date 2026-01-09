import 'dart:ui';
import 'package:flutter/material.dart';
import '../../constants/theme_constants.dart';
import '../../constants/design_constants.dart';

/// A glassmorphic card with backdrop blur effect
///
/// Features:
/// - Configurable blur strength
/// - Rounded corners (not oval)
/// - Subtle gradient overlays
/// - Optional glow effect
/// - Customizable padding and dimensions
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double blurStrength;
  final bool enableGlow;
  final List<BoxShadow>? customShadow;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.borderRadius = DesignConstants.radiusMedium,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = ThemeConstants.borderWidth,
    this.blurStrength = ThemeConstants.blurStrength,
    this.enableGlow = false,
    this.customShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: customShadow ??
            (enableGlow ? ThemeConstants.softGlow : ThemeConstants.cardShadow),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: blurStrength,
            sigmaY: blurStrength,
          ),
          child: Container(
            padding: padding ?? ThemeConstants.paddingMedium,
            decoration: BoxDecoration(
              color: backgroundColor ?? ThemeConstants.glassBackground,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: borderColor ?? ThemeConstants.glassBorder,
                width: borderWidth,
              ),
              gradient: gradient ?? ThemeConstants.glassGradient,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// A glassmorphic panel with extra strong blur for prominent sections
class GlassPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? width;
  final double? height;

  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: padding ?? ThemeConstants.paddingLarge,
      width: width,
      height: height,
      borderRadius: DesignConstants.radiusXXL,
      backgroundColor: ThemeConstants.glassBackgroundStrong,
      borderColor: ThemeConstants.glassBorderStrong,
      blurStrength: ThemeConstants.blurStrengthStrong,
      enableGlow: true,
      child: child,
    );
  }
}

/// A glassmorphic card optimized for bottom sheets
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool showHandle;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.padding,
    this.showHandle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: ThemeConstants.borderRadiusBottomSheet,
        boxShadow: ThemeConstants.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: ThemeConstants.borderRadiusBottomSheet,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: ThemeConstants.blurStrengthStrong,
            sigmaY: ThemeConstants.blurStrengthStrong,
          ),
          child: Container(
            padding: padding ?? ThemeConstants.paddingLarge,
            decoration: BoxDecoration(
              color: ThemeConstants.glassBackgroundStrong,
              borderRadius: ThemeConstants.borderRadiusBottomSheet,
              border: Border(
                top: BorderSide(
                  color: ThemeConstants.glassBorderStrong,
                  width: ThemeConstants.borderWidth,
                ),
                left: BorderSide(
                  color: ThemeConstants.glassBorderStrong,
                  width: ThemeConstants.borderWidth,
                ),
                right: BorderSide(
                  color: ThemeConstants.glassBorderStrong,
                  width: ThemeConstants.borderWidth,
                ),
              ),
              gradient: ThemeConstants.glassGradient,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showHandle)
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(
                        bottom: ThemeConstants.spacingMedium),
                    decoration: BoxDecoration(
                      color: ThemeConstants.mutedTextColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
