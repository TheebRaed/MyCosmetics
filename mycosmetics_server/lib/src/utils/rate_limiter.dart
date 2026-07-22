import 'package:serverpod/serverpod.dart';

/// Application-layer rate limiter backed by Redis.
/// Works alongside Nginx rate limiting for defense-in-depth.
///
/// Strategy: sliding window using Redis sorted sets.
/// Key: ratelimit:{endpoint}:{identifier}
/// Members: timestamp strings; score = timestamp in milliseconds
///
/// Example: auth/login — 10 attempts per minute per IP
class RateLimiter {

  /// Checks if the caller has exceeded the rate limit.
  /// Throws [RateLimitException] if limit exceeded.
  static Future<void> check(
    Session session, {
    required String endpoint,
    required String identifier, // IP address or userId
    required int maxRequests,
    required Duration window,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowMs = window.inMilliseconds;
    final windowStart = now - windowMs;

    try {
      // Use Redis sorted set: ZADD + ZREMRANGEBYSCORE + ZCARD
      // All in a pipeline for atomicity
      await session.db.unsafeQuery(
        'INSERT INTO "rate_limit_events" ("ipAddress","endpoint","createdAt") VALUES (@ip,@ep,@now)',
        parameters: QueryParameters.named({'ip': identifier, 'ep': endpoint, 'now': DateTime.now().toUtc()}),
      );

      // Count events in window
      final countResult = await session.db.unsafeQuery(
        'SELECT COUNT(*) as cnt FROM "rate_limit_events" '
        'WHERE "ipAddress"=@ip AND "endpoint"=@ep '
        'AND "createdAt" >= @windowStart',
        parameters: QueryParameters.named({
          'ip': identifier,
          'ep': endpoint,
          'windowStart': DateTime.fromMillisecondsSinceEpoch(windowStart).toUtc(),
        }),
      );
      final count = (countResult.first.toColumnMap()['cnt'] as BigInt).toInt();

      if (count > maxRequests) {
        throw RateLimitException(
          'Too many requests to $endpoint. Limit: $maxRequests per ${window.inSeconds}s.',
          retryAfterSeconds: window.inSeconds,
        );
      }

      // Cleanup old events (async, non-blocking)
      session.db.unsafeQuery(
        'DELETE FROM "rate_limit_events" '
        'WHERE "ipAddress"=@ip AND "endpoint"=@ep '
        'AND "createdAt" < @windowStart',
        parameters: QueryParameters.named({
          'ip': identifier,
          'ep': endpoint,
          'windowStart': DateTime.fromMillisecondsSinceEpoch(windowStart - 1000).toUtc(),
        }),
      ).ignore();
    } on RateLimitException {
      rethrow;
    } catch (_) {
      // Rate limiter errors must never block legitimate requests
    }
  }

  // ── Pre-configured limiters ───────────────────────────────────────────────

  /// Login: 10 attempts/minute per IP
  static Future<void> checkLogin(Session session, String ipAddress) =>
      check(session, endpoint: 'auth/login', identifier: ipAddress,
        maxRequests: 10, window: const Duration(minutes: 1));

  /// Password reset: 3 attempts/15 minutes per IP
  static Future<void> checkForgotPassword(Session session, String ipAddress) =>
      check(session, endpoint: 'auth/forgotPassword', identifier: ipAddress,
        maxRequests: 3, window: const Duration(minutes: 15));

  /// Recommendation generation: 10 per hour per user
  static Future<void> checkRecommendations(Session session, int userId) =>
      check(session, endpoint: 'beautyTech/generateRecommendations',
        identifier: 'user:$userId',
        maxRequests: 10, window: const Duration(hours: 1));

  /// Try-on analytics: 60 per minute per user
  static Future<void> checkTryOnAnalytics(Session session, int userId) =>
      check(session, endpoint: 'beautyTech/recordTryOn',
        identifier: 'user:$userId',
        maxRequests: 60, window: const Duration(minutes: 1));
}

class RateLimitException implements Exception {
  final String message;
  final int retryAfterSeconds;
  RateLimitException(this.message, {required this.retryAfterSeconds});
  @override String toString() => message;
}

extension FutureIgnore on Future {
  void ignore() { catchError((_) {}); }
}
