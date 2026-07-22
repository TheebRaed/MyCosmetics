import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';

part 'home_repository.g.dart';

/// How many items each Home section pulls. Home is a preview, not a full
/// listing -- the "see all" -> full paged Search/Category screen is
/// separate future work.
const _homeSectionPageSize = 10;

/// Thin wrapper around `client.product` / `client.category` (see
/// mycosmetics_server/lib/src/endpoints/product_endpoint.dart and
/// category_endpoint.dart) for the sections Home actually renders.
///
/// Deliberately NOT wrapped here: "Trending" (no order/view-count signal
/// exists on the backend yet), "AI Recommendations" (no BeautyTech
/// recommendation endpoint exists yet -- only protocol DTOs), "Special
/// Offers" as a dedicated query (`ProductFilter` has no discount filter,
/// so a real "on sale" listing would require scanning all pages
/// client-side -- not attempted), "Featured Collections" (no Collection
/// model exists; Featured products stands in for it on Home).
class HomeRepository {
  HomeRepository(this._client);

  final Client _client;

  Future<ProductListResult> newArrivals() => _client.product.search(
        isNewArrival: true,
        sortBy: ProductSortBy.newest,
        page: 0,
        pageSize: _homeSectionPageSize,
      );

  Future<ProductListResult> bestSellers() => _client.product.search(
        isBestSeller: true,
        sortBy: ProductSortBy.bestSelling,
        page: 0,
        pageSize: _homeSectionPageSize,
      );

  /// Stands in for both "Featured Collections" and "Recommended Products"
  /// on Home -- neither a Collection model nor a personalized recommender
  /// exists on the backend yet, and `isFeatured` is the one real curation
  /// signal available today.
  Future<ProductListResult> featured() => _client.product.search(
        isFeatured: true,
        sortBy: ProductSortBy.newest,
        page: 0,
        pageSize: _homeSectionPageSize,
      );

  Future<List<Category>> topLevelCategories() => _client.category.listTopLevel();

  Future<ProductDetail> productDetails(int id) => _client.product.getDetails(id: id);
}

@riverpod
HomeRepository homeRepository(Ref ref) => HomeRepository(ref.watch(apiClientProvider));

/// Local-only recently-viewed tracking (SharedPreferences, most-recent-first,
/// capped list of product ids). There's no server-side view-history
/// endpoint yet, so this is device-local and won't sync across devices --
/// flagged as a real gap for a future backend endpoint, not silently
/// worked around. Nothing currently calls [recordView] since the product
/// detail screen (the natural call site) is out of scope for this slice;
/// the section renders its honest empty state until PDP lands.
class RecentlyViewedStore {
  RecentlyViewedStore(this._prefs);

  static const _key = 'recently_viewed_product_ids';
  static const _maxEntries = 20;

  final SharedPreferences _prefs;

  List<int> getIds() => (_prefs.getStringList(_key) ?? const []).map(int.parse).toList();

  Future<void> recordView(int productId) async {
    final ids = getIds()..remove(productId);
    ids.insert(0, productId);
    if (ids.length > _maxEntries) ids.removeRange(_maxEntries, ids.length);
    await _prefs.setStringList(_key, ids.map((id) => id.toString()).toList());
  }
}

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) => SharedPreferences.getInstance();

@riverpod
Future<RecentlyViewedStore> recentlyViewedStore(Ref ref) async =>
    RecentlyViewedStore(await ref.watch(sharedPreferencesProvider.future));
