import 'package:flutter/material.dart';

class ThemeConstants {
  // =========================================================
  // ODELLE NYSE DESIGN SYSTEM
  // Voice-first, minimal fintech aesthetic
  // Conversational UI with two-tone layout
  // =========================================================

  // ---- Fintech Palette (Primary) --------------------------------------
  // Dark gradient backgrounds - calming blue to silver
  static const Color deepNavy = Color(0xFF0A1628);
  static const Color darkTeal = Color(0xFF1E3A5F);
  static const Color steelBlue = Color(0xFF4A6B7C);
  static const Color calmSilver = Color(0xFF7A8B9A);
  static const Color softSilver = Color(0xFF9EAAB6);
  static const Color warmSilver = Color(0xFFB8C0C8);

  // Legacy warm tones (for other screens)
  static const Color warmTaupe = Color(0xFF8B7355);
  static const Color sunsetGold = Color(0xFFC4A574);

  // Voice/Conversation gradient - calm and peaceful
  static const Color darkSlate = Color(0xFF2D3E50);
  static const Color coolGray = Color(0xFF5A6B7A);
  static const Color mistGray = Color(0xFF8E9EAD);

  // Surface colors
  static const Color panelWhite = Color(0xFFFFFFFF);
  static const Color panelCream = Color(0xFFF8F6F3);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnLight = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Accent colors
  static const Color accentGreen = Color(0xFF22C55E);
  static const Color accentBlue = Color(0xFF3B82F6);

  // ---- Legacy Palette (Backward Compatibility) ------------------------
  static const Color polyPurple500 = Color(0xFF8200FF);
  static const Color polyPurple600 = Color(0xFFDC00FF);
  static const Color polyPurple700 = Color(0xFF4D0097);
  static const Color polyPurple300 = Color(0xFFB366FF);
  static const Color polyPurple200 = Color(0xFFD9B3FF);

  static const Color polyBlue500 = Color(0xFF4024FB);
  static const Color polyBlue400 = Color(0xFF6D5AFE);
  static const Color polyBlue300 = Color(0xFF9A8FFE);

  static const Color polyPink500 = Color(0xFFFF006E);
  static const Color polyPink400 = Color(0xFFFF4D9F);
  static const Color polyPink300 = Color(0xFFFF99CC);

  static const Color polyMint400 = Color(0xFFA8FEDA);
  static const Color polyMint300 = Color(0xFFC4FEEA);

  static const Color polyGold500 = Color(0xFFFFD700);

  static const Color polyWhite = Color(0xFFFFFFFF);
  static const Color polyBlack = Color(0xFF000000);
  static const Color polyDeepPurple = Color(0xFF1A0033);

  // Orbyte (deprecated - use fintech palette)
  static const Color orbytePurple = Color(0xFF8B5CF6);
  static const Color orbyteOrange = Color(0xFFF97316);
  static const Color orbyteDarkBg = Color(0xFF0F0F1A);
  static const Color orbyteCardBg = Color(0xFF1E1E2E);
  static const Color orbyteTextPrimary = Color(0xFFFFFFFF);
  static const Color orbyteTextSecondary = Color(0xFF94A3B8);

  // ---- Social Platform Colors -----------------------------------------
  static const Color polyFacebook = Color(0xFF1877F2);
  static const Color polyInstagram = Color(0xFFE1306C);
  static const Color polyWhatsapp = Color(0xFF25D366);

  // ---- Glassmorphic Surfaces ------------------------------------------
  // Semi-transparent surfaces for glass effect
  static const Color glassBackground = Color(0x26FFFFFF); // 15% white
  static const Color glassBackgroundStrong = Color(0x40FFFFFF); // 25% white
  static const Color glassBackgroundWeak = Color(0x0DFFFFFF); // 5% white

  // Glass borders
  static const Color glassBorder = Color(0x33FFFFFF); // 20% white
  static const Color glassBorderStrong = Color(0x4DFFFFFF); // 30% white
  static const Color glassBorderWeak = Color(0x1AFFFFFF); // 10% white

  // ---- Semantic Colors ------------------------------------------------
  static const Color uiSuccess = Color(0xFF22C55E);
  static const Color uiInfo = Color(0xFF3B82F6);
  static const Color uiError = Color(0xFFEF4444);
  static const Color uiWarning = Color(0xFFF59E0B);
  static const Color uiMuted = Color(0xFF9CA3AF);

  // ---- Primary Colors (Fintech Design) --------------------------------
  static const Color primaryColorConst = accentBlue;
  static const Color accentColorConst = accentGreen;
  static const Color secondaryAccentConst = steelBlue;

  static const Color textColorConst = polyWhite;
  static const Color secondaryTextColorConst = Color(0xB3FFFFFF); // white70
  static const Color mutedTextColorConst = Color(0x80FFFFFF); // white50

