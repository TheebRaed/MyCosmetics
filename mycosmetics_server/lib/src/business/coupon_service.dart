import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/repositories/wishlist_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_image_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_variant_repository.dart';
import 'package:mycosmetics_server/src/business/cart_service.dart';
import 'package:mycosmetics_server/src/utils/shopping_validator.dart';

class WishlistService {
  final WishlistRepository _wishlist = WishlistRepository();
  final ProductRepository _products = ProductRepository();
  final ProductImageRepository _images = ProductImageRepository();
  final ProductVariantRepository _variants = ProductVariantRepository();
  final CartService _cartService = CartService();

  Future<List<WishlistItemDetail>> list(Session session, int userId) async {
    final items = await _wishlist.listForUser(session, userId);
    return Future.wait(items.map((item) async {
      final product = await _products.findById(session, item.productId, includeInactive: true);
      final images = await _images.listForProduct(session, item.productId);
      final variants = await _variants.listForProduct(session, item.productId);
      final inStock = variants.any((v) => v.stockQty > 0);
      return WishlistItemDetail(
        wishlistItem: item,
        productName: product?.name ?? 'Unknown product',
        basePrice: product?.basePrice ?? 0,
        imageUrl: images.isNotEmpty ? images.first.url : null,
        isInStock: inStock,
      );
    }));
  }

  Future<WishlistItem> add(Session session, {required int userId, required int productId}) async {
    final product = await _products.findById(session, productId);
    if (product == null) throw ShoppingValidationException('Product not found.');

    final existing = await _wishlist.find(session, userId, productId);
    if (existing != null) return existing;

    return _wishlist.add(
      session,
      WishlistItem(userId: userId, productId: productId, createdAt: DateTime.now().toUtc()),
    );
  }

  Future<void> remove(Session session, {required int userId, required int wishlistItemId}) async {
    final existing = await _wishlist.findById(session, wishlistItemId);
    if (existing == null || existing.userId != userId) {
      throw ShoppingValidationException('Wishlist item not found.');
    }
    await _wishlist.remove(session, id: wishlistItemId, userId: userId);
  }

  /// Moves a wishlisted product into the cart: adds the chosen variant to
  /// the cart (going through CartService so stock/availability validation
  /// still applies), then removes the wishlist entry only if the add
  /// succeeded \u2014 a failed stock check leaves the wishlist item intact
  /// rather than silently losing it.
  Future<CartSummary> moveToCart(
    Session session, {
    required int userId,
    required int wishlistItemId,
    required int variantId,
    int quantity = 1,
  }) async {
    final existing = await _wishlist.findById(session, wishlistItemId);
    if (existing == null || existing.userId != userId) {
      throw ShoppingValidationException('Wishlist item not found.');
    }

    final variant = await _variants.findById(session, variantId);
    if (variant == null || variant.productId != existing.productId) {
      throw ShoppingValidationException('Selected variant does not belong to this product.');
    }

    final cartSummary = await _cartService.addItem(session, userId: userId, variantId: variantId, quantity: quantity);
    await _wishlist.remove(session, id: wishlistItemId, userId: userId);
    return cartSummary;
  }
}
