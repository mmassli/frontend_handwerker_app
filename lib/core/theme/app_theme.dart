import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Handwerker Design System
/// Industrial-craft aesthetic: dark slate foundations, warm amber tooling accents,
/// concrete textures, and sharp geometric precision.
class AppTheme {
  AppTheme._();

  // ── Brand Colors ──────────────────────────────────────────
  static const Color amber = Color(0xFFE8A917);
  static const Color amberLight = Color(0xFFF5CC5A);
  static const Color amberDark = Color(0xFFB8850F);

  static const Color slate900 = Color(0xFF0F1419);
  static const Color slate800 = Color(0xFF1A1F2E);
  static const Color slate700 = Color(0xFF252B3B);
  static const Color slate600 = Color(0xFF343B4F);
  static const Color slate500 = Color(0xFF4A5168);
  static const Color slate400 = Color(0xFF6B7280);
  static const Color slate300 = Color(0xFF9CA3AF);
  static const Color slate200 = Color(0xFFD1D5DB);
  static const Color slate100 = Color(0xFFF3F4F6);

  static const Color success = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color warning = Color(0xFFFBBF24);
  static const Color info = Color(0xFF60A5FA);

  // ── Surface Colors ────────────────────────────────────────
  static const Color surfaceDark = Color(0xFF0F1419);
  static const Color surfaceCard = Color(0xFF1A1F2E);
  static const Color surfaceElevated = Color(0xFF252B3B);
  static const Color surfaceOverlay = Color(0x99000000);

  // Light theme surfaces
  static const Color surfaceLight = Color(0xFFF8F7F4);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color surfaceElevatedLight = Color(0xFFF0EDE8);

  // ── Typography ────────────────────────────────────────────
  static const String displayFont = 'Roboto';
  static const String bodyFont = 'Roboto';

  // ── Spacing ───────────────────────────────────────────────
  static const double spacingXS = 4;
  static const double spacingSM = 8;
  static const double spacingMD = 16;
  static const double spacingLG = 24;
  static const double spacingXL = 32;
  static const double spacing2XL = 48;
  static const double spacing3XL = 64;

  // ── Radius ────────────────────────────────────────────────
  static const double radiusSM = 8;
  static const double radiusMD = 12;
  static const double radiusLG = 16;
  static const double radiusXL = 24;
  static const double radiusFull = 999;

  // ── Elevation ─────────────────────────────────────────────
  static List<BoxShadow> get shadowSM => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMD => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLG => [
        BoxShadow(
          color: Colors.black.withOpacity(0.16),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get glowAmber => [
        BoxShadow(
          color: amber.withOpacity(0.3),
          blurRadius: 20,
          spreadRadius: -4,
        ),
      ];

  // ── Dark Theme ────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: bodyFont,
      scaffoldBackgroundColor: surfaceDark,
      colorScheme: const ColorScheme.dark(
        primary: amber,
        onPrimary: slate900,
        secondary: amberLight,
        onSecondary: slate900,
        surface: surfaceCard,
        onSurface: slate100,
        error: error,
        onError: Colors.white,
        outline: slate600,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontFamily: displayFont,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: slate100,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: slate200),
      ),
      textTheme: _buildTextTheme(isDark: true),
      inputDecorationTheme: _buildInputDecoration(isDark: true),
      elevatedButtonTheme: _buildElevatedButton(),
      outlinedButtonTheme: _buildOutlinedButton(),
      textButtonTheme: _buildTextButton(),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: BorderSide(color: slate700.withOpacity(0.5)),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: amber,
        unselectedItemColor: slate500,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: slate700,
        selectedColor: amber.withOpacity(0.15),
        labelStyle: const TextStyle(
          fontFamily: bodyFont,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: slate200,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSM),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      dividerTheme: const DividerThemeData(
        color: slate700,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceElevated,
        contentTextStyle: const TextStyle(
          fontFamily: bodyFont,
          color: slate100,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: bodyFont,
      scaffoldBackgroundColor: surfaceLight,
      colorScheme: const ColorScheme.light(
        primary: amberDark,
        onPrimary: Colors.white,
        secondary: amber,
        onSecondary: slate900,
        surface: surfaceCardLight,
        onSurface: slate900,
        error: errorDark,
        onError: Colors.white,
        outline: slate300,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: TextStyle(
          fontFamily: displayFont,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: slate900,
          letterSpacing: -0.5,
        ),
        iconTheme: IconThemeData(color: slate800),
      ),
      textTheme: _buildTextTheme(isDark: false),
      inputDecorationTheme: _buildInputDecoration(isDark: false),
      elevatedButtonTheme: _buildElevatedButton(),
      outlinedButtonTheme: _buildOutlinedButton(),
      textButtonTheme: _buildTextButton(),
      cardTheme: CardThemeData(
        color: surfaceCardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLG),
          side: BorderSide(color: slate200.withOpacity(0.6)),
        ),
        margin: EdgeInsets.zero,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceCardLight,
        selectedItemColor: amberDark,
        unselectedItemColor: slate400,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      dividerTheme: const DividerThemeData(
        color: slate200,
        thickness: 1,
        space: 1,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceCardLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radiusXL)),
        ),
      ),
    );
  }

  // ── Text Theme ────────────────────────────────────────────
  static TextTheme _buildTextTheme({required bool isDark}) {
    final Color primary = isDark ? slate100 : slate900;
    final Color secondary = isDark ? slate300 : slate500;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 40,
        fontWeight: FontWeight.w900,
        color: primary,
        letterSpacing: -1.5,
        height: 1.1,
      ),
      displayMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -1.0,
        height: 1.15,
      ),
      displaySmall: TextStyle(
        fontFamily: displayFont,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.5,
        height: 1.2,
      ),
      headlineLarge: TextStyle(
        fontFamily: displayFont,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -0.3,
      ),
      headlineMedium: TextStyle(
        fontFamily: displayFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: displayFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.5,
      ),
      bodySmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
        height: 1.4,
      ),
      labelLarge: TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primary,
        letterSpacing: 0.3,
      ),
      labelMedium: TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.3,
      ),
      labelSmall: TextStyle(
        fontFamily: bodyFont,
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 0.5,
        textBaseline: TextBaseline.alphabetic,
      ),
    );
  }

  // ── Input Decoration ──────────────────────────────────────
  static InputDecorationTheme _buildInputDecoration({required bool isDark}) {
    final fillColor = isDark ? slate800 : surfaceElevatedLight;
    final borderColor = isDark ? slate600 : slate300;

    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: BorderSide(color: borderColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: amber, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMD),
        borderSide: const BorderSide(color: error),
      ),
      hintStyle: TextStyle(
        fontFamily: bodyFont,
        color: isDark ? slate500 : slate400,
        fontSize: 14,
      ),
      labelStyle: TextStyle(
        fontFamily: bodyFont,
        color: isDark ? slate400 : slate500,
        fontSize: 14,
      ),
    );
  }

  // ── Buttons ───────────────────────────────────────────────
  static ElevatedButtonThemeData _buildElevatedButton() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: amber,
        foregroundColor: slate900,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        textStyle: const TextStyle(
          fontFamily: displayFont,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButton() {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: amber,
        side: const BorderSide(color: amber, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMD),
        ),
        textStyle: const TextStyle(
          fontFamily: displayFont,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButton() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: amber,
        textStyle: const TextStyle(
          fontFamily: bodyFont,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
