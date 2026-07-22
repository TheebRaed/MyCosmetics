import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/orders_repository.dart';

part 'orders_providers.g.dart';

/// Order statuses that still allow customer-initiated cancellation --
/// mirrors `order_service.dart`'s `_allowedTransitions` (pending/processing
/// can move to cancelled, shipped/delivered/cancelled/returned cannot).
const cancellableStatuses = {OrderStatus.pending, OrderStatus.processing};

@riverpod
class OrderList extends _$OrderList {
  @override
  Future<List<Order>> build() => ref.watch(ordersRepositoryProvider).listMyOrders();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(ordersRepositoryProvider).listMyOrders());
  }
}

@riverpod
class OrderDetailController extends _$OrderDetailController {
  @override
  Future<OrderDetail> build(int orderId) => ref.watch(ordersRepositoryProvider).getDetails(orderId);

  Future<String?> cancel({String? reason}) async {
    try {
      final updated = await ref.read(ordersRepositoryProvider).cancel(orderId: orderId, reason: reason);
      state = AsyncData(updated);
      ref.invalidate(orderListProvider);
      return null;
    } catch (e) {
      return friendlyOrderErrorMessage(e);
    }
  }

  Future<String?> submitReview({required int orderItemId, required int rating, String? comment}) async {
    try {
      await ref.read(ordersRepositoryProvider).addReview(orderItemId: orderItemId, rating: rating, comment: comment);
      return null;
    } catch (e) {
      return friendlyOrderErrorMessage(e);
    }
  }
}

/// Strips Serverpod's exception-class prefix, same pattern as
/// cart_providers.dart's `friendlyCartErrorMessage`.
String friendlyOrderErrorMessage(Object e) {
  final raw = e.toString();
  if (raw.contains('Internal server error')) {
    return 'Something went wrong. Please try again.';
  }
  final match = RegExp(r'^ServerpodClientException:\s*(.*?),\s*statusCode').firstMatch(raw);
  return match?.group(1) ?? 'Something went wrong. Please try again.';
}
