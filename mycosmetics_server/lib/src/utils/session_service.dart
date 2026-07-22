import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

/// Wraps Redis-backed session tokens and login rate-limiting.
/// Session tokens are opaque UUIDs mapped to userId in Redis (not JWT),
/// so logout/revocation is immediate and centrally controlled.
///
/// Relocated from lib/src/utils/password_service.dart, which had been
/// overwritten with this class instead of PasswordService. Uses
/// Session.caches.global (Serverpod's built-in Redis-backed cache), wrapping
/// plain strings in CachedString since Cache.get/put<T> require a
/// SerializableModel.
class SessionService {
  static const Duration sessionTtl = Duration(days: 7);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutWindow = Duration(minutes: 15);

  static String _sessionKey(String token) => 'session:$token';
  static String _attemptsKey(String email) => 'login_attempts:${email.toLowerCase()}';

  static Future<String> createSession(Session session, int userId) async {
    final token = const Uuid().v4();
    await session.caches.global.put(
      _sessionKey(token),
      CachedString(value: jsonEncode({'userId': userId})),
      lifetime: sessionTtl,
    );
    return token;
  }

  static Future<int?> resolveUserId(Session session, String token) async {
    final cached = await session.caches.global.get<CachedString>(_sessionKey(token));
    if (cached == null) return null;
    final data = jsonDecode(cached.value) as Map<String, dynamic>;
    return data['userId'] as int;
  }

  static Future<void> revokeSession(Session session, String token) async {
    await session.caches.global.invalidateKey(_sessionKey(token));
  }

  /// Returns true if the caller is allowed to attempt login (under threshold).
  static Future<bool> checkLoginAllowed(Session session, String email) async {
    final cached = await session.caches.global.get<CachedString>(_attemptsKey(email));
    final attempts = cached == null ? 0 : int.tryParse(cached.value) ?? 0;
    return attempts < maxLoginAttempts;
  }

  static Future<void> recordFailedLogin(Session session, String email) async {
    final key = _attemptsKey(email);
    final cached = await session.caches.global.get<CachedString>(key);
    final attempts = (cached == null ? 0 : int.tryParse(cached.value) ?? 0) + 1;
    await session.caches.global.put(key, CachedString(value: attempts.toString()), lifetime: lockoutWindow);
  }

  static Future<void> clearFailedLogins(Session session, String email) async {
    await session.caches.global.invalidateKey(_attemptsKey(email));
  }
}
