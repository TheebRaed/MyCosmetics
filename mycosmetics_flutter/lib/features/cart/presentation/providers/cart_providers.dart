import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/cart_repository.dart';

part 'cart_providers.g.dart';

/// Whole-cart state, shared by the Cart screen and Checkout (Checkout reads
/// this rather than re-fetching, so a coupon applied in Cart carries
/// straight into the checkout summary -- see CLAUDE.md task brief).
@riverpod
class CartController extends _$CartController {
  @override
  Future<CartSummary> build() => ref.watch(cartRepositoryProvider).getCart();

  Future<String?> updateQuantity({required int cartItemId, required int quantity}) async {
    try {
      final summary = await ref.read(cartRepositoryProvider).updateQuantity(cartItemId: cartItemId, quantity: quantity);
      state = AsyncData(summary);
      return null;
    } catch (e) {
      return friendlyCartErrorMessage(e);
    }
  }

  Future<String?> removeItem({required int cartItemId}) async {
    try {
      final summary = await ref.read(cartRepositoryProvider).removeItem(cartItemId: cartItemId);
      state = AsyncData(summary);
      return null;
    } catch (e) {
      return friendlyCartErrorMessage(e);
    }
  }

  Future<String?> moveToWishlist({required int cartItemId, required int productId}) async {
    try {
      await ref.read(cartRepositoryProvider).moveToWishlist(cartItemId: cartItemId, productId: productId);
      final summary = await ref.read(cartRepositoryProvider).getCart();
      state = AsyncData(summary);
      return null;
    } catch (e) {
      return friendlyCartErrorMessage(e);
    }
  }

  Future<String?> applyCoupon(String code) async {
    try {
      final result = await ref.read(cartRepositoryProvider).applyCoupon(code);
      if (!result.isValid) return result.message;
      final summary = await ref.read(cartRepositoryProvider).getCart();
      state = AsyncData(summary);
      return null;
    } catch (e) {
      return friendlyCartErrorMessage(e);
    }
  }

  Future<String?> removeCoupon() async {
    try {
      await ref.read(cartRepositoryProvider).removeCoupon();
      final summary = await ref.read(cartRepositoryProvider).getCart();
      state = AsyncData(summary);
      return null;
    } catch (e) {
      return friendlyCartErrorMessage(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = AsyncData(await ref.read(cartRepositoryProvider).getCart());
  }
}

/// Strips Serverpod's exception-class prefix, same approach as
/// auth_controller.dart's `friendlyAuthErrorMessage`. `ShoppingValidationException`
/// messages (stock limits, invalid quantity, etc.) come through as the raw
/// message text, everything else falls back to a generic message.
String friendlyCartErrorMessage(Object e) {
  final raw = e.toString();
  if (raw.contains('Internal server error')) {
    return 'Something went wrong. Please try again.';
  }
  final match = RegExp(r'^ServerpodClientException:\s*(.*?),\s*statusCode').firstMatch(raw);
  return match?.group(1) ?? 'Something went wrong. Please try again.';
}
