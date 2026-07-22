/// Pure color-matching utilities for the BeautyTech shade recommendation
/// engine. No ML, no external service -- just honest RGB-space math over
/// hex color strings. Kept dependency-free and side-effect-free so it can
/// be unit tested in isolation from Serverpod/DB concerns.
library color_matcher;

import 'dart:math' as math;

class ColorMatcher {
  ColorMatcher._();

  /// Parses a `#RRGGBB` or `RRGGBB` hex string into an (r, g, b) triple,
  /// each 0-255. Throws [FormatException] on malformed input -- callers
  /// should validate with `InputValidator.validateHexColor` first.
  static (int, int, int) hexToRgb(String hex) {
    final clean = hex.replaceAll('#', '');
    if (clean.length != 6) {
      throw FormatException('Expected a 6-digit hex color, got "$hex".');
    }
    final r = int.parse(clean.substring(0, 2), radix: 16);
    final g = int.parse(clean.substring(2, 4), radix: 16);
    final b = int.parse(clean.substring(4, 6), radix: 16);
    return (r, g, b);
  }

  /// Euclidean distance between two colors in raw RGB space, 0 (identical)
  /// to ~441.67 (black vs white -- sqrt(255^2 * 3)). RGB space is not
  /// perceptually uniform (e.g. green differences read as smaller than they
  /// are to the human eye), but it's simple, fast, and honest about what
  /// it measures -- no claim of a perceptual color-science model here.
  static double rgbDistance(String hexA, String hexB) {
    final (r1, g1, b1) = hexToRgb(hexA);
    final (r2, g2, b2) = hexToRgb(hexB);
    final dr = r1 - r2;
    final dg = g1 - g2;
    final db = b1 - b2;
    return math.sqrt((dr * dr + dg * dg + db * db).toDouble());
  }

  /// Maximum possible RGB-space distance -- black (#000000) vs white
  /// (#FFFFFF).
  static const double maxRgbDistance = 441.6729559300637; // sqrt(255^2*3)

  /// Converts RGB distance into a 0.0 (no match) - 1.0 (identical) shade
  /// similarity score, via a simple inverse-linear normalization.
  static double similarity(String hexA, String hexB) {
    final dist = rgbDistance(hexA, hexB);
    final normalized = 1 - (dist / maxRgbDistance);
    return normalized.clamp(0.0, 1.0);
  }

  /// Classifies a hex color's undertone as 'warm', 'cool', or 'neutral'
  /// using the sign and magnitude of (red - blue). This is a coarse but
  /// explainable heuristic (warm skin/makeup tones skew red/yellow i.e.
  /// higher red relative to blue; cool tones skew red/pink/blue i.e.
  /// higher blue relative to red) -- not a substitute for real
  /// colorimetry, but consistent and defensible for ranking purposes.
  static const int _undertoneThreshold = 15;

  static String classifyUndertone(String hex) {
    final (r, _, b) = hexToRgb(hex);
    final diff = r - b;
    if (diff > _undertoneThreshold) return 'warm';
    if (diff < -_undertoneThreshold) return 'cool';
    return 'neutral';
  }
}
