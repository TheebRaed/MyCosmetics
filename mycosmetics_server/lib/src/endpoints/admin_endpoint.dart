import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/admin_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class AdminEndpoint extends Endpoint {
  final AdminService _svc = AdminService();

  Future<DashboardOverview> getDashboardOverview(Session session) async {
    await AuthGuard.requirePermission(session, 'reports:read');
    return _svc.getDashboardOverview(session);
  }

  Future<DashboardCharts> getDashboardCharts(Session session) async {
    await AuthGuard.requirePermission(session, 'reports:read');
    return _svc.getDashboardCharts(session);
  }

  Future<Map<String,dynamic>> listProducts(Session session, {int page=0, int pageSize=20, String? search, int? categoryId, int? brandId, bool? isActive, String sortBy='createdAt', bool sortDesc=true}) async {
    await AuthGuard.requirePermission(session, 'products:read');
    return _svc.listProducts(session, page: page, pageSize: pageSize, search: search, categoryId: categoryId, brandId: brandId, isActive: isActive, sortBy: sortBy, sortDesc: sortDesc);
  }

  Future<void> bulkUpdatePrices(Session session, {required List<Map<String,dynamic>> updates}) async {
    final u = await AuthGuard.requirePermission(session, 'products:write');
    await _svc.bulkUpdatePrices(session, updates: updates, adminId: u.id!);
  }

  Future<void> bulkUpdateStock(Session session, {required List<Map<String,dynamic>> updates}) async {
    final u = await AuthGuard.requirePermission(session, 'inventory:write');
    await _svc.bulkUpdateStock(session, updates: updates, adminId: u.id!);
  }

  Future<Map<String,dynamic>> listOrders(Session session, {int page=0, int pageSize=20, String? status, String? search, String? dateFrom, String? dateTo}) async {
    await AuthGuard.requirePermission(session, 'orders:read');
    return _svc.listOrders(session, page: page, pageSize: pageSize, status: status, search: search, dateFrom: dateFrom, dateTo: dateTo);
  }

  Future<Map<String,dynamic>> listCustomers(Session session, {int page=0, int pageSize=20, String? search, bool? isActive}) async {
    await AuthGuard.requirePermission(session, 'customers:read');
    return _svc.listCustomers(session, page: page, pageSize: pageSize, search: search, isActive: isActive);
  }

  Future<Map<String,dynamic>> getCustomerDetail(Session session, {required int userId}) async {
    await AuthGuard.requirePermission(session, 'customers:read');
    return _svc.getCustomerDetail(session, userId);
  }

  Future<void> suspendUser(Session session, {required int userId, required String reason}) async {
    final a = await AuthGuard.requirePermission(session, 'customers:write');
    await _svc.suspendUser(session, userId: userId, reason: reason, adminId: a.id!);
  }

  Future<void> reactivateUser(Session session, {required int userId}) async {
    final a = await AuthGuard.requirePermission(session, 'customers:write');
    await _svc.reactivateUser(session, userId: userId, adminId: a.id!);
  }

  Future<void> adminResetPassword(Session session, {required int userId, required String newPassword}) async {
    final a = await AuthGuard.requirePermission(session, 'customers:support');
    await _svc.adminResetPassword(session, userId: userId, newPassword: newPassword, adminId: a.id!);
  }

  Future<Map<String,dynamic>> listInventory(Session session, {int page=0, int pageSize=50, bool? lowStock, bool? outOfStock, String? search}) async {
    await AuthGuard.requirePermission(session, 'inventory:read');
    return _svc.listInventory(session, page: page, pageSize: pageSize, lowStock: lowStock, outOfStock: outOfStock, search: search);
  }

  Future<void> adjustStock(Session session, {required int variantId, required int newQty, required String reason}) async {
    final a = await AuthGuard.requirePermission(session, 'inventory:write');
    await _svc.adjustStock(session, variantId: variantId, newQty: newQty, reason: reason, adminId: a.id!);
  }

  Future<List<Coupon>> listCoupons(Session session, {bool? isActive}) async {
    await AuthGuard.requirePermission(session, 'coupons:read');
    return _svc.listCoupons(session, isActive: isActive);
  }

  Future<AdminNotification> createNotification(Session session, {required String title, required String body, required String audience, String? audienceFilter, String? scheduledAt}) async {
    final a = await AuthGuard.requirePermission(session, 'notifications:write');
    final aud = NotificationAudience.values.firstWhere((e) => e.name == audience, orElse: () => NotificationAudience.allUsers);
    return _svc.createNotification(session, title: title, body: body, audience: aud, audienceFilter: audienceFilter, scheduledAt: scheduledAt != null ? DateTime.parse(scheduledAt) : null, adminId: a.id!);
  }

  Future<List<AdminNotification>> listNotifications(Session session, {int page=0}) async {
    await AuthGuard.requirePermission(session, 'notifications:write');
    return _svc.listNotifications(session, page: page);
  }

  Future<List<Map<String,dynamic>>> getBeautyTechAnalytics(Session session) async {
    await AuthGuard.requirePermission(session, 'analytics:read');
    return _svc.getBeautyTechAnalytics(session);
  }

  Future<List<Map<String,dynamic>>> getTopRecommendedVariants(Session session, {int limit=10}) async {
    await AuthGuard.requirePermission(session, 'analytics:read');
    return _svc.getTopRecommendedVariants(session, limit: limit);
  }

  Future<List<Map<String,dynamic>>> getUndertoneDistribution(Session session) async {
    await AuthGuard.requirePermission(session, 'analytics:read');
    return _svc.getUndertoneDistribution(session);
  }

  Future<Map<String,dynamic>> listAuditLogs(Session session, {int page=0, int pageSize=50, String? entity, int? adminId, String? dateFrom}) async {
    await AuthGuard.requirePermission(session, 'audit:read');
    return _svc.listAuditLogs(session, page: page, pageSize: pageSize, entity: entity, adminId: adminId, dateFrom: dateFrom);
  }
}
