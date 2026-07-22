import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

/// Health check endpoint data for Docker + load balancer readiness probes.
///
/// Returns:
///   200 OK   — all systems healthy, ready to serve traffic
///   503      — degraded or not ready (Docker will restart; LB will stop routing)
class HealthCheck {
  static Future<Map<String, dynamic>> check(Session session) async {
    final results = <String, dynamic>{};
    bool healthy = true;

    // ── Database ───────────────────────────────────────────────────────────
    try {
      await session.db.unsafeQuery('SELECT 1');
      results['database'] = 'ok';
    } catch (e) {
      results['database'] = 'error: $e';
      healthy = false;
    }

    // ── Redis ──────────────────────────────────────────────────────────────
    try {
      await session.caches.global.put(
        'health:ping',
        CachedString(value: 'pong'),
        lifetime: const Duration(seconds: 10),
      );
      final cached = await session.caches.global.get<CachedString>('health:ping');
      results['redis'] = cached?.value == 'pong' ? 'ok' : 'unexpected response';
      if (cached?.value != 'pong') healthy = false;
    } catch (e) {
      results['redis'] = 'error: $e';
      healthy = false;
    }

    // ── Disk space ─────────────────────────────────────────────────────────
    try {
      await FileStat.stat('/tmp');
      results['disk'] = 'ok';
    } catch (e) {
      results['disk'] = 'unknown';
    }

    return {
      'status':    healthy ? 'healthy' : 'unhealthy',
      'timestamp': DateTime.now().toUtc().toIso8601String(),
      'version':   const String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0'),
      'checks':    results,
    };
  }
}
