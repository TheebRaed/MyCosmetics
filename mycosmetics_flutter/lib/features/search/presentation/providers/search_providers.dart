import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/search_repository.dart';

part 'search_providers.g.dart';

/// Holds the current search/filter/sort state. The screen debounces text
/// input itself (Timer in the widget) before calling [setQuery] so we don't
/// fire a request per keystroke.
@riverpod
class SearchController extends _$SearchController {
  @override
  SearchParams build() => const SearchParams();

  void setQuery(String query) => state = state.copyWith(query: query, clearQuery: query.trim().isEmpty, page: 0);

  void setCategory(int? categoryId) =>
      state = state.copyWith(categoryId: categoryId, clearCategory: categoryId == null, page: 0);

  void setBrand(int? brandId) => state = state.copyWith(brandId: brandId, clearBrand: brandId == null, page: 0);

  void setPriceRange(double? min, double? max) =>
      state = state.copyWith(minPrice: min, maxPrice: max, clearPrice: min == null && max == null, page: 0);

  void setSortBy(ProductSortBy sortBy) => state = state.copyWith(sortBy: sortBy, page: 0);

  void clearFilters() => state = SearchParams(query: state.query, sortBy: state.sortBy);

  void reset() => state = const SearchParams();
}

/// Live results for the current [SearchController] state -- doubles as
/// "search-as-you-type suggestions" per the task brief (no separate
/// suggestions endpoint exists on the backend).
@riverpod
Future<ProductListResult> searchResults(Ref ref) {
  final params = ref.watch(searchControllerProvider);
  return ref.watch(searchRepositoryProvider).search(params);
}

@riverpod
Future<List<Category>> searchCategories(Ref ref) => ref.watch(searchRepositoryProvider).topLevelCategories();

@riverpod
Future<List<Brand>> searchBrands(Ref ref) => ref.watch(searchRepositoryProvider).allBrands();

@riverpod
Future<List<String>> searchHistory(Ref ref) async {
  final store = await ref.watch(searchHistoryStoreProvider.future);
  return store.getTerms();
}
