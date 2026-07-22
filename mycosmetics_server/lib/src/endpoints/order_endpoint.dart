import 'package:serverpod/serverpod.dart' hide Order;
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/order_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class OrderEndpoint extends Endpoint {
  final OrderService _orders = OrderService();

  Future<OrderDetail> checkout(Session session, {required int addressId}) async {
    final user = await AuthGuard.requireUser(session);
    return _orders.checkout(session, userId: user.id!, addressId: addressId);
  }

  Future<OrderDetail> getDetails(Session session, {required int orderId}) async {
    final user = await AuthGuard.requireUser(session);
    return _orders.getDetails(session, userId: user.id!, orderId: orderId);
  }

  Future<List<Order>> listMyOrders(Session session, {int page = 0, int pageSize = 20}) async {
    final user = await AuthGuard.requireUser(session);
    return _orders.listForUser(session, userId: user.id!, page: page, pageSize: pageSize);
  }

  Future<OrderDetail> cancel(Session session, {required int orderId, String? reason}) async {
    final user = await AuthGuard.requireUser(session);
    return _orders.cancel(session, userId: user.id!, orderId: orderId, reason: reason);
  }

  /// Admin/staff only - drives order status forward (Order Tracking is the
  /// read side of this same state machine, exposed to customers via
  /// getDetails().statusHistory).
  Future<OrderDetail> updateStatus(
    Session session, {
    required int orderId,
    required OrderStatus newStatus,
    String? note,
  }) async {
    await AuthGuard.requireAdminOrStaff(session);
    return _orders.updateStatus(session, orderId: orderId, newStatus: newStatus, note: note);
  }
}
