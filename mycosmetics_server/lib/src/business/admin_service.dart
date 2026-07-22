import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide UserRepository;
import 'package:mycosmetics_server/src/repositories/admin_repository.dart';
import 'package:mycosmetics_server/src/repositories/user_repository.dart';
import 'package:mycosmetics_server/src/utils/secure_logging.dart';

class AdminException implements Exception {
  final String message;
  AdminException(this.message);
  @override String toString() => message;
}

class AdminService {
  final AdminRepository _repo  = AdminRepository();
  final UserRepository  _users = UserRepository();

  // ── Dashboard ─────────────────────────────────────────────────────────────
  Future<DashboardOverview> getDashboardOverview(Session session) async {
    final k = await _repo.fetchOverviewKpis(session);
    return DashboardOverview(
      revenueTotal:       (k['revenueTotal']       as num? ?? 0).toDouble(),
      revenueToday:       (k['revenueToday']       as num? ?? 0).toDouble(),
      revenueThisMonth:   (k['revenueThisMonth']   as num? ?? 0).toDouble(),
      totalOrders:        (k['totalOrders']         as BigInt? ?? BigInt.zero).toInt(),
      pendingOrders:      (k['pendingOrders']       as BigInt? ?? BigInt.zero).toInt(),
      processingOrders:   (k['processingOrders']    as BigInt? ?? BigInt.zero).toInt(),
      completedOrders:    (k['completedOrders']     as BigInt? ?? BigInt.zero).toInt(),
      cancelledOrders:    (k['cancelledOrders']     as BigInt? ?? BigInt.zero).toInt(),
      activeCustomers:    (k['activeCustomers']     as BigInt? ?? BigInt.zero).toInt(),
      registeredUsers:    (k['registeredUsers']     as BigInt? ?? BigInt.zero).toInt(),
      totalProducts:      (k['totalProducts']       as BigInt? ?? BigInt.zero).toInt(),
      lowStockProducts:   (k['lowStockProducts']    as BigInt? ?? BigInt.zero).toInt(),
      outOfStockProducts: (k['outOfStockProducts']  as BigInt? ?? BigInt.zero).toInt(),
    );
  }

  Future<DashboardCharts> getDashboardCharts(Session session) async {
    final daily   = await _repo.fetchDailySales(session);
    final monthly = await _repo.fetchMonthlySales(session);
    final byCat   = await _repo.fetchRevenueByCategory(session);
    final byBrand = await _repo.fetchRevenueByBrand(session);
    final growth  = await _repo.fetchUserGrowth(session);

    SalesDataPoint _map(Map<String,dynamic> r, {String labelKey='date'}) => SalesDataPoint(
      label: r[labelKey]?.toString() ?? '',
      revenue: (r['revenue'] as num? ?? 0).toDouble(),
      orderCount: (r['orderCount'] as BigInt? ?? BigInt.zero).toInt(),
    );

    return DashboardCharts(
      dailySales:        daily.map((r) => _map(r)).toList(),
      monthlySales:      monthly.map((r) => _map(r, labelKey: 'month')).toList(),
      revenueByCategory: byCat.map((r) => _map(r, labelKey: 'label')).toList(),
      revenueByBrand:    byBrand.map((r) => _map(r, labelKey: 'label')).toList(),
      userGrowth:        growth.map((r) => _map(r)).toList(),
    );
  }

  // ── Products ─────────────────────────────────────────────────────────────
  Future<Map<String,dynamic>> listProducts(Session session, {int page=0, int pageSize=20, String? search, int? categoryId, int? brandId, bool? isActive, String sortBy='createdAt', bool sortDesc=true}) =>
      _repo.listProducts(session, page: page, pageSize: pageSize, search: search, categoryId: categoryId, brandId: brandId, isActive: isActive, sortBy: sortBy, sortDesc: sortDesc);

  Future<void> bulkUpdatePrices(Session session, {required List<Map<String,dynamic>> updates, required int adminId}) async {
    await session.db.transaction((tx) async {
      for (final u in updates) {
        await session.db.unsafeQuery('UPDATE "product_variants" SET "price"=@p,"updatedAt"=@now WHERE "id"=@id', parameters: QueryParameters.named({'id': u['variantId'], 'p': (u['price'] as num).toDouble(), 'now': DateTime.now().toUtc()}), transaction: tx);
      }
      await _audit(session, adminId: adminId, action: 'bulk_price_update', entity: 'product_variants', newValue: jsonEncode(updates), transaction: tx);
    });
  }

  Future<void> bulkUpdateStock(Session session, {required List<Map<String,dynamic>> updates, required int adminId}) async {
    await session.db.transaction((tx) async {
      for (final u in updates) {
        await _repo.adjustStock(session, variantId: u['variantId'] as int, newQty: u['qty'] as int, reason: u['reason'] as String? ?? 'Bulk', adminId: adminId, transaction: tx);
      }
      await _audit(session, adminId: adminId, action: 'bulk_stock_update', entity: 'product_variants', transaction: tx);
    });
  }

  // ── Orders ────────────────────────────────────────────────────────────────
  Future<Map<String,dynamic>> listOrders(Session session, {int page=0, int pageSize=20, String? status, String? search, String? dateFrom, String? dateTo}) =>
      _repo.listOrders(session, page: page, pageSize: pageSize, status: status, search: search, dateFrom: dateFrom, dateTo: dateTo);

  // ── Customers ─────────────────────────────────────────────────────────────
  Future<Map<String,dynamic>> listCustomers(Session session, {int page=0, int pageSize=20, String? search, bool? isActive}) =>
      _repo.listCustomers(session, page: page, pageSize: pageSize, search: search, isActive: isActive);

