import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:uuid/uuid.dart';

/// Wraps Redis-backed session tokens and login rate-limiting.
/// Session tokens are opaque UUIDs mapped to userId in Redis (not JWT),
/// so logout/revocation is immediate and centrally controlled.
class SessionService {
  static const _uuid = Uuid();
  static const Duration sessionTtl = Duration(days: 7);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutWindow = Duration(minutes: 15);

  static String _sessionKey(String token) => 'session:$token';
  static String _attemptsKey(String email) => 'login_attempts:${email.toLowerCase()}';

  static Future<String> createSession(Session session, int userId) async {
    final token = _uuid.v4();
    await session.caches.global.put(
      _sessionKey(token),
      jsonEncode({'userId': userId}),
      lifetime: sessionTtl,
    );
    return token;
  }

  static Future<int?> resolveUserId(Session session, String token) async {
    final raw = await session.caches.global.get<String>(_sessionKey(token));
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return data['userId'] as int;
  }

  static Future<void> revokeSession(Session session, String token) async {
    await session.caches.global.invalidateKey(_sessionKey(token));
  }

  /// Returns true if the caller is allowed to attempt login (under threshold).
  static Future<bool> checkLoginAllowed(Session session, String email) async {
    final raw = await session.caches.global.get<String>(_attemptsKey(email));
    final attempts = raw == null ? 0 : int.tryParse(raw) ?? 0;
    return attempts < maxLoginAttempts;
  }

  static Future<void> recordFailedLogin(Session session, String email) async {
    final key = _attemptsKey(email);
    final raw = await session.caches.global.get<String>(key);
    final attempts = (raw == null ? 0 : int.tryParse(raw) ?? 0) + 1;
    await session.caches.global.put(key, attempts.toString(), lifetime: lockoutWindow);
  }

  static Future<void> clearFailedLogins(Session session, String email) async {
    await session.caches.global.invalidateKey(_attemptsKey(email));
  }
}