  // Getters for backward compatibility
  static Color get primaryColor => primaryColorConst;
  static Color get accentColor => accentColorConst;
  static Color get secondaryAccent => secondaryAccentConst;
  static Color get errorColor => uiError;
  static Color get textColor => textColorConst;
  static Color get secondaryTextColor => secondaryTextColorConst;
  static Color get mutedTextColor => mutedTextColorConst;

  // Glass surface getters
  static Color get surfaceColor => glassBackground;
  static Color get backgroundColor => deepNavy; // Fintech dark background
  static Color get borderColor => glassBorder;
  static Color get primaryContainer => glassBackgroundStrong;
  static Color get errorContainer =>
      Color(0x33EF4444); // Error with transparency

  // ---- Spacing (Mobile Optimized) -------------------------------------
  // Touch targets min 48px for accessibility
  static const double spacingXS = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  static const double spacingXXLarge = 48.0;
  static const double spacingXXXLarge = 64.0;

  // ---- Padding --------------------------------------------------------
  static const EdgeInsets paddingXS = EdgeInsets.all(4.0);
  static const EdgeInsets paddingSmall = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMedium = EdgeInsets.all(16.0);
  static const EdgeInsets paddingLarge = EdgeInsets.all(24.0);
  static const EdgeInsets paddingXL = EdgeInsets.all(32.0);

