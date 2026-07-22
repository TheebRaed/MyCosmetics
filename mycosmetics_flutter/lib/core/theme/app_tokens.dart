import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Border-radius scale from docs/DESIGN_SYSTEM.md. Use these instead of
/// hardcoding raw radius values in a widget's BoxDecoration.
abstract class AppRadius {
  static const double chip = 8;
  static const double input = 13; // 12-14px band
  static const double card = 20; // 18-22px band
  static const double pill = 30;
  static const double hero = 42;
  static const double circle = 999; // 50% -- avatars/dots, pair with a square box
}

/// Shadow recipes from docs/DESIGN_SYSTEM.md -- always rose/gold tinted,
/// never neutral grey. Pass `Brightness` so callers get the right variant
/// without duplicating the recipe per screen.
abstract class AppShadows {
  static List<BoxShadow> card(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        BoxShadow(color: AppColorsDark.shadowElevatedDark, blurRadius: 34, offset: Offset(0, 14)),
      ];
    }
    return const [
      BoxShadow(color: AppColorsLight.shadowRoseCard, blurRadius: 22, offset: Offset(0, 8)),
      BoxShadow(color: AppColorsLight.insetHighlight, blurRadius: 0, offset: Offset(0, 1)),
    ];
  }

  static List<BoxShadow> elevated(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const [
        BoxShadow(color: AppColorsDark.shadowRoseElevated, blurRadius: 60, offset: Offset(0, 24)),
      ];
    }
    return const [
      BoxShadow(color: AppColorsLight.shadowRoseElevated, blurRadius: 50, offset: Offset(0, 24)),
    ];
  }

  /// Gold CTA glow: 0 8px 18px rgba(169,124,61,.35) -- same in both modes.
  static const List<BoxShadow> goldCta = [
    BoxShadow(color: AppColorsLight.shadowGoldCta, blurRadius: 18, offset: Offset(0, 8)),
  ];

  /// Tight glow for AI/sparkle indicator dots.
  static List<BoxShadow> glowDot({required Color color}) => [
        BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 6, spreadRadius: 0),
      ];
}

/// Card background gradient -- see docs/DESIGN_SYSTEM.md `--card-bg` /
/// `--drawer-bg` tokens.
abstract class AppGradients {
  static LinearGradient card(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? const [AppColorsDark.cardGradientStart, AppColorsDark.cardGradientEnd]
          : const [AppColorsLight.cardGradientStart, AppColorsLight.cardGradientEnd],
    );
  }

  static LinearGradient drawer(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      transform: const GradientRotation(160 * 3.1415926535 / 180),
      colors: isDark
          ? const [AppColorsDark.drawerGradientStart, AppColorsDark.drawerGradientEnd]
          : const [AppColorsLight.drawerGradientStart, AppColorsLight.drawerGradientEnd],
    );
  }
}

abstract class AppSpacing {
  static const double xs = 4, sm = 8, md = 16, lg = 24, xl = 32, xxl = 48;
}
