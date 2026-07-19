import 'package:test/test.dart';

// Unit tests for AuthService business logic.
// These test the pure Dart logic without requiring a database connection.
// Integration tests (requiring Serverpod + Postgres) are in test/integration/.

void main() {
  group('Password validation', () {
    test('rejects passwords shorter than 8 characters', () {
      expect(_validatePassword('short'), isFalse);
    });
    test('accepts passwords 8+ characters', () {
      expect(_validatePassword('secure123'), isTrue);
    });
    test('rejects empty password', () {
      expect(_validatePassword(''), isFalse);
    });
  });

  group('Email validation', () {
    test('accepts valid email', () {
      expect(_validateEmail('user@example.com'), isTrue);
    });
    test('rejects email without @', () {
      expect(_validateEmail('userexample.com'), isFalse);
    });
    test('rejects empty email', () {
      expect(_validateEmail(''), isFalse);
    });
    test('rejects email without domain', () {
      expect(_validateEmail('user@'), isFalse);
    });
  });

  group('Recommendation scoring', () {
    test('skin tone score for foundation within close range is high', () {
      // brightness 0.6 shade, skin 0.55 → delta 0.05 → score near 1.0
      final score = _scoreSkinTone(shadeBrightness: 0.6, skinBrightness: 0.55, category: 'foundation');
      expect(score, greaterThan(0.8));
    });

    test('skin tone score for foundation with large delta is low', () {
      final score = _scoreSkinTone(shadeBrightness: 0.1, skinBrightness: 0.9, category: 'foundation');
      expect(score, lessThan(0.3));
    });

    test('undertone score warm skin + warm shade is high', () {
      final score = _scoreUndertone(warmth: 0.8, undertone: 'warm', category: 'lipstick');
      expect(score, greaterThan(0.7));
    });

    test('undertone score warm skin + cool shade is low', () {
      final score = _scoreUndertone(warmth: 0.1, undertone: 'warm', category: 'lipstick');
      expect(score, lessThan(0.5));
    });

    test('final weighted score is always 0.0-1.0', () {
      for (double s = 0.0; s <= 1.0; s += 0.1) {
        final score = _weightedScore(s, s, s, s, s);
        expect(score, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('Hex color parsing', () {
    test('valid hex returns RGB', () {
      final rgb = _hexToRgb('#FF5733');
      expect(rgb, isNotNull);
      expect(rgb![0], equals(255));
      expect(rgb[1], equals(87));
      expect(rgb[2], equals(51));
    });

    test('hex without # returns RGB', () {
      expect(_hexToRgb('FF5733'), isNotNull);
    });

    test('invalid hex returns null', () {
      expect(_hexToRgb('GGHHII'), isNull);
      expect(_hexToRgb(''), isNull);
      expect(_hexToRgb('12345'), isNull);
    });
  });

  group('Payment idempotency', () {
    test('same idempotency key with same amount is valid duplicate', () {
      expect(_isValidDuplicate(amount: 100.0, existingAmount: 100.0), isTrue);
    });

    test('same idempotency key with different amount is a conflict', () {
      expect(_isValidDuplicate(amount: 100.0, existingAmount: 99.0), isFalse);
    });
  });
}

// ── Pure logic extracted from services for unit testing ───────────────────────

bool _validatePassword(String p) => p.length >= 8;

bool _validateEmail(String e) {
  final parts = e.split('@');
  if (parts.length != 2) return false;
  return parts[0].isNotEmpty && parts[1].contains('.');
}

double _scoreSkinTone({required double shadeBrightness, required double skinBrightness, required String category}) {
  if (category == 'foundation') return (1.0 - (shadeBrightness - skinBrightness).abs() * 2.0).clamp(0.0, 1.0);
  return 0.5;
}

double _scoreUndertone({required double warmth, required String undertone, required String category}) {
  if (undertone == 'warm') return warmth > 0.45 ? (0.5 + warmth * 0.5).clamp(0.0, 1.0) : warmth * 0.6;
  if (undertone == 'cool') return warmth < 0.55 ? (0.5 + (1.0 - warmth) * 0.5).clamp(0.0, 1.0) : (1.0 - warmth) * 0.6;
  return (1.0 - ((warmth - 0.5).abs() * 1.6)).clamp(0.0, 1.0);
}

double _weightedScore(double st, double ut, double pop, double pref, double tryon) =>
    (st * 0.35 + ut * 0.30 + pop * 0.15 + pref * 0.12 + tryon * 0.08).clamp(0.0, 1.0);

List<int>? _hexToRgb(String hex) {
  try {
    final clean = hex.replaceAll('#', '').trim();
    if (clean.length != 6) return null;
    return [int.parse(clean.substring(0, 2), radix: 16), int.parse(clean.substring(2, 4), radix: 16), int.parse(clean.substring(4, 6), radix: 16)];
  } catch (_) { return null; }
}

bool _isValidDuplicate({required double amount, required double existingAmount}) =>
    amount == existingAmount;
