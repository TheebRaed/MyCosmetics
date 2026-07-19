import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../dashboard/data/models/admin_models.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';
part 'orders_providers.g.dart';

class OrdersFilter { const OrdersFilter({this.page=0, this.status, this.search}); final int page; final String? status, search; }

@riverpod class OrdersFilterNotifier extends _$OrdersFilterNotifier {
  @override OrdersFilter build() => const OrdersFilter();
  void setStatus(String? s) => state = OrdersFilter(page: 0, status: s, search: state.search);
  void setSearch(String s)  => state = OrdersFilter(page: 0, status: state.status, search: s.isEmpty ? null : s);
  void setPage(int p)       => state = OrdersFilter(page: p, status: state.status, search: state.search);
}

@riverpod Future<PaginatedData<AdminOrderRow>> adminOrdersList(Ref ref) async {
  final f = ref.watch(ordersFilterNotifierProvider);
  final result = await ref.watch(adminRepositoryProvider).listOrders(page: f.page, status: f.status, search: f.search);
  final rows = (result['rows'] as List).map((r) => AdminOrderRow.fromJson(r as Map<String,dynamic>)).toList();
  return PaginatedData(items: rows, totalCount: result['totalCount'] as int, page: f.page, pageSize: 20);
}
