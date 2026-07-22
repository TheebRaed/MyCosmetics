import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';

part 'orders_repository.g.dart';

const _pageSize = 20;

/// Thin wrapper around `client.order` (see
/// mycosmetics_server/lib/src/endpoints/order_endpoint.dart) for the Orders
/// list/detail screens, plus `client.review.add` for the "write a review"
/// action surfaced from a delivered order's line items.
///
/// `OrderEndpoint.cancel` is only offered in the UI while the order's
/// current status allows it (pending/processing -- see the state machine in
/// order_service.dart's `_allowedTransitions`); the server re-validates the
/// same transition regardless, this is purely to avoid showing a button
/// that would just error.
class OrdersRepository {
  OrdersRepository(this._client);

  final Client _client;

  Future<List<Order>> listMyOrders({int page = 0}) =>
      _client.order.listMyOrders(page: page, pageSize: _pageSize);

  Future<OrderDetail> getDetails(int orderId) => _client.order.getDetails(orderId: orderId);

  Future<OrderDetail> cancel({required int orderId, String? reason}) =>
      _client.order.cancel(orderId: orderId, reason: reason);

  /// Eligibility (must be a Delivered order's item, not already reviewed)
  /// is enforced server-side in `ReviewService.add` -- this call surfaces
  /// whatever message that throws (e.g. "You have already reviewed this
  /// purchase.") rather than re-deriving eligibility client-side.
  Future<Review> addReview({required int orderItemId, required int rating, String? comment}) =>
      _client.review.add(orderItemId: orderItemId, rating: rating, comment: comment);
}

@riverpod
OrdersRepository ordersRepository(Ref ref) => OrdersRepository(ref.watch(apiClientProvider));
