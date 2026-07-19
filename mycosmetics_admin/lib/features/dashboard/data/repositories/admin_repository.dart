import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/network/admin_api_client.dart';
import '../models/admin_models.dart';
part 'admin_repository.g.dart';

@riverpod AdminRepository adminRepository(Ref ref) => AdminRepository(ref.watch(adminApiClientProvider));

class AdminRepository {
  AdminRepository(this._api);
  final AdminApiClient _api;

  Future<Map<String,dynamic>> login(String email, String password) =>
      _api.post(endpoint: 'auth', method: 'login', body: {'email': email, 'password': password}, fromJson: (j) => j as Map<String,dynamic>);

  Future<DashboardOverview> getOverview() =>
      _api.post(endpoint: 'admin', method: 'getDashboardOverview', fromJson: (j) => DashboardOverview.fromJson(j as Map<String,dynamic>));

  Future<DashboardCharts> getCharts() =>
      _api.post(endpoint: 'admin', method: 'getDashboardCharts', fromJson: (j) => DashboardCharts.fromJson(j as Map<String,dynamic>));

  Future<Map<String,dynamic>> listProducts({int page=0, int pageSize=20, String? search, int? categoryId, int? brandId, bool? isActive, String sortBy='createdAt', bool sortDesc=true}) =>
      _api.post(endpoint: 'admin', method: 'listProducts', body: {'page':page,'pageSize':pageSize,if(search!=null)'search':search,if(categoryId!=null)'categoryId':categoryId,if(brandId!=null)'brandId':brandId,if(isActive!=null)'isActive':isActive,'sortBy':sortBy,'sortDesc':sortDesc}, fromJson: (j) => j as Map<String,dynamic>);

  Future<Map<String,dynamic>> listOrders({int page=0, int pageSize=20, String? status, String? search, String? dateFrom, String? dateTo}) =>
      _api.post(endpoint: 'admin', method: 'listOrders', body: {'page':page,'pageSize':pageSize,if(status!=null)'status':status,if(search!=null)'search':search,if(dateFrom!=null)'dateFrom':dateFrom,if(dateTo!=null)'dateTo':dateTo}, fromJson: (j) => j as Map<String,dynamic>);

  Future<void> updateOrderStatus(int orderId, String newStatus, {String? note}) =>
      _api.post(endpoint: 'order', method: 'updateStatus', body: {'orderId':orderId,'newStatus':newStatus,if(note!=null)'note':note}, fromJson: (_) => null);

  Future<Map<String,dynamic>> listCustomers({int page=0, int pageSize=20, String? search, bool? isActive}) =>
      _api.post(endpoint: 'admin', method: 'listCustomers', body: {'page':page,'pageSize':pageSize,if(search!=null)'search':search,if(isActive!=null)'isActive':isActive}, fromJson: (j) => j as Map<String,dynamic>);

  Future<Map<String,dynamic>> getCustomerDetail(int userId) =>
      _api.post(endpoint: 'admin', method: 'getCustomerDetail', body: {'userId':userId}, fromJson: (j) => j as Map<String,dynamic>);

  Future<void> suspendUser(int userId, String reason) =>
      _api.post(endpoint: 'admin', method: 'suspendUser', body: {'userId':userId,'reason':reason}, fromJson: (_) => null);

  Future<void> reactivateUser(int userId) =>
      _api.post(endpoint: 'admin', method: 'reactivateUser', body: {'userId':userId}, fromJson: (_) => null);

  Future<Map<String,dynamic>> listInventory({int page=0, int pageSize=50, bool? lowStock, bool? outOfStock, String? search}) =>
      _api.post(endpoint: 'admin', method: 'listInventory', body: {'page':page,'pageSize':pageSize,if(lowStock!=null)'lowStock':lowStock,if(outOfStock!=null)'outOfStock':outOfStock,if(search!=null)'search':search}, fromJson: (j) => j as Map<String,dynamic>);

  Future<void> adjustStock(int variantId, int newQty, String reason) =>
      _api.post(endpoint: 'admin', method: 'adjustStock', body: {'variantId':variantId,'newQty':newQty,'reason':reason}, fromJson: (_) => null);

  Future<List<Map<String,dynamic>>> listCoupons({bool? isActive}) =>
      _api.postList(endpoint: 'admin', method: 'listCoupons', body: {if(isActive!=null)'isActive':isActive}, fromJson: (j) => j);

  Future<void> createCoupon({required String code, required String type, required double value, double minSpend=0, double? maxDiscount, int? usageLimit, String? expiresAt}) =>
      _api.post(endpoint: 'coupon', method: 'create', body: {'code':code,'type':type,'value':value,'minSpend':minSpend,if(maxDiscount!=null)'maxDiscount':maxDiscount,if(usageLimit!=null)'usageLimit':usageLimit,if(expiresAt!=null)'expiresAt':expiresAt}, fromJson: (_) => null);

  Future<void> setCouponActive(int id, bool isActive) =>
      _api.post(endpoint: 'coupon', method: 'setActive', body: {'id':id,'isActive':isActive}, fromJson: (_) => null);

  Future<List<Map<String,dynamic>>> listNotifications({int page=0}) =>
      _api.postList(endpoint: 'admin', method: 'listNotifications', body: {'page':page}, fromJson: (j) => j);

  Future<void> createNotification({required String title, required String body, required String audience, String? audienceFilter, String? scheduledAt}) =>
      _api.post(endpoint: 'admin', method: 'createNotification', body: {'title':title,'body':body,'audience':audience,if(audienceFilter!=null)'audienceFilter':audienceFilter,if(scheduledAt!=null)'scheduledAt':scheduledAt}, fromJson: (_) => null);

  Future<List<Map<String,dynamic>>> getBeautyTechAnalytics() =>
      _api.postList(endpoint: 'admin', method: 'getBeautyTechAnalytics', fromJson: (j) => j);

  Future<List<Map<String,dynamic>>> getTopRecommended({int limit=10}) =>
      _api.postList(endpoint: 'admin', method: 'getTopRecommendedVariants', body: {'limit':limit}, fromJson: (j) => j);

  Future<List<Map<String,dynamic>>> getUndertoneDistribution() =>
      _api.postList(endpoint: 'admin', method: 'getUndertoneDistribution', fromJson: (j) => j);

  Future<Map<String,dynamic>> listAuditLogs({int page=0, int pageSize=50, String? entity, int? adminId, String? dateFrom}) =>
      _api.post(endpoint: 'admin', method: 'listAuditLogs', body: {'page':page,'pageSize':pageSize,if(entity!=null)'entity':entity,if(adminId!=null)'adminId':adminId,if(dateFrom!=null)'dateFrom':dateFrom}, fromJson: (j) => j as Map<String,dynamic>);
}
