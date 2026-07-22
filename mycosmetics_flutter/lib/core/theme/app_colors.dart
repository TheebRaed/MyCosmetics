import 'package:flutter/material.dart';

/// Color tokens lifted verbatim from docs/DESIGN_SYSTEM.md (Claude Design
/// import, 2026-07-21). Never hardcode these hex values directly in a
/// widget -- reference [AppColors] so light/dark stay in sync.
abstract class AppColorsLight {
  static const bodyBg = Color(0xFFE9E4EF);
  static const textHeading = Color(0xFF3A2230);
  static const textLabel = Color(0xFF5A4050);
  static const textMuted = Color(0xFF8A6B74);
  static const textFaint = Color(0xFFA9899A);
  static const chipBg = Color(0xFFFDF0F3);
  static const chipSolidBg = Color(0xFFFFFFFF);
  static const chipText = Color(0xFF9C2748);
  static const inputBg = Color(0xFFFDF3F5);
  static const inputBorder = Color(0xFFF0D3DD);

  // card-bg gradient: linear-gradient(135deg, rgba(255,255,255,.75), rgba(252,227,234,.6))
  static const cardGradientStart = Color(0xBFFFFFFF); // ~.75 alpha
  static const cardGradientEnd = Color(0x99FCE3EA); // ~.6 alpha

  // drawer-bg gradient: linear-gradient(160deg, #fffaf7, #fce3ea)
  static const drawerGradientStart = Color(0xFFFFFAF7);
  static const drawerGradientEnd = Color(0xFFFCE3EA);

  // page-bg wash accent: warm rose-gold radial highlights
  static const pageWashRoseGold = Color(0xFFE9B478);

  // shadow tints -- always rose/gold, never neutral grey
  static const shadowRoseCard = Color(0x1F9C2748); // rgba(156,39,72,.12)
  static const shadowRoseElevated = Color(0x479C2748); // rgba(156,39,72,.28)
  static const shadowGoldCta = Color(0x59A97C3D); // rgba(169,124,61,.35)
  static const insetHighlight = Color(0x99FFFFFF); // rgba(255,255,255,.6)

  static const primary = chipText; // deep rose, used as seed/primary
  static const accentGold = Color(0xFFA97C3D);
}

abstract class AppColorsDark {
  static const bodyBg = Color(0xFF150B11);
  static const textHeading = Color(0xFFF5E8EE);
  static const textLabel = Color(0xFFE3CDD8);
  static const textMuted = Color(0xFFC9A7B5);
  static const textFaint = Color(0xFF9C8494);
  static const chipText = Color(0xFFF5C9D6);
  static const chipBg = Color(0xFF2A1420);
  static const chipSolidBg = Color(0xFF241019);
  static const inputBg = Color(0xFF241019);
  static const inputBorder = Color(0xFF3A2230);

  // card-bg: linear-gradient(135deg, rgba(255,255,255,.06), rgba(232,194,122,.05)) -- glassy glow
  static const cardGradientStart = Color(0x0FFFFFFF); // ~.06 alpha
  static const cardGradientEnd = Color(0x0DE8C27A); // ~.05 alpha

  // drawer-bg: linear-gradient(160deg, #2a1420, #1f0f18)
  static const drawerGradientStart = Color(0xFF2A1420);
  static const drawerGradientEnd = Color(0xFF1F0F18);

  // page-bg wash accent: muted gold on near-black
  static const pageWashGold = Color(0x29C9975B); // rgba(201,151,91,.16)

  // shadows in dark: pure black is allowed only for elevated surfaces per doc
  static const shadowElevatedDark = Color(0x59000000); // rgba(0,0,0,.35)
  static const shadowGoldCta = Color(0x59A97C3D); // same gold CTA glow
  static const shadowRoseElevated = Color(0x597A1F3D); // rgba(122,31,61,.35)

  static const primary = chipText;
  static const accentGold = Color(0xFFC9975B);
}