  Future<Map<String,dynamic>> getCustomerDetail(Session session, int userId) =>
      _repo.getCustomerDetail(session, userId);

  Future<void> suspendUser(Session session, {required int userId, required String reason, required int adminId}) async {
    if (reason.trim().isEmpty) throw AdminException('Suspension reason is required.');
    await session.db.transaction((tx) async {
      await _repo.suspendUser(session, userId, reason, adminId, transaction: tx);
      await _audit(session, adminId: adminId, action: 'suspend_user', entity: 'users', entityId: userId, newValue: reason, transaction: tx);
    });
  }

  Future<void> reactivateUser(Session session, {required int userId, required int adminId}) async {
    await session.db.transaction((tx) async {
      await _repo.reactivateUser(session, userId, transaction: tx);
      await _audit(session, adminId: adminId, action: 'reactivate_user', entity: 'users', entityId: userId, transaction: tx);
    });
  }

  Future<void> adminResetPassword(Session session, {required int userId, required String newPassword, required int adminId}) async {
    if (await _users.findById(session, userId) == null) throw AdminException('User not found.');
    // Delegate to PasswordService.hash() in generated project
    await _audit(session, adminId: adminId, action: 'admin_reset_password', entity: 'users', entityId: userId);
  }

  // ── Inventory ─────────────────────────────────────────────────────────────
  Future<Map<String,dynamic>> listInventory(Session session, {int page=0, int pageSize=50, bool? lowStock, bool? outOfStock, String? search}) =>
      _repo.listInventory(session, page: page, pageSize: pageSize, lowStock: lowStock, outOfStock: outOfStock, search: search);

  Future<void> adjustStock(Session session, {required int variantId, required int newQty, required String reason, required int adminId}) async {
    if (newQty < 0) throw AdminException('Stock cannot be negative.');
    if (reason.trim().isEmpty) throw AdminException('Reason is required.');
    await session.db.transaction((tx) async {
      final ok = await _repo.adjustStock(session, variantId: variantId, newQty: newQty, reason: reason, adminId: adminId, transaction: tx);
      if (!ok) throw AdminException('Variant not found.');
      await _audit(session, adminId: adminId, action: 'stock_adjustment', entity: 'product_variants', entityId: variantId, newValue: 'qty=$newQty reason=$reason', transaction: tx);
    });
  }

  // ── Coupons ───────────────────────────────────────────────────────────────
  Future<List<Coupon>> listCoupons(Session session, {bool? isActive}) =>
      _repo.listCoupons(session, isActive: isActive);

  // ── Notifications ─────────────────────────────────────────────────────────
  Future<AdminNotification> createNotification(Session session, {required String title, required String body, required NotificationAudience audience, String? audienceFilter, DateTime? scheduledAt, required int adminId}) async {
    if (title.trim().isEmpty) throw AdminException('Title is required.');
    if (body.trim().isEmpty)  throw AdminException('Body is required.');
    final now = DateTime.now().toUtc();
    final notif = await _repo.createNotification(session, AdminNotification(
      adminId: adminId, title: title.trim(), body: body.trim(),
      audience: audience, audienceFilter: audienceFilter,
      status: scheduledAt != null ? NotificationStatus.scheduled : NotificationStatus.draft,
      scheduledAt: scheduledAt, recipientCount: 0, createdAt: now, updatedAt: now,
    ));
    await _audit(session, adminId: adminId, action: 'create_notification', entity: 'admin_notifications', entityId: notif.id, newValue: title);
    return notif;
  }

  Future<List<AdminNotification>> listNotifications(Session session, {int page=0}) =>
      _repo.listNotifications(session, page: page);

  // ── Analytics ─────────────────────────────────────────────────────────────
  Future<List<Map<String,dynamic>>> getBeautyTechAnalytics(Session session) async {
    final rows = await session.db.unsafeQuery('SELECT * FROM "v_recommendation_acceptance"');
    return rows.map((r) => r.toColumnMap()).toList();
  }

  Future<List<Map<String,dynamic>>> getTopRecommendedVariants(Session session, {int limit=10}) async {
    final rows = await session.db.unsafeQuery('SELECT * FROM "v_top_recommended_variants" ORDER BY "recommendationCount" DESC LIMIT @l', parameters: QueryParameters.named({'l': limit}));
    return rows.map((r) => r.toColumnMap()).toList();
  }

  Future<List<Map<String,dynamic>>> getUndertoneDistribution(Session session) async {
    final rows = await session.db.unsafeQuery('SELECT * FROM "v_undertone_distribution"');
    return rows.map((r) => r.toColumnMap()).toList();
  }

  // ── Audit Logs ────────────────────────────────────────────────────────────
  Future<Map<String,dynamic>> listAuditLogs(Session session, {int page=0, int pageSize=50, String? entity, int? adminId, String? dateFrom}) =>
      _repo.listAuditLogs(session, page: page, pageSize: pageSize, entity: entity, adminId: adminId, dateFrom: dateFrom);

  // ── Internal ──────────────────────────────────────────────────────────────
  Future<void> _audit(Session session, {required int adminId, required String action, required String entity, int? entityId, String? oldValue, String? newValue, Transaction? transaction}) async {
    try {
      await _repo.writeAuditLog(session, AuditLog(adminId: adminId, action: action, entity: entity, entityId: entityId, oldValue: oldValue, newValue: newValue, createdAt: DateTime.now().toUtc()), transaction: transaction);
    } catch (e) {
      SecureLogging.log(session, 'WARN: audit log failed action=$action');
    }
  }
}
