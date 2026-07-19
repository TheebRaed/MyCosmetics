import 'package:freezed_annotation/freezed_annotation.dart';
part 'admin_models.freezed.dart';
part 'admin_models.g.dart';

@freezed class DashboardOverview with _$DashboardOverview {
  const factory DashboardOverview({@Default(0) double revenueTotal, @Default(0) double revenueToday, @Default(0) double revenueThisMonth, @Default(0) int totalOrders, @Default(0) int pendingOrders, @Default(0) int processingOrders, @Default(0) int completedOrders, @Default(0) int cancelledOrders, @Default(0) int activeCustomers, @Default(0) int registeredUsers, @Default(0) int totalProducts, @Default(0) int lowStockProducts, @Default(0) int outOfStockProducts}) = _DashboardOverview;
  factory DashboardOverview.fromJson(Map<String,dynamic> j) => _$DashboardOverviewFromJson(j);
}

@freezed class SalesDataPoint with _$SalesDataPoint {
  const factory SalesDataPoint({required String label, @Default(0) double revenue, @Default(0) int orderCount}) = _SalesDataPoint;
  factory SalesDataPoint.fromJson(Map<String,dynamic> j) => _$SalesDataPointFromJson(j);
}

@freezed class DashboardCharts with _$DashboardCharts {
  const factory DashboardCharts({@Default([]) List<SalesDataPoint> dailySales, @Default([]) List<SalesDataPoint> monthlySales, @Default([]) List<SalesDataPoint> revenueByCategory, @Default([]) List<SalesDataPoint> revenueByBrand, @Default([]) List<SalesDataPoint> userGrowth}) = _DashboardCharts;
  factory DashboardCharts.fromJson(Map<String,dynamic> j) => _$DashboardChartsFromJson(j);
}

@freezed class AdminProductRow with _$AdminProductRow {
  const factory AdminProductRow({required int id, @Default('') String name, @Default('') String categoryName, @Default('') String brandName, @Default(0) double basePrice, @Default(0) int totalStock, @Default(0) int variantCount, @Default(true) bool isActive, @Default(false) bool isFeatured, @Default(0) double ratingAvg}) = _AdminProductRow;
  factory AdminProductRow.fromJson(Map<String,dynamic> j) => _$AdminProductRowFromJson(j);
}

@freezed class AdminOrderRow with _$AdminOrderRow {
  const factory AdminOrderRow({required int id, @Default('') String customerName, @Default('') String customerEmail, @Default('pending') String status, @Default('unpaid') String paymentStatus, @Default(0) double total, @Default(0) int itemCount, @Default('') String createdAt}) = _AdminOrderRow;
  factory AdminOrderRow.fromJson(Map<String,dynamic> j) => _$AdminOrderRowFromJson(j);
}

@freezed class AdminCustomerRow with _$AdminCustomerRow {
  const factory AdminCustomerRow({required int id, @Default('') String fullName, @Default('') String email, String? phone, @Default('customer') String role, @Default(true) bool isActive, @Default(0) int orderCount, @Default(0) double totalSpent, @Default('') String createdAt, String? lastActiveAt}) = _AdminCustomerRow;
  factory AdminCustomerRow.fromJson(Map<String,dynamic> j) => _$AdminCustomerRowFromJson(j);
}

@freezed class InventoryRow with _$InventoryRow {
  const factory InventoryRow({required int variantId, required int productId, @Default('') String productName, String? shadeName, @Default('') String sku, @Default(0) int stockQty, @Default(true) bool isActive, @Default(false) bool isLowStock, @Default(false) bool isOutOfStock}) = _InventoryRow;
  factory InventoryRow.fromJson(Map<String,dynamic> j) => _$InventoryRowFromJson(j);
}

@freezed class AuditLogRow with _$AuditLogRow {
  const factory AuditLogRow({required int id, @Default('') String adminName, @Default('') String action, @Default('') String entity, int? entityId, String? oldValue, String? newValue, @Default('') String createdAt}) = _AuditLogRow;
  factory AuditLogRow.fromJson(Map<String,dynamic> j) => _$AuditLogRowFromJson(j);
}

@freezed class AdminCoupon with _$AdminCoupon {
  const factory AdminCoupon({required int id, required String code, required String type, required double value, @Default(0) double minSpend, double? maxDiscount, int? usageLimit, @Default(0) int usedCount, String? expiresAt, @Default(true) bool isActive}) = _AdminCoupon;
  factory AdminCoupon.fromJson(Map<String,dynamic> j) => _$AdminCouponFromJson(j);
}

@freezed class AdminNotificationModel with _$AdminNotificationModel {
  const factory AdminNotificationModel({required int id, required String title, required String body, @Default('allUsers') String audience, String? audienceFilter, @Default('draft') String status, String? scheduledAt, String? sentAt, @Default(0) int recipientCount, required String createdAt}) = _AdminNotificationModel;
  factory AdminNotificationModel.fromJson(Map<String,dynamic> j) => _$AdminNotificationModelFromJson(j);
}

class PaginatedData<T> {
  const PaginatedData({required this.items, required this.totalCount, required this.page, required this.pageSize});
  final List<T> items; final int totalCount, page, pageSize;
  bool get hasMore => (page+1)*pageSize < totalCount;
  int  get totalPages => totalCount == 0 ? 1 : (totalCount/pageSize).ceil();
}
