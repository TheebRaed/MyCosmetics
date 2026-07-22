import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

/// Redis-backed caching layer for high-traffic read endpoints.
///
/// Cache strategy:
///   - Product listings:     5 minutes TTL (invalidated on product update)
///   - Category/Brand lists: 30 minutes TTL (rarely change)
///   - Dashboard KPIs:       2 minutes TTL (near-real-time for admin)
///   - Recommendation results: 1 hour TTL (per-user, invalidated on rescan)
///
/// Key naming convention:
///   product:list:{filterHash}
///   product:detail:{id}
///   category:list:toplevel
///   brand:list:all
///   dashboard:kpis
///   recommendation:user:{userId}
///
/// Uses Session.caches.global (Serverpod's built-in Redis-backed cache),
/// wrapping values in CachedString since Cache.get/put<T> require a
/// SerializableModel, not a raw String/int.
class CacheService {
  static const _defaultTtl   = Duration(minutes: 5);
  static const _longTtl      = Duration(minutes: 30);
  static const _shortTtl     = Duration(minutes: 2);
  static const _userTtl      = Duration(hours: 1);

  // ── Generic helpers ───────────────────────────────────────────────────────

  Future<String?> get(Session session, String key) async {
    try {
      final cached = await session.caches.global.get<CachedString>(key);
      return cached?.value;
    } catch (_) { return null; }
  }

  Future<void> set(Session session, String key, String value, {Duration? ttl}) async {
    try {
      await session.caches.global.put(key, CachedString(value: value), lifetime: ttl ?? _defaultTtl);
    } catch (_) {}
  }

  Future<void> invalidate(Session session, String key) async {
    try {
      await session.caches.global.invalidateKey(key);
    } catch (_) {}
  }

  Future<void> invalidatePattern(Session session, String prefix) async {
    // Serverpod's global cache does not support pattern delete natively.
    // For now we use a version key approach: increment a version counter
    // and include it in the cache key so old entries become unreachable.
    try {
      final vKey = 'version:$prefix';
      final current = await _version(session, prefix);
      await session.caches.global.put(vKey, CachedString(value: (current + 1).toString()), lifetime: const Duration(days: 7));
    } catch (_) {}
  }

  Future<int> _version(Session session, String prefix) async {
    try {
      final cached = await session.caches.global.get<CachedString>('version:$prefix');
      return cached == null ? 0 : int.tryParse(cached.value) ?? 0;
    } catch (_) { return 0; }
  }

  // ── Product cache ─────────────────────────────────────────────────────────

  String productListKey(String filterHash, {int version = 0}) =>
      'product:list:v$version:$filterHash';

  String productDetailKey(int id) => 'product:detail:$id';

  Future<void> invalidateProductCache(Session session) =>
      invalidatePattern(session, 'product');

  // ── Category / Brand cache ────────────────────────────────────────────────

  static const categoryKey = 'category:list:toplevel';
  static const brandKey    = 'brand:list:all';

  Future<void> warmCategoryCache(Session session, String json) =>
      set(session, categoryKey, json, ttl: _longTtl);

  Future<void> warmBrandCache(Session session, String json) =>
      set(session, brandKey, json, ttl: _longTtl);

  // ── Dashboard KPI cache ───────────────────────────────────────────────────

  static const dashboardKpiKey = 'dashboard:kpis';

  Future<String?> getDashboardKpis(Session session) => get(session, dashboardKpiKey);

  Future<void> setDashboardKpis(Session session, String json) =>
      set(session, dashboardKpiKey, json, ttl: _shortTtl);

  // ── User recommendation cache ─────────────────────────────────────────────

  String recommendationKey(int userId) => 'recommendation:user:$userId';

  Future<void> invalidateUserRecommendations(Session session, int userId) =>
      invalidate(session, recommendationKey(userId));

  /// Exposed so callers can build user-scoped keys with the same TTL policy
  /// this class uses internally.
  Duration get userTtl => _userTtl;
}
