import 'package:flutter/material.dart';

abstract class AdminColors {
  static const primary      = Color(0xFF880E4F);
  static const primaryLight = Color(0xFFC2185B);
  static const accent       = Color(0xFFC9963F);
  static const success      = Color(0xFF2E7D32);
  static const warning      = Color(0xFFF57C00);
  static const error        = Color(0xFFB00020);
  static const info         = Color(0xFF0277BD);
  static const surface      = Color(0xFFF5F5F7);
  static const white        = Color(0xFFFFFFFF);
  static const divider      = Color(0xFFE0E0E0);
  static const textPrimary  = Color(0xFF1A1A2E);
  static const textSec      = Color(0xFF6B6B80);
  static const textHint     = Color(0xFFAAAAAA);
  static const sidebar      = Color(0xFF1A0A10);
  static const sidebarSel   = Color(0xFFC2185B);
  static const cardBg       = Color(0xFFFFFFFF);
  static const blush        = Color(0xFFFCE9EC);
}

abstract class AdminTextStyles {
  static const headline = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AdminColors.textPrimary);
  static const title    = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AdminColors.textPrimary);
  static const subtitle = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AdminColors.textSec);
  static const body     = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AdminColors.textPrimary);
  static const caption  = TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: AdminColors.textHint);
  static const kpiValue = TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AdminColors.textPrimary);
  static const kpiLabel = TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AdminColors.textSec, letterSpacing: 0.6);
}

class AdminTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AdminColors.primary, primary: AdminColors.primary, surface: AdminColors.surface),
    scaffoldBackgroundColor: AdminColors.surface,
    appBarTheme: const AppBarTheme(backgroundColor: AdminColors.white, foregroundColor: AdminColors.textPrimary, elevation: 0, scrolledUnderElevation: 1, titleTextStyle: AdminTextStyles.title),
    cardTheme: CardThemeData(color: AdminColors.cardBg, elevation: 1, shadowColor: Colors.black.withValues(alpha: 0.08), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), margin: EdgeInsets.zero),
    elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(backgroundColor: AdminColors.primary, foregroundColor: AdminColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12))),
    outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(foregroundColor: AdminColors.primary, side: const BorderSide(color: AdminColors.primary), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)))),
    inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: AdminColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.divider)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.divider)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AdminColors.primary, width: 1.5)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
    snackBarTheme: SnackBarThemeData(backgroundColor: AdminColors.textPrimary, contentTextStyle: const TextStyle(color: AdminColors.white), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), behavior: SnackBarBehavior.floating),
  );
}

abstract class AdminSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32;
  static const pagePadding = EdgeInsets.all(24);
  static const cardPadding = EdgeInsets.all(16);
}
