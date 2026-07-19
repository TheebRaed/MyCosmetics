import 'dart:convert';
import 'package:serverpod/serverpod.dart';

/// Redis-backed caching service.
///
/// Cache key convention: {entity}:{identifier}:{variant}
///   - product:42:detail         → ProductDetail for id 42
///   - products:cat:3:page:0     → page 0 of category 3
///   - categories:toplevel       → top-level category list
///
/// TTL strategy:
///   - Product catalog: 5 minutes (invalidated on write)
///   - Dashboard KPIs:  2 minutes (refreshed frequently)
///   - Analytics views: 10 minutes (expensive aggregations)
///   - User-specific:   No caching (always fresh)
class CacheService {
  static const _catalogTtl   = Duration(minutes: 5);
  static const _dashboardTtl = Duration(minutes: 2);
  static const _analyticsTtl = Duration(minutes: 10);

  // ── Get / Set ─────────────────────────────────────────────────────────────

  static Future<T?> get<T>(
    Session session,
    String key,
    T Function(dynamic) fromJson,
  ) async {
    try {
      final raw = await session.caches.global.get<String>(key);
      if (raw == null) return null;
      return fromJson(jsonDecode(raw));
    } catch (_) {
      return null; // Cache miss or decode error — always fall through to DB
    }
  }

  static Future<void> set(
    Session session,
    String key,
    dynamic value, {
    Duration ttl = _catalogTtl,
  }) async {
    try {
      await session.caches.global.put(
        key,
        jsonEncode(value),
        lifetime: ttl,
      );
    } catch (_) {
      // Cache write failure must never break the primary request
    }
  }

  static Future<void> invalidate(Session session, String key) async {
    try {
      await session.caches.global.invalidateKey(key);
    } catch (_) {}
  }

  static Future<void> invalidatePattern(Session session, String prefix) async {
    // Serverpod global cache does not support pattern delete directly.
    // For production use Redis SCAN + DEL via unsafeQuery to Redis.
    // This is a best-effort invalidation on known keys.
    try {
      await session.caches.global.invalidateKey(prefix);
    } catch (_) {}
  }

  // ── Typed helpers ─────────────────────────────────────────────────────────

  static Future<T> getOrSet<T>(
    Session session,
    String key,
    Future<T> Function() loader,
    T Function(dynamic) fromJson, {
    Duration ttl = _catalogTtl,
  }) async {
    final cached = await get<T>(session, key, fromJson);
    if (cached != null) return cached;
    final fresh = await loader();
    await set(session, key, fresh, ttl: ttl);
    return fresh;
  }

  // ── Category cache ────────────────────────────────────────────────────────

  static String categoriesKey()           => 'categories:toplevel';
  static String subCategoriesKey(int id)  => 'categories:sub:$id';
  static String brandsKey()               => 'brands:all';

  // ── Product cache ─────────────────────────────────────────────────────────

  static String productDetailKey(int id)  => 'product:$id:detail';
  static String productSlugKey(String s)  => 'product:slug:$s:detail';
  static String productListKey(String filter, int page) => 'products:list:$filter:p$page';

  static Future<void> invalidateProduct(Session session, int productId) async {
    await invalidate(session, productDetailKey(productId));
    // List caches are TTL-expired; no pattern delete needed for short TTL
  }

  // ── Dashboard cache ───────────────────────────────────────────────────────

  static String dashboardKpisKey()  => 'dashboard:kpis';
  static String dashboardChartsKey()=> 'dashboard:charts';

  static Future<void> invalidateDashboard(Session session) async {
    await invalidate(session, dashboardKpisKey());
    await invalidate(session, dashboardChartsKey());
  }

  // ── Analytics cache ───────────────────────────────────────────────────────

  static String analyticsAcceptanceKey() => 'analytics:acceptance';
  static String analyticsTopRecsKey()    => 'analytics:top_recs';
  static String analyticsUndertonesKey() => 'analytics:undertones';

  static Duration get dashboardTtl  => _dashboardTtl;
  static Duration get analyticsTtl  => _analyticsTtl;
}
