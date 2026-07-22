import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';

part 'product_details_repository.g.dart';

const _similarPageSize = 10;
const _reviewsPageSize = 20;

/// Thin wrapper around the generated client for the Product Details screen.
///
/// Deliberately NOT wrapped here (see docs and task brief for why):
/// - Any AI match %, recommendation, or virtual try-on call -- no
///   recommendation-engine endpoint exists on the backend yet (confirmed
///   gap from the Home screen build).
/// - "Complete The Look" -- same gap, no endpoint.
/// - Delivery-estimate lookup -- no shipping/delivery-estimate data source
///   exists on the backend.
/// - Coupon validation on the PDP -- checkout doesn't exist yet, coupon
///   application is a checkout-flow concern.
class ProductDetailsRepository {
  ProductDetailsRepository(this._client);

  final Client _client;

  Future<ProductDetail> details(int id) => _client.product.getDetails(id: id);

  /// "Similar products" stands in for the spec's "Similar Products" section
  /// using a real query -- same category, excluding the current product.
  /// Not personalized/AI-driven (that endpoint doesn't exist), just a plain
  /// category search.
  Future<List<ProductDetail>> similarInCategory({required int categoryId, required int excludeProductId}) async {
    final result = await _client.product.search(
      categoryId: categoryId,
      sortBy: ProductSortBy.bestSelling,
      page: 0,
      pageSize: _similarPageSize,
    );
    return result.items.where((p) => p.product.id != excludeProductId).toList();
  }

  Future<List<Review>> reviews(int productId, {int page = 0}) =>
      _client.review.listForProduct(productId: productId, page: page, pageSize: _reviewsPageSize);

  Future<List<WishlistItemDetail>> wishlist() => _client.wishlist.list();

  Future<WishlistItem> addToWishlist(int productId) => _client.wishlist.add(productId: productId);

  Future<void> removeFromWishlist(int wishlistItemId) => _client.wishlist.remove(wishlistItemId: wishlistItemId);

  Future<CartSummary> addToCart({required int variantId, required int quantity}) =>
      _client.cart.addItem(variantId: variantId, quantity: quantity);
}

@riverpod
ProductDetailsRepository productDetailsRepository(Ref ref) =>
    ProductDetailsRepository(ref.watch(apiClientProvider));
