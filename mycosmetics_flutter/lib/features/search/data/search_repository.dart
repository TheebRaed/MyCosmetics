import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../home/data/home_repository.dart' show sharedPreferencesProvider;

part 'search_repository.g.dart';

const _searchPageSize = 20;

/// Params bundle for the single real `ProductEndpoint.search` call --
/// text query, category/brand/price filters, and sort are all just
/// different combinations of the same query per the endpoint's own doc
/// comment. Shade filtering is deliberately NOT included: shades live on
/// `ProductVariant`, not `Product`, and `ProductFilter`
/// (mycosmetics_server/lib/src/repositories/product_repository.dart) has no
/// variant-level filter field, so a real shade filter would need a new
/// backend param -- not attempted here.
class SearchParams {
  const SearchParams({
    this.query,
    this.categoryId,
    this.brandId,
    this.minPrice,
    this.maxPrice,
    this.sortBy = ProductSortBy.newest,
    this.page = 0,
  });

  final String? query;
  final int? categoryId;
  final int? brandId;
  final double? minPrice;
  final double? maxPrice;
  final ProductSortBy sortBy;
  final int page;

  SearchParams copyWith({
    String? query,
    bool clearQuery = false,
    int? categoryId,
    bool clearCategory = false,
    int? brandId,
    bool clearBrand = false,
    double? minPrice,
    double? maxPrice,
    bool clearPrice = false,
    ProductSortBy? sortBy,
    int? page,
  }) {
    return SearchParams(
      query: clearQuery ? null : (query ?? this.query),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      brandId: clearBrand ? null : (brandId ?? this.brandId),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      sortBy: sortBy ?? this.sortBy,
      page: page ?? this.page,
    );
  }

  bool get hasActiveFilters =>
      categoryId != null || brandId != null || minPrice != null || maxPrice != null;
}

/// Thin wrapper around `client.product.search` / `client.category` /
/// `client.brand` for the Search screen. See product_endpoint.dart,
/// category_endpoint.dart, brand_endpoint.dart.
class SearchRepository {
  SearchRepository(this._client);

  final Client _client;

  Future<ProductListResult> search(SearchParams params) => _client.product.search(
        searchQuery: (params.query?.trim().isEmpty ?? true) ? null : params.query!.trim(),
        categoryId: params.categoryId,
        brandId: params.brandId,
        minPrice: params.minPrice,
        maxPrice: params.maxPrice,
        sortBy: params.sortBy,
        page: params.page,
        pageSize: _searchPageSize,
      );

  Future<List<Category>> topLevelCategories() => _client.category.listTopLevel();

  Future<List<Brand>> allBrands() => _client.brand.listAll();
}

@riverpod
SearchRepository searchRepository(Ref ref) => SearchRepository(ref.watch(apiClientProvider));

/// Local-only recent search terms (SharedPreferences, most-recent-first,
/// capped list, de-duplicated). There's no server-side "search history" or
/// "trending searches" endpoint -- this is device-local only, same pattern
/// as Home's `RecentlyViewedStore`.
class SearchHistoryStore {
  SearchHistoryStore(this._prefs);

  static const _key = 'recent_search_terms';
  static const _maxEntries = 10;

  final SharedPreferences _prefs;

  List<String> getTerms() => _prefs.getStringList(_key) ?? const [];

  Future<void> record(String term) async {
    final trimmed = term.trim();
    if (trimmed.isEmpty) return;
    final terms = getTerms().where((t) => t.toLowerCase() != trimmed.toLowerCase()).toList()
      ..insert(0, trimmed);
    if (terms.length > _maxEntries) terms.removeRange(_maxEntries, terms.length);
    await _prefs.setStringList(_key, terms);
  }

  Future<void> clear() => _prefs.remove(_key);
}

@riverpod
Future<SearchHistoryStore> searchHistoryStore(Ref ref) async =>
    SearchHistoryStore(await ref.watch(sharedPreferencesProvider.future));
