import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/repositories/order_repository.dart';
import 'package:mycosmetics_server/src/repositories/cart_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_variant_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_repository.dart';
import 'package:mycosmetics_server/src/repositories/coupon_repository.dart';
import 'package:mycosmetics_server/src/repositories/address_repository.dart';
import 'package:mycosmetics_server/src/business/coupon_service.dart';
import 'package:mycosmetics_server/src/utils/shopping_validator.dart';

class OrderException implements Exception {
  final String message;
  OrderException(this.message);
  @override
  String toString() => message;
}

/// Status transitions allowed by the state machine. Anything not listed
/// here (e.g. Delivered -> Processing, or any transition out of Cancelled)
/// is rejected \u2014 order status must move forward only, and Cancelled is
/// terminal.
const Map<OrderStatus, Set<OrderStatus>> _allowedTransitions = {
  OrderStatus.pending: {OrderStatus.processing, OrderStatus.cancelled},
  OrderStatus.processing: {OrderStatus.packed, OrderStatus.cancelled},
  OrderStatus.packed: {OrderStatus.shipped, OrderStatus.cancelled},
  OrderStatus.shipped: {OrderStatus.delivered},
  OrderStatus.delivered: {},
  OrderStatus.cancelled: {},
};

class OrderService {
  final OrderRepository _orders = OrderRepository();
  final CartRepository _carts = CartRepository();
  final ProductVariantRepository _variants = ProductVariantRepository();
  final ProductRepository _products = ProductRepository();
  final CouponRepository _coupons = CouponRepository();
  final AddressRepository _addresses = AddressRepository();
  final CouponService _couponService = CouponService();

  Future<OrderDetail> _composeDetail(Session session, Order order) async {
    final items = await _orders.listItems(session, order.id!);
    final history = await _orders.listStatusHistory(session, order.id!);
    final address = await _addresses.findById(session, order.addressId);
    if (address == null) {
      // Address was hard-deleted; this should be prevented by the
      // ON DELETE RESTRICT FK, but guard rather than crash order history views.
      throw OrderException('Shipping address for this order is no longer available.');
    }
    return OrderDetail(order: order, items: items, statusHistory: history, shippingAddress: address);
  }

  Future<OrderDetail> getDetails(Session session, {required int userId, required int orderId}) async {
    final order = await _orders.findById(session, orderId);
    if (order == null || order.userId != userId) {
      throw OrderException('Order not found.');
    }
    return _composeDetail(session, order);
  }

  Future<List<Order>> listForUser(Session session, {required int userId, int page = 0, int pageSize = 20}) {
    ShoppingValidator.validatePagination(page, pageSize);
    return _orders.listForUser(session, userId, page: page, pageSize: pageSize);
  }

  /// The full checkout transaction. Runs inside a single DB transaction so
  /// stock decrements, order/order-item creation, coupon consumption, and
  /// cart clearing either all happen or none do \u2014 a failure partway
  /// through (e.g. a variant goes out of stock between cart-read and
  /// checkout) cannot leave a half-created order or double-decremented stock.
  Future<OrderDetail> checkout(Session session, {required int userId, required int addressId}) async {
    final address = await _addresses.findById(session, addressId);
    if (address == null || address.userId != userId) {
      throw OrderException('Shipping address not found.');
    }

    final cart = await _carts.getOrCreate(session, userId);
    final cartItems = await _carts.listItems(session, cart.id!);
    if (cartItems.isEmpty) {
      throw OrderException('Cannot checkout an empty cart.');
    }

    final order = await session.db.transaction((transaction) async {
      double subtotal = 0;
      final lineSnapshots = <_OrderLineSnapshot>[];

      // Re-validate stock and price for every line INSIDE the transaction,
      // against the live variant row, immediately before decrementing \u2014
      // this is the actual stock-validation enforcement point for
      // checkout (the cart-level check at add-time is only a UX nicety;
      // this is what prevents overselling).
      for (final item in cartItems) {
        final variant = await _variants.findById(session, item.variantId);
        if (variant == null || !variant.isActive) {
          throw OrderException('An item in your cart is no longer available. Please review your cart.');
        }
        if (item.quantity > variant.stockQty) {
          throw OrderException(
            'Only ${variant.stockQty} unit(s) of "${variant.shadeName ?? variant.sku}" are left in stock.',
          );
        }
        final product = await _products.findById(session, variant.productId);
        if (product == null) {
          throw OrderException('An item in your cart is no longer available. Please review your cart.');
        }

        final lineTotal = variant.price * item.quantity;
        subtotal += lineTotal;
        lineSnapshots.add(_OrderLineSnapshot(
          variantId: variant.id!,
          productName: product.name,
          shadeName: variant.shadeName,
          unitPrice: variant.price,
          quantity: item.quantity,
          lineTotal: lineTotal,
        ));

        // Decrement stock atomically via a conditional UPDATE (not
        // read-modify-write in Dart) so concurrent checkouts against the
        // same variant can't both pass the check above and oversell it.
        final decremented = await _decrementStock(session, variant.id!, item.quantity);
        if (!decremented) {
          throw OrderException(
            'Stock for "${variant.shadeName ?? variant.sku}" changed while checking out. Please review your cart.',
          );
        }
      }

      double discountAmount = 0;
      int? couponId;
      if (cart.appliedCouponId != null) {
        final coupon = await _coupons.findById(session, cart.appliedCouponId!);
        if (coupon != null) {
          final validation = await _couponService.validate(session, code: coupon.code, subtotal: subtotal);
          if (validation.isValid) {
            final consumed = await _coupons.tryIncrementUsage(session, coupon.id!);
            if (consumed) {
              discountAmount = validation.discountAmount;
              couponId = coupon.id;
            }
            // If the coupon couldn't be consumed (limit hit by a
            // concurrent checkout between validate() and here), proceed
            // without the discount rather than failing the whole order \u2014
            // losing a discount is recoverable, losing a sale is not.
          }
        }
      }

      final total = (subtotal - discountAmount).clamp(0, double.infinity);
      final now = DateTime.now().toUtc();

      final createdOrder = await _orders.create(
        session,
        Order(
          userId: userId,
          addressId: addressId,
          couponId: couponId,
          status: OrderStatus.pending,
          subtotal: subtotal,
          discountAmount: discountAmount,
          total: total,
          createdAt: now,
          updatedAt: now,
        ),
      );

      for (final line in lineSnapshots) {
        await _orders.createItem(
          session,
          OrderItem(
            orderId: createdOrder.id!,
            variantId: line.variantId,
            productNameSnapshot: line.productName,
            shadeNameSnapshot: line.shadeName,
            unitPrice: line.unitPrice,
            quantity: line.quantity,
            lineTotal: line.lineTotal,
          ),
        );
      }

      await _orders.addStatusHistory(
        session,
        OrderStatusHistory(orderId: createdOrder.id!, status: OrderStatus.pending, note: 'Order placed.', createdAt: now),
      );

      await _carts.clearItems(session, cart.id!);
      if (cart.appliedCouponId != null) {
        await _carts.update(session, cart.copyWith(appliedCouponId: null, updatedAt: now));
      }

      return createdOrder;
    });

    return _composeDetail(session, order);
  }

