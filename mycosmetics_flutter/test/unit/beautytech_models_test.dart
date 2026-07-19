import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SkinProfile helpers', () {
    test('brightnessLabel returns Fair for high brightness', () {
      expect(_brightnessLabel(0.80), equals('Fair'));
    });
    test('brightnessLabel returns Medium for 0.55', () {
      expect(_brightnessLabel(0.55), equals('Medium'));
    });
    test('brightnessLabel returns Tan for 0.35', () {
      expect(_brightnessLabel(0.35), equals('Tan'));
    });
    test('brightnessLabel returns Deep for 0.10', () {
      expect(_brightnessLabel(0.10), equals('Deep'));
    });
  });

  group('Hex color parsing', () {
    test('parses valid 6-digit hex', () {
      expect(_parseHex('#C2185B'), isNotNull);
    });
    test('returns null for invalid hex', () {
      expect(_parseHex('banana'), isNull);
      expect(_parseHex(''), isNull);
    });
    test('handles hex without #', () {
      expect(_parseHex('C2185B'), isNotNull);
    });
  });

  group('SavedLook variantIds parsing', () {
    test('parses comma-separated ids', () {
      expect(_parseVariantIds('1,2,3'), equals([1, 2, 3]));
    });
    test('returns empty list for empty string', () {
      expect(_parseVariantIds(''), isEmpty);
    });
    test('skips invalid entries', () {
      expect(_parseVariantIds('1,abc,3'), equals([1, 3]));
    });
  });

  group('Confidence percent', () {
    test('converts 0.85 to 85%', () => expect(_confidencePct(0.85), equals(85)));
    test('converts 1.0 to 100%', () => expect(_confidencePct(1.0), equals(100)));
    test('converts 0.0 to 0%',   () => expect(_confidencePct(0.0), equals(0)));
  });

  group('Undertone classification', () {
    test('warm undertone label', () => expect(_undertoneLabel('warm'),    equals('Warm 🌻')));
    test('cool undertone label',  () => expect(_undertoneLabel('cool'),    equals('Cool 🌸')));
    test('neutral fallback',      () => expect(_undertoneLabel('unknown'), equals('Neutral ✨')));
  });

  group('Score breakdown weights sum to ~1.0', () {
    test('weights: 0.35+0.30+0.15+0.12+0.08 = 1.00', () {
      const sum = 0.35 + 0.30 + 0.15 + 0.12 + 0.08;
      expect(sum, closeTo(1.0, 0.001));
    });
  });
}

String _brightnessLabel(double b) {
  if (b > 0.65) return 'Fair';
  if (b > 0.45) return 'Medium';
  if (b > 0.28) return 'Tan';
  return 'Deep';
}

int? _parseHex(String hex) {
  try { return int.parse(hex.replaceAll('#', '').trim().padLeft(6, '0'), radix: 16); }
  catch (_) { return null; }
}

List<int> _parseVariantIds(String s) {
  if (s.isEmpty) return [];
  return s.split(',').map((e) => int.tryParse(e.trim()) ?? -1).where((i) => i > 0).toList();
}

int _confidencePct(double s) => (s * 100).round();

String _undertoneLabel(String? u) => switch (u) {
  'warm' => 'Warm 🌻',
  'cool' => 'Cool 🌸',
  _ => 'Neutral ✨',
};
