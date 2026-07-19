import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/order_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class OrderEndpoint extends Endpoint {
  final OrderService _orders = OrderService();

  Future<OrderDetail> checkout(Session session, {required String token, required int addressId}) async {
    final user = await AuthGuard.requireUser(session, token);
    return _orders.checkout(session, userId: user.id!, addressId: addressId);
  }

  Future<OrderDetail> getDetails(Session session, {required String token, required int orderId}) async {
    final user = await AuthGuard.requireUser(session, token);
    return _orders.getDetails(session, userId: user.id!, orderId: orderId);
  }

  Future<List<Order>> listMyOrders(Session session, {required String token, int page = 0, int pageSize = 20}) async {
    final user = await AuthGuard.requireUser(session, token);
    return _orders.listForUser(session, userId: user.id!, page: page, pageSize: pageSize);
  }

  Future<OrderDetail> cancel(Session session, {required String token, required int orderId, String? reason}) async {
    final user = await AuthGuard.requireUser(session, token);
    return _orders.cancel(session, userId: user.id!, orderId: orderId, reason: reason);
  }

  /// Admin/staff only \u2014 drives order status forward (Order Tracking is the
  /// read side of this same state machine, exposed to customers via
  /// getDetails().statusHistory).
  Future<OrderDetail> updateStatus(
    Session session, {
    required String token,
    required int orderId,
    required OrderStatus newStatus,
    String? note,
  }) async {
    await AuthGuard.requireAdminOrStaff(session, token);
    return _orders.updateStatus(session, orderId: orderId, newStatus: newStatus, note: note);
  }
}
