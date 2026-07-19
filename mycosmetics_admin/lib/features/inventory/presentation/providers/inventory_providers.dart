import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../dashboard/data/models/admin_models.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';
part 'inventory_providers.g.dart';

@riverpod
class InventoryFilterNotifier extends _$InventoryFilterNotifier {
  @override
  ({int page, bool? lowStock, bool? outOfStock, String? search}) build() => (page: 0, lowStock: null, outOfStock: null, search: null);
  void setLowStock()  => state = (page: 0, lowStock: true,  outOfStock: null, search: state.search);
  void setOutOfStock()=> state = (page: 0, lowStock: null, outOfStock: true, search: state.search);
  void setAll()       => state = (page: 0, lowStock: null, outOfStock: null, search: state.search);
  void setSearch(String s) => state = (page: 0, lowStock: state.lowStock, outOfStock: state.outOfStock, search: s.isEmpty ? null : s);
  void setPage(int p)=> state = (page: p, lowStock: state.lowStock, outOfStock: state.outOfStock, search: state.search);
}

@riverpod
Future<PaginatedData<InventoryRow>> adminInventoryList(Ref ref) async {
  final f = ref.watch(inventoryFilterNotifierProvider);
  final result = await ref.watch(adminRepositoryProvider).listInventory(page: f.page, lowStock: f.lowStock, outOfStock: f.outOfStock, search: f.search);
  final rows = (result['rows'] as List).map((r) => InventoryRow.fromJson(r as Map<String,dynamic>)).toList();
  return PaginatedData(items: rows, totalCount: result['totalCount'] as int, page: f.page, pageSize: 50);
}
