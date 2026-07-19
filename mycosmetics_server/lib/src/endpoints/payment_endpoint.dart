import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/payment_service.dart';
import 'package:mycosmetics_server/src/business/shipping_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class PaymentEndpoint extends Endpoint {
  final PaymentService  _payments = PaymentService();
  final ShippingService _shipping = ShippingService();

  Future<Map<String, dynamic>> initiatePayment(
    Session session, {
    required int orderId,
    required String provider,
    required String method,
    required String idempotencyKey,
  }) async {
    final userId = await AuthGuard.requireUserId(session);
    // Validate order ownership
    final order = await Order.db.findById(session, orderId);
    if (order == null || order.userId != userId) {
      throw Exception('Order not found.');
    }
    final prov = PaymentProvider.values.firstWhere(
      (e) => e.name == provider,
      orElse: () => throw Exception('Invalid payment provider: $provider'),
    );
    final meth = PaymentMethod.values.firstWhere(
      (e) => e.name == method,
      orElse: () => throw Exception('Invalid payment method: $method'),
    );
    return _payments.initiatePayment(session,
      orderId: orderId,
      provider: prov,
      method: meth,
      amount: order.total,
      currency: 'USD',
      idempotencyKey: idempotencyKey,
    );
  }

  Future<void> confirmCodCollection(
    Session session, {
    required int paymentId,
    required String receiptNumber,
  }) async {
    final admin = await AuthGuard.requirePermission(session, 'orders:update');
    await _payments.confirmCodCollection(session,
      paymentId: paymentId,
      receiptNumber: receiptNumber,
      adminId: admin.id!,
    );
  }

  Future<Map<String, dynamic>?> getPaymentForOrder(
    Session session, {required int orderId}) async {
    final userId = await AuthGuard.requireUserId(session);
    final order = await Order.db.findById(session, orderId);
    if (order == null || order.userId != userId) throw Exception('Order not found.');
    final payment = await _payments.getPaymentForOrder(session, orderId);
    if (payment == null) return null;
    return {
      'id': payment.id,
      'status': payment.status.name,
      'provider': payment.provider.name,
      'amount': payment.amount,
      'currency': payment.currency,
      'paidAt': payment.paidAt?.toIso8601String(),
    };
  }

  Future<Map<String, dynamic>> requestRefund(
    Session session, {
    required int orderId,
    required int paymentId,
    required String reason,
    required double amount,
  }) async {
    final userId = await AuthGuard.requireUserId(session);
    final req = await _payments.requestRefund(session,
      orderId: orderId, userId: userId,
      paymentId: paymentId, reason: reason, amount: amount,
    );
    return {'refundRequestId': req.id, 'status': req.status.name};
  }

  Future<void> processRefund(
    Session session, {
    required int refundRequestId,
    required bool approve,
    String? adminNote,
  }) async {
    final admin = await AuthGuard.requirePermission(session, 'refunds:write');
    await _payments.processRefund(session,
      refundRequestId: refundRequestId,
      adminId: admin.id!,
      approve: approve,
      adminNote: adminNote,
    );
  }

  /// Stripe webhook handler — called by Nginx, not by the Flutter app.
  /// Signature is verified inside PaymentService.handleStripeWebhook().
  Future<void> stripeWebhook(
    Session session, {
    required String rawBody,
    required String signature,
  }) async {
    // No auth guard — webhook comes from Stripe, not a user session.
    // Security is enforced via HMAC signature verification inside the service.
    final webhookSecret = const String.fromEnvironment('STRIPE_WEBHOOK_SECRET');
    await _payments.handleStripeWebhook(session,
      rawBody: rawBody,
      signature: signature,
      webhookSecret: webhookSecret,
    );
  }

  // ── Shipping ──────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getShippingMethods(
    Session session, {
    required String country,
    required double orderTotal,
  }) async {
    await AuthGuard.requireUserId(session);
    final methods = await _shipping.getAvailableMethods(session,
      country: country, orderTotal: orderTotal);
    return methods.map((m) => {
      'id': m.id,
      'name': m.name,
      'description': m.description,
      'fee': _shipping.calculateFee(m, orderTotal),
      'estimatedDays': m.estimatedDays,
      'isFree': m.freeAbove != null && orderTotal >= m.freeAbove!,
    }).toList();
  }

  Future<Map<String, dynamic>?> getShipmentForOrder(
    Session session, {required int orderId}) async {
    final userId = await AuthGuard.requireUserId(session);
    final order = await Order.db.findById(session, orderId);
    if (order == null || order.userId != userId) throw Exception('Order not found.');
    final shipment = await _shipping.getShipmentForOrder(session, orderId);
    if (shipment == null) return null;
    return {
      'status': shipment.status.name,
      'trackingNumber': shipment.trackingNumber,
      'courierName': shipment.courierName,
      'courierUrl': shipment.courierUrl,
      'estimatedDelivery': shipment.estimatedDelivery?.toIso8601String(),
      'actualDelivery': shipment.actualDelivery?.toIso8601String(),
    };
  }
}
