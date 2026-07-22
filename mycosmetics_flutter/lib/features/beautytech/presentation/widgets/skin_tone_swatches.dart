import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Fixed palette of skin-tone swatch hex values the user picks/confirms
/// from -- this IS the "skin tone scan" (no camera/ML pipeline exists, see
/// CLAUDE.md task brief honesty framing). Spans a light-to-deep range with
/// warm/neutral/cool leaning shades so `ColorMatcher.classifyUndertone` on
/// the server can meaningfully classify most picks.
const kSkinToneSwatches = <String>[
  '#FDE5D3',
  '#F5CBA0',
  '#EAB888',
  '#D9A06B',
  '#C68642',
  '#A9673A',
  '#8D5524',
  '#6B4226',
  '#4A2E1D',
  '#3B2417',
];

class SkinToneSwatchGrid extends StatelessWidget {
  const SkinToneSwatchGrid({super.key, required this.selectedHex, required this.onSelected});

  final String? selectedHex;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: kSkinToneSwatches.map((hex) {
        final selected = hex.toUpperCase() == selectedHex?.toUpperCase();
        return GestureDetector(
          onTap: () => onSelected(hex),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _colorFromHex(hex),
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColorsLight.accentGold : Colors.transparent,
                width: 3,
              ),
              boxShadow: selected ? AppShadows.glowDot(color: AppColorsLight.accentGold) : null,
            ),
            child: selected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
          ),
        );
      }).toList(),
    );
  }
}

enum UndertoneOption { warm, cool, neutral }

/// Undertone values match `ColorMatcher.classifyUndertone`'s exact strings
/// ('warm'/'cool'/'neutral') -- see mycosmetics_server/lib/src/utils/color_matcher.dart.
extension UndertoneOptionX on UndertoneOption {
  String get value => switch (this) {
        UndertoneOption.warm => 'warm',
        UndertoneOption.cool => 'cool',
        UndertoneOption.neutral => 'neutral',
      };

  String get label => switch (this) {
        UndertoneOption.warm => 'Warm',
        UndertoneOption.cool => 'Cool',
        UndertoneOption.neutral => 'Neutral',
      };
}

class UndertonePicker extends StatelessWidget {
  const UndertonePicker({super.key, required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final chipBg = isDark ? AppColorsDark.chipBg : AppColorsLight.chipBg;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    return Wrap(
      spacing: AppSpacing.sm,
      children: UndertoneOption.values.map((option) {
        final isSelected = option.value == selected;
        return ChoiceChip(
          label: Text(option.label),
          selected: isSelected,
          onSelected: (_) => onSelected(option.value),
          selectedColor: chipText,
          backgroundColor: chipBg,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : muted,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}

Color _colorFromHex(String hex) {
  final cleaned = hex.replaceAll('#', '');
  return Color(int.parse('FF$cleaned', radix: 16));
}
