import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../dashboard/data/models/admin_models.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';
part 'products_providers.g.dart';

class ProductsFilter { const ProductsFilter({this.page=0, this.search, this.isActive}); final int page; final String? search; final bool? isActive; }

@riverpod class ProductsFilterNotifier extends _$ProductsFilterNotifier {
  @override ProductsFilter build() => const ProductsFilter();
  void setSearch(String s) => state = ProductsFilter(page: 0, search: s.isEmpty ? null : s, isActive: state.isActive);
  void setPage(int p)      => state = ProductsFilter(page: p, search: state.search, isActive: state.isActive);
}

@riverpod Future<PaginatedData<AdminProductRow>> adminProductsList(Ref ref) async {
  final f = ref.watch(productsFilterNotifierProvider);
  final result = await ref.watch(adminRepositoryProvider).listProducts(page: f.page, search: f.search, isActive: f.isActive);
  final rows = (result['rows'] as List).map((r) {
    final m = r as Map<String,dynamic>;
    return AdminProductRow.fromJson({...m, 'totalStock': m['total_stock'] ?? m['totalStock'] ?? 0});
  }).toList();
  return PaginatedData(items: rows, totalCount: result['totalCount'] as int, page: f.page, pageSize: 20);
}
