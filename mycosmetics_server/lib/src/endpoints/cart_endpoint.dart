import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/wishlist_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class WishlistEndpoint extends Endpoint {
  final WishlistService _wishlist = WishlistService();

  Future<List<WishlistItemDetail>> list(Session session, {required String token}) async {
    final user = await AuthGuard.requireUser(session, token);
    return _wishlist.list(session, user.id!);
  }

  Future<WishlistItem> add(Session session, {required String token, required int productId}) async {
    final user = await AuthGuard.requireUser(session, token);
    return _wishlist.add(session, userId: user.id!, productId: productId);
  }

  Future<void> remove(Session session, {required String token, required int wishlistItemId}) async {
    final user = await AuthGuard.requireUser(session, token);
    await _wishlist.remove(session, userId: user.id!, wishlistItemId: wishlistItemId);
  }

  Future<CartSummary> moveToCart(
    Session session, {
    required String token,
    required int wishlistItemId,
    required int variantId,
    int quantity = 1,
  }) async {
    final user = await AuthGuard.requireUser(session, token);
    return _wishlist.moveToCart(
      session,
      userId: user.id!,
      wishlistItemId: wishlistItemId,
      variantId: variantId,
      quantity: quantity,
    );
  }
}
