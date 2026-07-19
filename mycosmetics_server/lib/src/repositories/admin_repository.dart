import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class AdminRepository {

  Future<Map<String,dynamic>> fetchOverviewKpis(Session session) async {
    final now = DateTime.now().toUtc();
    final todayStart = DateTime(now.year,now.month,now.day).toUtc();
    final monthStart = DateTime(now.year,now.month,1).toUtc();
    final rows = await session.db.unsafeQuery('''
      SELECT
        (SELECT COALESCE(SUM("total"),0) FROM "orders" WHERE "status"!='cancelled') AS "revenueTotal",
        (SELECT COALESCE(SUM("total"),0) FROM "orders" WHERE "status"!='cancelled' AND "createdAt">=@ts) AS "revenueToday",
        (SELECT COALESCE(SUM("total"),0) FROM "orders" WHERE "status"!='cancelled' AND "createdAt">=@ms) AS "revenueThisMonth",
        (SELECT COUNT(*) FROM "orders") AS "totalOrders",
        (SELECT COUNT(*) FROM "orders" WHERE "status"='pending') AS "pendingOrders",
        (SELECT COUNT(*) FROM "orders" WHERE "status"='processing') AS "processingOrders",
        (SELECT COUNT(*) FROM "orders" WHERE "status"='delivered') AS "completedOrders",
        (SELECT COUNT(*) FROM "orders" WHERE "status"='cancelled') AS "cancelledOrders",
        (SELECT COUNT(DISTINCT "userId") FROM "orders" WHERE "createdAt">=@ms) AS "activeCustomers",
        (SELECT COUNT(*) FROM "users" WHERE "deletedAt" IS NULL AND "role"='customer') AS "registeredUsers",
        (SELECT COUNT(*) FROM "products" WHERE "deletedAt" IS NULL AND "isActive"=true) AS "totalProducts",
        (SELECT COUNT(*) FROM "product_variants" WHERE "isActive"=true AND "stockQty">0 AND "stockQty"<=10) AS "lowStockProducts",
        (SELECT COUNT(*) FROM "product_variants" WHERE "isActive"=true AND "stockQty"=0) AS "outOfStockProducts"
    ''', parameters: QueryParameters.named({'ts': todayStart, 'ms': monthStart}));
    return rows.first.toColumnMap();
  }

  Future<List<Map<String,dynamic>>> fetchDailySales(Session s) async => (await s.db.unsafeQuery('SELECT * FROM "v_daily_revenue" LIMIT 90')).map((r)=>r.toColumnMap()).toList();
  Future<List<Map<String,dynamic>>> fetchMonthlySales(Session s) async => (await s.db.unsafeQuery('SELECT * FROM "v_monthly_revenue" LIMIT 12')).map((r)=>r.toColumnMap()).toList();
  Future<List<Map<String,dynamic>>> fetchRevenueByCategory(Session s) async => (await s.db.unsafeQuery('SELECT * FROM "v_revenue_by_category" ORDER BY "revenue" DESC LIMIT 10')).map((r)=>r.toColumnMap()).toList();
  Future<List<Map<String,dynamic>>> fetchRevenueByBrand(Session s) async => (await s.db.unsafeQuery('SELECT * FROM "v_revenue_by_brand" LIMIT 10')).map((r)=>r.toColumnMap()).toList();
  Future<List<Map<String,dynamic>>> fetchUserGrowth(Session s) async => (await s.db.unsafeQuery('SELECT * FROM "v_user_growth" LIMIT 90')).map((r)=>r.toColumnMap()).toList();

  Future<Map<String,dynamic>> listProducts(Session session, {int page=0, int pageSize=20, String? search, int? categoryId, int? brandId, bool? isActive, String sortBy='createdAt', bool sortDesc=true}) async {
    final conds = <String>['p."deletedAt" IS NULL'];
    final params = <String,dynamic>{'limit':pageSize,'offset':page*pageSize};
    if (search!=null && search.isNotEmpty) { conds.add('p."name" ILIKE @search'); params['search']='%$search%'; }
    if (categoryId!=null) { conds.add('p."categoryId"=@cat'); params['cat']=categoryId; }
    if (brandId!=null) { conds.add('p."brandId"=@brand'); params['brand']=brandId; }
    if (isActive!=null) { conds.add('p."isActive"=@active'); params['active']=isActive; }
    final where = conds.join(' AND ');
    final orderCol = {'name':'p."name"','price':'p."basePrice"'}[sortBy] ?? 'p."createdAt"';
    final dir = sortDesc ? 'DESC' : 'ASC';
    final total = await session.db.unsafeQuery('SELECT COUNT(*) AS cnt FROM "products" p WHERE $where', parameters: QueryParameters.named(params));
    final totalCount = (total.first.toColumnMap()['cnt'] as BigInt).toInt();
    final rows = await session.db.unsafeQuery('''
      SELECT p."id",p."name",p."basePrice",p."isActive",p."isFeatured",p."ratingAvg",
             c."name" AS "categoryName",b."name" AS "brandName",
             COALESCE(SUM(pv."stockQty"),0) AS "total_stock",COUNT(pv."id") AS "variantCount"
      FROM "products" p JOIN "categories" c ON c."id"=p."categoryId" JOIN "brands" b ON b."id"=p."brandId"
      LEFT JOIN "product_variants" pv ON pv."productId"=p."id" AND pv."isActive"=true
      WHERE $where GROUP BY p."id",p."name",p."basePrice",p."isActive",p."isFeatured",p."ratingAvg",c."name",b."name"
      ORDER BY $orderCol $dir LIMIT @limit OFFSET @offset
    ''', parameters: QueryParameters.named(params));
    return {'totalCount':totalCount,'rows':rows.map((r)=>r.toColumnMap()).toList()};
  }

  Future<Map<String,dynamic>> listOrders(Session session, {int page=0, int pageSize=20, String? status, String? search, String? dateFrom, String? dateTo}) async {
    final conds = <String>['1=1'];
    final params = <String,dynamic>{'limit':pageSize,'offset':page*pageSize};
    if (status!=null) { conds.add('o."status"=@status'); params['status']=status; }
    if (search!=null && search.isNotEmpty) { conds.add('(u."fullName" ILIKE @search OR u."email" ILIKE @search)'); params['search']='%$search%'; }
    if (dateFrom!=null) { conds.add('o."createdAt">=@df'); params['df']=DateTime.parse(dateFrom); }
    if (dateTo!=null) { conds.add('o."createdAt"<=@dt'); params['dt']=DateTime.parse(dateTo); }
    final where = conds.join(' AND ');
    final total = await session.db.unsafeQuery('SELECT COUNT(*) AS cnt FROM "orders" o JOIN "users" u ON u."id"=o."userId" WHERE $where', parameters: QueryParameters.named(params));
    final totalCount = (total.first.toColumnMap()['cnt'] as BigInt).toInt();
    final rows = await session.db.unsafeQuery('''
      SELECT o."id",o."status",o."total",o."createdAt",u."fullName" AS "customerName",u."email" AS "customerEmail",
             COALESCE(o."paymentStatus",'unpaid') AS "paymentStatus",
             (SELECT COUNT(*) FROM "order_items" oi WHERE oi."orderId"=o."id") AS "itemCount"
      FROM "orders" o JOIN "users" u ON u."id"=o."userId" WHERE $where ORDER BY o."createdAt" DESC LIMIT @limit OFFSET @offset
    ''', parameters: QueryParameters.named(params));
    return {'totalCount':totalCount,'rows':rows.map((r)=>r.toColumnMap()).toList()};
  }

  Future<Map<String,dynamic>> listCustomers(Session session, {int page=0, int pageSize=20, String? search, bool? isActive}) async {
    final conds = <String>['"deletedAt" IS NULL','"role"=\'customer\''];
    final params = <String,dynamic>{'limit':pageSize,'offset':page*pageSize};
    if (search!=null && search.isNotEmpty) { conds.add('("fullName" ILIKE @search OR "email" ILIKE @search)'); params['search']='%$search%'; }
    if (isActive==true) conds.add('"suspendedAt" IS NULL');
    if (isActive==false) conds.add('"suspendedAt" IS NOT NULL');
    final where = conds.join(' AND ');
    final total = await session.db.unsafeQuery('SELECT COUNT(*) AS cnt FROM "users" WHERE $where', parameters: QueryParameters.named(params));
    final totalCount = (total.first.toColumnMap()['cnt'] as BigInt).toInt();
    final rows = await session.db.unsafeQuery('''
      SELECT u."id",u."fullName",u."email",u."phone",u."role",(u."suspendedAt" IS NULL) AS "isActive",u."createdAt",u."lastActiveAt",
             COALESCE(s."orderCount",0) AS "orderCount",COALESCE(s."totalSpent",0) AS "totalSpent"
      FROM "users" u LEFT JOIN LATERAL (SELECT COUNT(*) AS "orderCount",COALESCE(SUM("total"),0) AS "totalSpent" FROM "orders" WHERE "userId"=u."id" AND "status"!='cancelled') s ON true
      WHERE $where ORDER BY u."createdAt" DESC LIMIT @limit OFFSET @offset
    ''', parameters: QueryParameters.named(params));
    return {'totalCount':totalCount,'rows':rows.map((r)=>r.toColumnMap()).toList()};
  }

  Future<Map<String,dynamic>> getCustomerDetail(Session session, int userId) async {
    final rows = await session.db.unsafeQuery('''
      SELECT u.*,COALESCE(s."orderCount",0) AS "orderCount",COALESCE(s."totalSpent",0) AS "totalSpent",COALESCE(s."avgOrderValue",0) AS "avgOrderValue"
      FROM "users" u LEFT JOIN LATERAL (SELECT COUNT(*) AS "orderCount",COALESCE(SUM("total"),0) AS "totalSpent",COALESCE(AVG("total"),0) AS "avgOrderValue" FROM "orders" WHERE "userId"=u."id" AND "status"!='cancelled') s ON true
      WHERE u."id"=@id
    ''', parameters: QueryParameters.named({'id':userId}));
    if (rows.isEmpty) return {};
    return rows.first.toColumnMap();
  }

  Future<void> suspendUser(Session session, int userId, String reason, int adminId, {Transaction? transaction}) async {
    await session.db.unsafeQuery('UPDATE "users" SET "suspendedAt"=@now,"suspendedReason"=@reason,"updatedAt"=@now WHERE "id"=@id', parameters: QueryParameters.named({'id':userId,'reason':reason,'now':DateTime.now().toUtc()}), transaction: transaction);
  }

  Future<void> reactivateUser(Session session, int userId, {Transaction? transaction}) async {
    await session.db.unsafeQuery('UPDATE "users" SET "suspendedAt"=NULL,"suspendedReason"=NULL,"updatedAt"=@now WHERE "id"=@id', parameters: QueryParameters.named({'id':userId,'now':DateTime.now().toUtc()}), transaction: transaction);
  }

  Future<Map<String,dynamic>> listInventory(Session session, {int page=0, int pageSize=50, bool? lowStock, bool? outOfStock, String? search}) async {
    final conds = <String>['p."deletedAt" IS NULL'];
    final params = <String,dynamic>{'limit':pageSize,'offset':page*pageSize};
    if (lowStock==true) conds.add('pv."stockQty">0 AND pv."stockQty"<=10');
    if (outOfStock==true) conds.add('pv."stockQty"=0');
    if (search!=null && search.isNotEmpty) { conds.add('(p."name" ILIKE @search OR pv."sku" ILIKE @search)'); params['search']='%$search%'; }
    final where = conds.join(' AND ');
    final total = await session.db.unsafeQuery('SELECT COUNT(*) AS cnt FROM "product_variants" pv JOIN "products" p ON p."id"=pv."productId" WHERE $where', parameters: QueryParameters.named(params));
    final totalCount = (total.first.toColumnMap()['cnt'] as BigInt).toInt();
    final rows = await session.db.unsafeQuery('''
      SELECT pv."id" AS "variantId",p."id" AS "productId",p."name" AS "productName",pv."shadeName",pv."sku",pv."stockQty",pv."isActive",
             (pv."stockQty">0 AND pv."stockQty"<=10) AS "isLowStock",(pv."stockQty"=0) AS "isOutOfStock"
      FROM "product_variants" pv JOIN "products" p ON p."id"=pv."productId" WHERE $where ORDER BY pv."stockQty" ASC LIMIT @limit OFFSET @offset
    ''', parameters: QueryParameters.named(params));
    return {'totalCount':totalCount,'rows':rows.map((r)=>r.toColumnMap()).toList()};
  }

  Future<bool> adjustStock(Session session, {required int variantId, required int newQty, required String reason, required int adminId, Transaction? transaction}) async {
    final curr = await session.db.unsafeQuery('SELECT "stockQty" FROM "product_variants" WHERE "id"=@id', parameters: QueryParameters.named({'id':variantId}), transaction: transaction);
    if (curr.isEmpty) return false;
    final prev = curr.first.toColumnMap()['stockQty'] as int;
    await session.db.unsafeQuery('UPDATE "product_variants" SET "stockQty"=@qty,"updatedAt"=@now WHERE "id"=@id', parameters: QueryParameters.named({'id':variantId,'qty':newQty,'now':DateTime.now().toUtc()}), transaction: transaction);
    await StockAdjustment.db.insertRow(session, StockAdjustment(variantId: variantId, adminId: adminId, previousQty: prev, newQty: newQty, delta: newQty-prev, reason: reason, createdAt: DateTime.now().toUtc()), transaction: transaction);
    return true;
  }

  Future<List<Coupon>> listCoupons(Session session, {bool? isActive}) {
    if (isActive!=null) return Coupon.db.find(session, where: (t)=>t.isActive.equals(isActive), orderBy: (t)=>t.createdAt, orderDescending: true);
    return Coupon.db.find(session, orderBy: (t)=>t.createdAt, orderDescending: true);
  }

  Future<AdminNotification> createNotification(Session session, AdminNotification n, {Transaction? transaction}) => AdminNotification.db.insertRow(session, n, transaction: transaction);
  Future<List<AdminNotification>> listNotifications(Session session, {int page=0, int pageSize=20}) => AdminNotification.db.find(session, orderBy: (t)=>t.createdAt, orderDescending: true, limit: pageSize, offset: page*pageSize);

  Future<AuditLog> writeAuditLog(Session session, AuditLog log, {Transaction? transaction}) => AuditLog.db.insertRow(session, log, transaction: transaction);

  Future<Map<String,dynamic>> listAuditLogs(Session session, {int page=0, int pageSize=50, String? entity, int? adminId, String? dateFrom}) async {
    final conds = <String>['1=1'];
    final params = <String,dynamic>{'limit':pageSize,'offset':page*pageSize};
    if (entity!=null) { conds.add('al."entity"=@entity'); params['entity']=entity; }
    if (adminId!=null) { conds.add('al."adminId"=@adminId'); params['adminId']=adminId; }
    if (dateFrom!=null) { conds.add('al."createdAt">=@df'); params['df']=DateTime.parse(dateFrom); }
    final where = conds.join(' AND ');
    final total = await session.db.unsafeQuery('SELECT COUNT(*) AS cnt FROM "audit_logs" al WHERE $where', parameters: QueryParameters.named(params));
    final totalCount = (total.first.toColumnMap()['cnt'] as BigInt).toInt();
    final rows = await session.db.unsafeQuery('''
      SELECT al."id",al."action",al."entity",al."entityId",al."oldValue",al."newValue",al."createdAt",u."fullName" AS "adminName"
      FROM "audit_logs" al JOIN "users" u ON u."id"=al."adminId" WHERE $where ORDER BY al."createdAt" DESC LIMIT @limit OFFSET @offset
    ''', parameters: QueryParameters.named(params));
    return {'totalCount':totalCount,'rows':rows.map((r)=>r.toColumnMap()).toList()};
  }

  Future<List<Map<String,dynamic>>> topTriedVariants(Session session, {int limit=10}) async {
    final rows = await session.db.unsafeQuery('SELECT * FROM "v_top_recommended_variants" ORDER BY "recommendationCount" DESC LIMIT @limit', parameters: QueryParameters.named({'limit':limit}));
    return rows.map((r)=>r.toColumnMap()).toList();
  }
}
