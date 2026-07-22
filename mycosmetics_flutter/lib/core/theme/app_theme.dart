import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

/// Text style helpers combining the Poppins/Dancing Script/Tajawal font
/// stack from docs/DESIGN_SYSTEM.md. Poppins is the body/UI face, Dancing
/// Script is reserved for the brand wordmark and luxury flourishes.
abstract class AppTextStyles {
  static TextStyle poppins({
    required Color color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    double? letterSpacing,
  }) =>
      GoogleFonts.poppins(color: color, fontSize: fontSize, fontWeight: fontWeight, letterSpacing: letterSpacing);

  /// Brand wordmark / script accent -- "My Cosmetics" logo treatment and
  /// similar luxury flourishes only, never body copy.
  static TextStyle dancingScript({
    required Color color,
    double fontSize = 28,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      GoogleFonts.dancingScript(color: color, fontSize: fontSize, fontWeight: fontWeight);
}

class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final label = isDark ? AppColorsDark.textLabel : AppColorsLight.textLabel;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final bodyBg = isDark ? AppColorsDark.bodyBg : AppColorsLight.bodyBg;
    final primary = isDark ? AppColorsDark.primary : AppColorsLight.primary;
    final accentGold = isDark ? AppColorsDark.accentGold : AppColorsLight.accentGold;
    final inputBg = isDark ? AppColorsDark.inputBg : AppColorsLight.inputBg;
    final inputBorder = isDark ? AppColorsDark.inputBorder : AppColorsLight.inputBorder;

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: bodyBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        secondary: accentGold,
        surface: isDark ? AppColorsDark.chipSolidBg : AppColorsLight.chipSolidBg,
      ),
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: TextTheme(
        headlineMedium: AppTextStyles.poppins(color: heading, fontSize: 24, fontWeight: FontWeight.w700),
        titleLarge: AppTextStyles.poppins(color: heading, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: AppTextStyles.poppins(color: label, fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: AppTextStyles.poppins(color: label, fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: AppTextStyles.poppins(color: muted, fontSize: 12, fontWeight: FontWeight.w400),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: heading,
        elevation: 0,
        titleTextStyle: AppTextStyles.poppins(color: heading, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: isDark ? AppColorsDark.chipSolidBg : AppColorsLight.chipSolidBg,
        selectedItemColor: primary,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      dividerColor: inputBorder,
    );

    return base;
  }
}
