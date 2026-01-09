import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_constants.dart';

/// Modern glassmorphic design system constants
/// Voice-first, dynamic backgrounds, fluid animations
class DesignConstants {
  // Core Colors (Mapped to ThemeConstants - Glassmorphic)
  static const Color deepPurple = ThemeConstants.polyDeepPurple;
  static const Color pureWhite = ThemeConstants.polyWhite;
  static const Color softWhite = Color(0xFFF5F5F5);

  // Accent Colors (Modern Palette)
  static const Color accentPurple = ThemeConstants.polyPurple500;
  static const Color accentMint = ThemeConstants.polyMint400;
  static const Color accentPink = ThemeConstants.polyPink400;
  static const Color accentBlue = ThemeConstants.polyBlue500;
  static const Color accentGold = ThemeConstants.polyGold500;

  // Orbyte Colors
  static const Color orbytePurple = ThemeConstants.orbytePurple;
  static const Color orbyteOrange = ThemeConstants.orbyteOrange;
  static const Color orbyteBackground = ThemeConstants.orbyteDarkBg;

  // UI Element Colors
  static const Color successColor = ThemeConstants.uiSuccess;
  static const Color infoColor = ThemeConstants.uiInfo;
  static const Color warningColor = ThemeConstants.uiWarning;
  static const Color errorColor = ThemeConstants.uiError;
  static const Color mutedColor = ThemeConstants.uiMuted;

  // Spacing (Mobile Optimized)
  static const double spaceXS = ThemeConstants.spacingXS;
  static const double spaceS = ThemeConstants.spacingSmall;
  static const double spaceM = ThemeConstants.spacingMedium;
  static const double spaceL = ThemeConstants.spacingLarge;
  static const double spaceXL = ThemeConstants.spacingXLarge;
  static const double spaceXXL = ThemeConstants.spacingXXLarge;
  static const double spaceXXXL = ThemeConstants.spacingXXXLarge;

  // Typography Scales (Mobile Optimized for Readability)
  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0; // Body small
  static const double fontSizeM = 16.0; // Body default
  static const double fontSizeL = 20.0; // Subheading
  static const double fontSizeXL = 24.0; // Heading
  static const double fontSizeXXL = 32.0; // Display
  static const double fontSizeHero = 40.0; // Hero text

  // Font Weights
  static const FontWeight fontWeightLight = FontWeight.w300;
  static const FontWeight fontWeightRegular = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemiBold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;
  static const FontWeight fontWeightBlack = FontWeight.w900;

  // Animation Durations
  static const Duration durationFast = ThemeConstants.animationFast;
  static const Duration durationMedium = ThemeConstants.animationMedium;
  static const Duration durationSlow = ThemeConstants.animationSlow;
  static const Duration durationVerySlow = ThemeConstants.animationVerySlow;

  // Elevation (for shadows)
  static const double elevationSmall = 4.0;
  static const double elevationMedium = 8.0;
  static const double elevationLarge = 16.0;

  // Border Radius (Glassmorphic - rounded, not angular)
  static const double radiusNone = 0.0;
  static const double radiusSmall = ThemeConstants.radiusSmall;
  static const double radiusMedium = ThemeConstants.radiusMedium;
  static const double radiusLarge = ThemeConstants.radiusLarge;
  static const double radiusXL = ThemeConstants.radiusXL;
  static const double radiusXXL = ThemeConstants.radiusXXL;

  // Border Widths
  static const double borderThin = ThemeConstants.borderWidthThin;
  static const double borderMedium = ThemeConstants.borderWidth;
  static const double borderThick = ThemeConstants.borderWidthThick;

  // Opacity Levels
  static const double opacityDisabled = 0.38;
  static const double opacityLight = 0.54;
  static const double opacityMedium = 0.87;
  static const double opacityFull = 1.0;

  // Layout Constants
  static const double maxWidth = 600.0; // Mobile max width
  static const double minTouchTarget = 48.0; // Accessibility standard
  static const double iconSize = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeSmall = 16.0;
  static const double iconSizeHero = 48.0; // For large action buttons