  /// Atomic, race-safe stock decrement: only succeeds if enough stock is
  /// still available at the moment of the UPDATE, regardless of what was
  /// read earlier in this same request.
  Future<bool> _decrementStock(Session session, int variantId, int quantity) async {
    final result = await session.db.unsafeQuery(
      'UPDATE "product_variants" SET "stockQty" = "stockQty" - @qty, "updatedAt" = @now '
      'WHERE "id" = @id AND "stockQty" >= @qty '
      'RETURNING "id"',
      parameters: QueryParameters.named({'id': variantId, 'qty': quantity, 'now': DateTime.now().toUtc()}),
    );
    return result.isNotEmpty;
  }

  Future<bool> _restoreStock(Session session, int variantId, int quantity) async {
    final result = await session.db.unsafeQuery(
      'UPDATE "product_variants" SET "stockQty" = "stockQty" + @qty, "updatedAt" = @now WHERE "id" = @id RETURNING "id"',
      parameters: QueryParameters.named({'id': variantId, 'qty': quantity, 'now': DateTime.now().toUtc()}),
    );
    return result.isNotEmpty;
  }

  /// Customer-initiated cancellation: only allowed while the order hasn't
  /// shipped yet (matches the state machine: pending/processing/packed can
  /// cancel, shipped/delivered/cancelled cannot).
  Future<OrderDetail> cancel(Session session, {required int userId, required int orderId, String? reason}) async {
    final order = await _orders.findById(session, orderId);
    if (order == null || order.userId != userId) {
      throw OrderException('Order not found.');
    }
    await _transitionStatus(session, order, OrderStatus.cancelled, note: reason ?? 'Cancelled by customer.');
    return getDetails(session, userId: userId, orderId: orderId);
  }

  /// Admin-side status update, used by the admin Orders Management module.
  Future<OrderDetail> updateStatus(Session session, {required int orderId, required OrderStatus newStatus, String? note}) async {
    final order = await _orders.findById(session, orderId);
    if (order == null) throw OrderException('Order not found.');
    await _transitionStatus(session, order, newStatus, note: note);
    final refreshed = await _orders.findById(session, orderId);
    return _composeDetail(session, refreshed!);
  }

  Future<void> _transitionStatus(Session session, Order order, OrderStatus newStatus, {String? note}) async {
    final allowed = _allowedTransitions[order.status] ?? {};
    if (!allowed.contains(newStatus)) {
      throw OrderException('Cannot move order from ${order.status.name} to ${newStatus.name}.');
    }

    await session.db.transaction((transaction) async {
      if (newStatus == OrderStatus.cancelled) {
        // Restore stock for every line item when an order is cancelled \u2014
        // mirrors the decrement done at checkout so inventory stays correct.
        final items = await _orders.listItems(session, order.id!);
        for (final item in items) {
          await _restoreStock(session, item.variantId, item.quantity);
        }
        if (order.couponId != null) {
          await _coupons.decrementUsage(session, order.couponId!);
        }
      }

      await _orders.update(session, order.copyWith(status: newStatus, updatedAt: DateTime.now().toUtc()));
      await _orders.addStatusHistory(
        session,
        OrderStatusHistory(orderId: order.id!, status: newStatus, note: note, createdAt: DateTime.now().toUtc()),
      );
    });
  }
}

class _OrderLineSnapshot {
  final int variantId;
  final String productName;
  final String? shadeName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  _OrderLineSnapshot({
    required this.variantId,
    required this.productName,
    required this.shadeName,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });
}
