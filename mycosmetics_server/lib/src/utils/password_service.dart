import 'package:crypt/crypt.dart';

/// Centralizes password hashing so no endpoint ever rolls its own crypto.
class PasswordService {
  static const int _rounds = 12;

  static String hash(String plainPassword) {
    return Crypt.sha256(plainPassword, rounds: _rounds).toString();
  }

  static bool verify(String plainPassword, String storedHash) {
    try {
      return Crypt(storedHash).match(plainPassword);
    } catch (_) {
      // Malformed hash should never crash auth; treat as failed match.
      return false;
    }
  }

  /// Basic policy: 8+ chars, at least one letter and one digit.
  static String? validateStrength(String plainPassword) {
    if (plainPassword.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(plainPassword) ||
        !RegExp(r'[0-9]').hasMatch(plainPassword)) {
      return 'Password must contain letters and numbers.';
    }
    return null;
  }
}