  // Blur Constants for Glassmorphism
  static const double blurWeak = ThemeConstants.blurStrengthWeak;
  static const double blurMedium = ThemeConstants.blurStrength;
  static const double blurStrong = ThemeConstants.blurStrengthStrong;

  // Glow Effects (Glassmorphic)
  static List<BoxShadow> get softGlow => ThemeConstants.softGlow;
  static List<BoxShadow> get purpleGlow => ThemeConstants.purpleGlow;
  static List<BoxShadow> get mintGlow => ThemeConstants.mintGlow;
  static List<BoxShadow> get pinkGlow => ThemeConstants.pinkGlow;
  static List<BoxShadow> get goldGlow => ThemeConstants.goldGlow;
  static List<BoxShadow> get cardShadow => ThemeConstants.cardShadow;

  static List<Shadow> get textGlow => ThemeConstants.textGlow;
  static List<Shadow> get textMintGlow => ThemeConstants.textMintGlow;

  // Text Styles (Modern, Glassmorphic Design)
  // Display & Headings: Josefin Sans
  static TextStyle get displayL => GoogleFonts.josefinSans(
        fontSize: fontSizeHero,
        fontWeight: fontWeightBold,
        letterSpacing: -1.0,
        height: 1.1,
        color: pureWhite,
        shadows: textGlow,
      );

  static TextStyle get headingXL => GoogleFonts.josefinSans(
        fontSize: fontSizeXXL,
        fontWeight: fontWeightBold,
        letterSpacing: -0.5,
        height: 1.2,
        color: pureWhite,
      );

  static TextStyle get headingL => GoogleFonts.josefinSans(
        fontSize: fontSizeXL,
        fontWeight: fontWeightSemiBold,
        letterSpacing: -0.25,
        height: 1.3,
        color: pureWhite,
      );

  static TextStyle get headingM => GoogleFonts.josefinSans(
        fontSize: fontSizeL,
        fontWeight: fontWeightSemiBold,
        letterSpacing: 0,
        height: 1.3,
        color: pureWhite,
      );

  static TextStyle get headingS => GoogleFonts.josefinSans(
        fontSize: fontSizeS,
        fontWeight: fontWeightSemiBold,
        letterSpacing: 0,
        height: 1.3,
        color: pureWhite,
      );

  // Body Text: Lato
  static TextStyle get bodyL => GoogleFonts.lato(
        fontSize: fontSizeM,
        fontWeight: fontWeightRegular,
        letterSpacing: 0,
        height: 1.5,
        color: pureWhite,
      );

  static TextStyle get bodyM => GoogleFonts.lato(
        fontSize: fontSizeS,
        fontWeight: fontWeightRegular,
        letterSpacing: 0,
        height: 1.5,
        color: ThemeConstants.secondaryTextColor,
      );

  static TextStyle get bodyS => GoogleFonts.lato(
        fontSize: fontSizeXS,
        fontWeight: fontWeightRegular,
        letterSpacing: 0,
        height: 1.5,
        color: ThemeConstants.secondaryTextColor,
      );

  // Special Text Styles
  static TextStyle get buttonText => GoogleFonts.lato(
        fontSize: fontSizeM,
        fontWeight: fontWeightSemiBold,
        letterSpacing: 0.5,
        color: pureWhite,
      );

  static TextStyle get captionText => GoogleFonts.lato(
        fontSize: fontSizeXS,
        fontWeight: fontWeightRegular,
        letterSpacing: 0.3,
        color: ThemeConstants.mutedTextColor,
      );

  // Assets
  static const String defaultBackgroundImage =
      'https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?q=80&w=2574&auto=format&fit=crop';

  // Deprecated - keeping for backward compatibility
  static TextStyle get systemText => bodyM.copyWith(
        fontWeight: fontWeightMedium,
        color: successColor,
      );
}
