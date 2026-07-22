import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';

part 'cart_repository.g.dart';

/// Thin wrapper around `client.cart`/`client.coupon`/`client.wishlist` for
/// the Cart screen -- see mycosmetics_server/lib/src/endpoints/cart_endpoint.dart
/// and coupon_endpoint.dart.
///
/// "Save for later" reuses the existing wishlist mechanism (already wired
/// on PDP, see product_details_repository.dart) rather than inventing a new
/// backend concept -- there's no distinct "saved for later" flag on
/// CartItem/Cart. [moveToWishlist] adds the product to the wishlist then
/// removes the line from the cart, which is a real, persisted action.
///
/// Delivery fees are NOT computed here -- no fee is known until an address
/// is picked at checkout (see checkout_repository.dart's
/// `getShippingMethods`), so the Cart screen shows "Calculated at checkout"
/// rather than inventing a number.
class CartRepository {
  CartRepository(this._client);

  final Client _client;

  Future<CartSummary> getCart() => _client.cart.getCart();

  Future<CartSummary> updateQuantity({required int cartItemId, required int quantity}) =>
      _client.cart.updateQuantity(cartItemId: cartItemId, quantity: quantity);

  Future<CartSummary> removeItem({required int cartItemId}) => _client.cart.removeItem(cartItemId: cartItemId);

  Future<CouponValidationResult> applyCoupon(String code) => _client.coupon.apply(code: code);

  Future<void> removeCoupon() => _client.coupon.remove();

  Future<void> moveToWishlist({required int cartItemId, required int productId}) async {
    await _client.wishlist.add(productId: productId);
    await _client.cart.removeItem(cartItemId: cartItemId);
  }
}

@riverpod
CartRepository cartRepository(Ref ref) => CartRepository(ref.watch(apiClientProvider));
