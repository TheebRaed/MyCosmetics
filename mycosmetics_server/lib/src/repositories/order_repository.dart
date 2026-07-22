import 'package:serverpod/serverpod.dart' hide Order;
import 'package:mycosmetics_server/src/generated/protocol.dart';

class OrderRepository {
  Future<Order?> findById(Session session, int id) {
    return Order.db.findById(session, id);
  }

  Future<List<Order>> listForUser(Session session, int userId, {int page = 0, int pageSize = 20}) {
    return Order.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: pageSize,
      offset: page * pageSize,
    );
  }

  Future<int> countForUser(Session session, int userId) {
    return Order.db.count(session, where: (t) => t.userId.equals(userId));
  }

  Future<Order> create(Session session, Order order) {
    return Order.db.insertRow(session, order);
  }

  Future<Order> update(Session session, Order order) {
    return Order.db.updateRow(session, order);
  }

  Future<List<OrderItem>> listItems(Session session, int orderId) {
    return OrderItem.db.find(session, where: (t) => t.orderId.equals(orderId));
  }

  Future<OrderItem?> findItemById(Session session, int id) {
    return OrderItem.db.findById(session, id);
  }

  Future<OrderItem> createItem(Session session, OrderItem item) {
    return OrderItem.db.insertRow(session, item);
  }

  Future<List<OrderStatusHistory>> listStatusHistory(Session session, int orderId) {
    return OrderStatusHistory.db.find(
      session,
      where: (t) => t.orderId.equals(orderId),
      orderBy: (t) => t.createdAt,
    );
  }

  Future<OrderStatusHistory> addStatusHistory(Session session, OrderStatusHistory history) {
    return OrderStatusHistory.db.insertRow(session, history);
  }

  /// True if this user has a Delivered order containing this variant —
  /// the DB-level check backing the "verified purchaser" review rule.
  Future<OrderItem?> findDeliveredPurchase(Session session, {required int userId, required int variantId}) async {
    final rows = await session.db.unsafeQuery(
      'SELECT oi.* FROM "order_items" oi '
      'JOIN "orders" o ON o."id" = oi."orderId" '
      'WHERE o."userId" = @userId AND oi."variantId" = @variantId AND o."status" = @status '
      'LIMIT 1',
      parameters: QueryParameters.named({
        'userId': userId,
        'variantId': variantId,
        'status': OrderStatus.delivered.name,
      }),
    );
    if (rows.isEmpty) return null;
    return OrderItem.fromJson(rows.first.toColumnMap());
  }
}
