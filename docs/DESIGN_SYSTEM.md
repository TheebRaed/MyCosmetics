# MyCosmetics -- Design System (from Claude Design import)

Source: https://claude.ai/design/p/cadeb1f0-484d-4da1-96cb-c235ef53843f?file=MyCosmetics+App.dc.html
Imported: 2026-07-21. Treat this as the visual source of truth -- do not deviate without asking.

## Fonts
- Body/UI: `Poppins` (400/500/600/700), fallback `Tajawal` (Arabic support), sans-serif.
- Script/accent (logo, luxury flourishes): `Dancing Script` (600/700).

## Light mode tokens
| Token | Value | Use |
|---|---|---|
| `--body-bg` | `#e9e4ef` | app background base |
| `--page-bg` | layered soft radial gradients, warm rose-gold (`rgba(233,180,120,*)`) + white highlights | screen background wash |
| `--text-heading` | `#3a2230` | headings |
| `--text-label` | `#5a4050` | body/labels |
| `--text-muted` | `#8a6b74` | secondary text |
| `--text-faint` | `#a9899a` | disabled/hint text |
| `--card-bg` | `linear-gradient(135deg, rgba(255,255,255,.75), rgba(252,227,234,.6))` | cards/panels |
| `--chip-bg` | `#fdf0f3` | chips/tags background |
| `--chip-solid-bg` | `#fff` | solid chip variant |
| `--chip-text` | `#9c2748` | chip text (deep rose) |
| `--input-bg` | `#fdf3f5` | text field fill |
| `--input-border` | `#f0d3dd` | text field border |
| `--drawer-bg` | `linear-gradient(160deg, #fffaf7, #fce3ea)` | modals/bottom sheets/drawers |

## Dark mode tokens
| Token | Value |
|---|---|
| `--body-bg` | `#150b11` |
| `--page-bg` | layered radial gradients, muted gold (`rgba(201,151,91,.16)`) on near-black |
| `--text-heading` | `#f5e8ee` |
| `--text-label` | `#e3cdd8` |
| `--text-muted` | `#c9a7b5` |
| `--text-faint` | `#9c8494` |
| `--card-bg` | `linear-gradient(135deg, rgba(255,255,255,.06), rgba(232,194,122,.05))` (glassy glow) |
| `--chip-text` | `#f5c9d6` |
| `--drawer-bg` | `linear-gradient(160deg, #2a1420, #1f0f18)` |

Dark mode preserves rose/gold accents at lower opacity over near-black -- never pure black, never desaturated grey.

## Shape & elevation
- Border radius scale: `8px` (small chips/icons), `12-14px` (inputs, list rows, small cards), `18-22px` (cards, sheets), `30px` (pill buttons), `42px` (hero/large containers), `50%` (avatars/dots).
- Shadows are always tinted rose/gold, never neutral grey:
  - Card resting: `0 8px 22px rgba(156,39,72,.12)` with `inset 0 1px 0 rgba(255,255,255,.6)` (light) for a soft embossed edge.
  - Elevated card/hero: `0 24px 50px rgba(156,39,72,.28)` to `0 24px 60px rgba(122,31,61,.35)`.
  - Gold CTA buttons: `0 8px 18px rgba(169,124,61,.35)`.
  - Dark-mode elevated surfaces: `0 14px 34px rgba(0,0,0,.35)`.
  - Small glow dots/indicators: tight `0 0 5-6px` rose or gold glow, used for AI/sparkle accents.

## Motion (CSS keyframes present in source -- reproduce as Flutter animations, not literal CSS)
- `sparkleMove` -- slow drifting background sparkle positions (ambient, hero/splash backgrounds).
- `scanLine` -- vertical scan line 8%->88%->8% (AI skin-analysis/scanning UI).
- `pulseRing` -- scale 1 -> 1.04 with opacity pulse (AI match rings, live indicators).
- `twinkle` -- opacity/scale sparkle twinkle (decorative accents).
- `floatSoft` -- gentle -6px vertical float loop (cards, illustrations).
- `spin360` -- full Y-axis rotation (try-on / 3D product preview).
- `heroGlow` -- opacity pulse .6<->1 (hero banner glow).

## Recognized UI language from source
- Brand wordmark "My Cosmetics" in `Dancing Script` over `Poppins` body.
- AI-forward visual motifs: scan lines, pulse rings, sparkle/twinkle particles, match-percentage rings -- used for BeautyTech screens (skin analysis, AI recommendations, virtual try-on).
- Admin screens present in same source file (e.g. product creation with photo/subcategory/collection/description fields, AI recommendation engine weight controls) -- confirms admin lives in the same app shell per CLAUDE.md.

## How to apply in Flutter
- Map tokens above into `lib/core/theme/` `ThemeData`/`ColorScheme` (light + dark), both apps share the same palette per CLAUDE.md.
- Do not hardcode hex values in widgets -- reference theme extension/tokens so light/dark stay in sync.
- Reproduce shadow/radius scale via reusable widgets (e.g. `AppCard`, `PillButton`) in `lib/shared/` rather than repeating raw `BoxDecoration` per screen.
- Motion: use `AnimationController`/`Rive`/`Lottie` sparingly per motif above; keep durations slow/soft (this is a luxury, unhurried feel, not snappy Material motion).
