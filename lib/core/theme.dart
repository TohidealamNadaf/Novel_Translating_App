import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ReadingTheme { dark, sepia, light, oled }

class AppTheme {
  // ─── Brand Colors ───
  static const Color brandPrimary = Color(0xFF4A6572); // Slate Navy
  static const Color brandSecondary = Color(0xFF7A9E9F); // Muted Teal
  static const Color brandAccent = Color(0xFFF9AA33); // Warm Sand

  // ─── Dark Theme (Calm Navy / Eclipse) ───
  static const Color darkBg = Color(0xFF13151A); // Deep Muted Navy
  static const Color darkSurface = Color(0xFF1E2128);
  static const Color darkCard = Color(0xFF262932);
  static const Color darkText = Color(0xFFE2E8F0);
  static const Color darkSubtext = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF333842);

  // ─── OLED Theme ───
  static const Color oledBg = Color(0xFF000000);
  static const Color oledSurface = Color(0xFF0A0A0A);
  static const Color oledCard = Color(0xFF111111);
  static const Color oledText = Color(0xFFE0E0E0);
  static const Color oledSubtext = Color(0xFF888888);
  static const Color oledBorder = Color(0xFF222222);

  // ─── Sepia Theme ───
  static const Color sepiaBg = Color(0xFFF6EFE5);
  static const Color sepiaSurface = Color(0xFFF0E5D3);
  static const Color sepiaCard = Color(0xFFE8DBC3);
  static const Color sepiaText = Color(0xFF433422);
  static const Color sepiaSubtext = Color(0xFF7A654E);
  static const Color sepiaBorder = Color(0xFFD6C8B0);

  // ─── Light Theme ───
  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1E293B);
  static const Color lightSubtext = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE2E8F0);

  static ThemeData buildTheme(ReadingTheme theme) {
    switch (theme) {
      case ReadingTheme.dark:
        return _buildDarkTheme();
      case ReadingTheme.oled:
        return _buildOledTheme();
      case ReadingTheme.sepia:
        return _buildSepiaTheme();
      case ReadingTheme.light:
        return _buildLightTheme();
    }
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: brandPrimary,
        secondary: brandSecondary,
        tertiary: brandAccent,
        surface: darkSurface,
        onSurface: darkText,
        outline: darkBorder,
      ),
      textTheme: _buildTextTheme(darkText, darkSubtext),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: brandPrimary.withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brandPrimary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: const TextStyle(color: darkText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: darkBorder, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: darkSurface,
        labelStyle: const TextStyle(color: darkText),
        side: const BorderSide(color: darkBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData _buildOledTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: oledBg,
      colorScheme: const ColorScheme.dark(
        primary: brandPrimary,
        secondary: brandSecondary,
        tertiary: brandAccent,
        surface: oledSurface,
        onSurface: oledText,
        outline: oledBorder,
      ),
      textTheme: _buildTextTheme(oledText, oledSubtext),
      appBarTheme: const AppBarTheme(
        backgroundColor: oledBg,
        foregroundColor: oledText,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: oledSurface,
        indicatorColor: brandPrimary.withOpacity(0.3),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: oledSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: oledBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: oledBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brandPrimary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: oledCard,
        contentTextStyle: const TextStyle(color: oledText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: oledBorder, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: oledSurface,
        labelStyle: const TextStyle(color: oledText),
        side: const BorderSide(color: oledBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData _buildSepiaTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: sepiaBg,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF8B6914),
        secondary: Color(0xFFB08D3B),
        tertiary: brandAccent,
        surface: sepiaSurface,
        onSurface: sepiaText,
        outline: sepiaBorder,
      ),
      textTheme: _buildTextTheme(sepiaText, sepiaSubtext),
      appBarTheme: const AppBarTheme(
        backgroundColor: sepiaBg,
        foregroundColor: sepiaText,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: sepiaSurface,
        indicatorColor: const Color(0xFF8B6914).withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: sepiaSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: sepiaBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: sepiaBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF8B6914), width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8B6914),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFF8B6914),
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: sepiaCard,
        contentTextStyle: const TextStyle(color: sepiaText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: sepiaBorder, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: sepiaSurface,
        labelStyle: const TextStyle(color: sepiaText),
        side: const BorderSide(color: sepiaBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: brandPrimary,
        secondary: brandSecondary,
        tertiary: brandAccent,
        surface: lightSurface,
        onSurface: lightText,
        outline: lightBorder,
      ),
      textTheme: _buildTextTheme(lightText, lightSubtext),
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: brandPrimary.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: lightBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: brandPrimary, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: brandPrimary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightCard,
        contentTextStyle: const TextStyle(color: lightText),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(color: lightBorder, thickness: 1),
      chipTheme: ChipThemeData(
        backgroundColor: lightSurface,
        labelStyle: const TextStyle(color: lightText),
        side: const BorderSide(color: lightBorder),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      displayMedium: GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineLarge: GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineMedium: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleMedium: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodyLarge: GoogleFonts.merriweather(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
    );
  }

  // ─── Reading-specific text styles ───
  static TextStyle readingStyle({
    required ReadingTheme theme,
    required double fontSize,
    required bool useSerif,
  }) {
    final color = switch (theme) {
      ReadingTheme.dark => darkText,
      ReadingTheme.oled => oledText,
      ReadingTheme.sepia => sepiaText,
      ReadingTheme.light => lightText,
    };

    if (useSerif) {
      return GoogleFonts.merriweather(
        fontSize: fontSize,
        height: 1.8,
        color: color,
      );
    }
    return GoogleFonts.inter(
      fontSize: fontSize,
      height: 1.7,
      color: color,
    );
  }

  static Color readingBackground(ReadingTheme theme) {
    return switch (theme) {
      ReadingTheme.dark => darkBg,
      ReadingTheme.oled => oledBg,
      ReadingTheme.sepia => sepiaBg,
      ReadingTheme.light => lightBg,
    };
  }
}