  // Screen padding
  static const EdgeInsets paddingScreen =
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0);
  static const EdgeInsets paddingCard =
      EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0);
  static const EdgeInsets paddingButton =
      EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0);

  // ---- Borders & Radii ------------------------------------------------
  static const double borderWidth = 1.0;
  static const double borderWidthThin = 0.5;
  static const double borderWidthThick = 2.0;

  // Border Radii (Glassmorphic - rounded but not oval)
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusXL = 28.0;
  static const double radiusXXL = 36.0;
  static const double radiusCircle = 9999.0; // For circular elements

  static BorderRadius get borderRadius => BorderRadius.circular(radiusMedium);
  static BorderRadius get borderRadiusSmall =>
      BorderRadius.circular(radiusSmall);
  static BorderRadius get borderRadiusLarge =>
      BorderRadius.circular(radiusLarge);
  static BorderRadius get borderRadiusXL => BorderRadius.circular(radiusXL);
  static BorderRadius get borderRadiusXXL => BorderRadius.circular(radiusXXL);

  // Specific corner radii for bottom sheets
  static BorderRadius get borderRadiusBottomSheet => const BorderRadius.only(
        topLeft: Radius.circular(radiusXXL),
        topRight: Radius.circular(radiusXXL),
      );

  // ---- Gradients ------------------------------------------------------
  // Fintech gradients (Primary)
  static LinearGradient get fintechDarkGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          deepNavy,
          darkTeal,
          steelBlue,
        ],
        stops: [0.0, 0.5, 1.0],
      );

  // Calming voice gradient - deep navy to soft silver
  static LinearGradient get fintechFullGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          deepNavy,
          darkTeal,
          steelBlue,
          calmSilver,
          softSilver,
        ],
        stops: [0.0, 0.25, 0.5, 0.75, 1.0],
      );

  // Voice screen gradient - calm and peaceful
  static LinearGradient get voiceGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          deepNavy,
          darkTeal,
          steelBlue,
          calmSilver,
        ],
        stops: [0.0, 0.35, 0.7, 1.0],
      );

  // Background for Voice Screen (Light Silver)
  // Provides contrast for the dark "Hero Card"
  static LinearGradient get voiceBackgroundGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE2E8F0), // Light Silver
          Color(0xFFCBD5E1), // Slightly darker silver
        ],
      );

  // Legacy gradients (backward compatibility)
  static LinearGradient get loginGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2E004F), // Deepest Purple
          Color(0xFF000000), // Black
        ],
        stops: [0.0, 1.0],
      );

  static LinearGradient get chatGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1A0033), // Deep Purple
          Color(0xFF050505), // Almost Black
          Colors.black,
        ],
        stops: [0.0, 0.5, 1.0],
      );

  static LinearGradient get workersGradient => const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          polyBlue500,
          polyPurple500,
          polyDeepPurple,
        ],
        stops: [0.0, 0.6, 1.0],
      );

  static LinearGradient get tasksGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          polyPink500,
          polyPurple600,
          polyDeepPurple,
        ],
        stops: [0.0, 0.5, 1.0],
      );

  // Accent gradients for overlays
  static LinearGradient get glassGradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          polyWhite.withValues(alpha: 0.15),
          polyWhite.withValues(alpha: 0.05),
        ],
      );

  static LinearGradient get accentGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [polyMint400, polyBlue400],
      );

  static LinearGradient get buttonGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [polyPurple500, polyPurple600],
      );

  // Orbyte Gradients
  static LinearGradient get orbytePrimaryGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF8B5CF6), // Purple
          Color(0xFFF97316), // Orange
        ],
      );

  static LinearGradient get orbyteDarkGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF1E1E2E),
          Color(0xFF0F0F1A),
        ],
      );

  // ---- Decorations ----------------------------------------------------
  // Glassmorphic decorations
  static BoxDecoration get glassDecoration => BoxDecoration(
        color: glassBackground,
        borderRadius: borderRadius,
        border: Border.all(
          color: glassBorder,
          width: borderWidth,
        ),
      );

  static BoxDecoration get glassDecorationStrong => BoxDecoration(
        color: glassBackgroundStrong,
        borderRadius: borderRadius,
        border: Border.all(
          color: glassBorderStrong,
          width: borderWidth,
        ),
      );

  static BoxDecoration get primaryContainerDecoration => BoxDecoration(
        color: glassBackgroundStrong,
        borderRadius: borderRadius,
        border: Border.all(
          color: glassBorderStrong,
          width: borderWidth,
        ),
      );

  static BoxDecoration get glassPanelDecoration => BoxDecoration(
        color: glassBackground,
        borderRadius: borderRadiusXXL,
        border: Border.all(
          color: glassBorderStrong,
          width: borderWidth,
        ),
      );

  // Error container decoration
  static BoxDecoration get errorContainerDecoration => BoxDecoration(
        color: Color(0x33EF4444),
        borderRadius: borderRadius,
        border: Border.all(
          color: uiError,
          width: borderWidth,
        ),
      );

  // Legacy alias for backward compatibility
  static BoxDecoration get containerDecoration => primaryContainerDecoration;

  // ---- Effects --------------------------------------------------------
  // Soft glows for glassmorphic design
  static List<BoxShadow> get softGlow => [
        BoxShadow(
          color: polyPurple500.withValues(alpha: 0.2),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get glowShadow => [
        BoxShadow(
          color: polyPurple600.withValues(alpha: 0.3),
          blurRadius: 25,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get purpleGlow => [
        BoxShadow(
          color: polyPurple600.withValues(alpha: 0.4),
          blurRadius: 30,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get mintGlow => [
        BoxShadow(
          color: polyMint400.withValues(alpha: 0.3),
          blurRadius: 25,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get pinkGlow => [
        BoxShadow(
          color: polyPink400.withValues(alpha: 0.3),
          blurRadius: 25,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: polyGold500.withValues(alpha: 0.3),
          blurRadius: 25,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get errorGlowShadow => [
        BoxShadow(
          color: uiError.withValues(alpha: 0.4),
          blurRadius: 25,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: polyBlack.withValues(alpha: 0.3),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
      ];

  static List<Shadow> get textGlow => [
        Shadow(
          color: polyPurple600.withValues(alpha: 0.6),
          blurRadius: 12,
          offset: const Offset(0, 0),
        ),
      ];

  static List<Shadow> get textMintGlow => [
        Shadow(
          color: polyMint400.withValues(alpha: 0.6),
          blurRadius: 12,
          offset: const Offset(0, 0),
        ),
      ];

  // ---- Text Styles (Base) ---------------------------------------------
  // Modern, readable typography
  static const TextStyle headingStyle = TextStyle(
    color: textColorConst,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
  );

  static const TextStyle subheadingStyle = TextStyle(
    color: secondaryTextColorConst,
    fontSize: 18,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyStyle = TextStyle(
    color: textColorConst,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    color: textColorConst,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const TextStyle captionStyle = TextStyle(
    color: mutedTextColorConst,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  // ---- Button Styles --------------------------------------------------
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: polyPurple500,
        foregroundColor: polyWhite,
        padding: paddingButton,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ).copyWith(
        overlayColor: WidgetStateProperty.all(polyWhite.withValues(alpha: 0.1)),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: glassBackground,
        foregroundColor: polyWhite,
        padding: paddingButton,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius,
          side: BorderSide(color: glassBorderStrong, width: borderWidth),
        ),
        elevation: 0,
        shadowColor: Colors.transparent,
      ).copyWith(
        overlayColor:
            WidgetStateProperty.all(polyWhite.withValues(alpha: 0.05)),
      );

  // ---- Input Decoration -----------------------------------------------
  static InputDecoration get glassInputDecoration => InputDecoration(
        filled: true,
        fillColor: glassBackground,
        hintStyle: TextStyle(color: mutedTextColor),
        contentPadding: paddingMedium,
        enabledBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: glassBorder, width: borderWidth),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide:
              BorderSide(color: glassBorderStrong, width: borderWidthThick),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: uiError, width: borderWidth),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: borderRadius,
          borderSide: BorderSide(color: uiError, width: borderWidthThick),
        ),
      );

  // Deprecated - keeping for backward compatibility
  static InputDecoration get underlinedInputDecoration => glassInputDecoration;

  // ---- Animation Durations --------------------------------------------
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  static const Duration animationVerySlow = Duration(milliseconds: 800);

  // ---- Blur Constants -------------------------------------------------
  static const double blurStrength = 25.0;
  static const double blurStrengthStrong = 40.0;
  static const double blurStrengthWeak = 5.0;
}
