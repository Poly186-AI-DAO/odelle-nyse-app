import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/theme_constants.dart';

enum OdelleButtonVariant {
  primary,
  secondary,
  ghost,
}

enum OdelleButtonSize {
  small,
  medium,
  large,
}

class OdelleButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final OdelleButtonVariant variant;
  final OdelleButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const OdelleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = OdelleButtonVariant.primary,
    this.size = OdelleButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _getHeight(),
      child: Container(
        decoration: _getDecoration(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: _getPadding(),
              child: _buildContent(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getTextColor()),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: _getIconSize(),
            color: _getTextColor(),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w600,
            color: _getTextColor(),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  double _getHeight() {
    switch (size) {
      case OdelleButtonSize.small:
        return 36;
      case OdelleButtonSize.medium:
        return 48;
      case OdelleButtonSize.large:
        return 56;
    }
  }

  double _getFontSize() {
    switch (size) {
      case OdelleButtonSize.small:
        return 13;
      case OdelleButtonSize.medium:
        return 15;
      case OdelleButtonSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (size) {
      case OdelleButtonSize.small:
        return 16;
      case OdelleButtonSize.medium:
        return 20;
      case OdelleButtonSize.large:
        return 24;
    }
  }

  EdgeInsets _getPadding() {
    switch (size) {
      case OdelleButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16);
      case OdelleButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24);
      case OdelleButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32);
    }
  }

  BoxDecoration? _getDecoration() {
    if (variant == OdelleButtonVariant.ghost) return null;

    if (variant == OdelleButtonVariant.secondary) {
      return BoxDecoration(
        color: ThemeConstants.glassBackground, // Glassy
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2), // Subtle border
          width: 1,
        ),
      );
    }

    // Primary
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: const LinearGradient(
        colors: [
           Color(0xFF9D4EDD), // Poly Purple
           Color(0xFFFF6B35), // Poly Orange Accent
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF9D4EDD).withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Color _getTextColor() {
    return Colors.white; // Always white for dark theme
  }
}

/// Full-width variant of OdelleButton for CTAs
class OdelleButtonFullWidth extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color backgroundColor;
  final Color textColor;

  const OdelleButtonFullWidth({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.backgroundColor = const Color(0xFF9D4EDD), // Poly Purple
    this.textColor = Colors.white,
  });

  /// Dark navy CTA button
  const OdelleButtonFullWidth.dark({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  })  : backgroundColor = const Color(0xFF0A1628), // deepNavy
        textColor = Colors.white;

  /// Orange accent CTA button
  const OdelleButtonFullWidth.accent({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  })  : backgroundColor = const Color(0xFFFF6B35), // Poly Orange
        textColor = Colors.white;

  /// Primary purple CTA button
  const OdelleButtonFullWidth.primary({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  })  : backgroundColor = const Color(0xFF9D4EDD), // Poly Purple
        textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
