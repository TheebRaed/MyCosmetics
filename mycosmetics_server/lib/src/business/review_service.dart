import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/cart_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class CartEndpoint extends Endpoint {
  final CartService _cart = CartService();

  Future<CartSummary> getCart(Session session, {required String token}) async {
    final user = await AuthGuard.requireUser(session, token);
    return _cart.getCart(session, user.id!);
  }

  Future<CartSummary> addItem(Session session, {required String token, required int variantId, required int quantity}) async {
    final user = await AuthGuard.requireUser(session, token);
    return _cart.addItem(session, userId: user.id!, variantId: variantId, quantity: quantity);
  }

  Future<CartSummary> updateQuantity(Session session, {required String token, required int cartItemId, required int quantity}) async {
    final user = await AuthGuard.requireUser(session, token);
    return _cart.updateQuantity(session, userId: user.id!, cartItemId: cartItemId, quantity: quantity);
  }

  Future<CartSummary> removeItem(Session session, {required String token, required int cartItemId}) async {
    final user = await AuthGuard.requireUser(session, token);
    return _cart.removeItem(session, userId: user.id!, cartItemId: cartItemId);
  }

  Future<CartSummary> clearCart(Session session, {required String token}) async {
    final user = await AuthGuard.requireUser(session, token);
    return _cart.clearCart(session, user.id!);
  }
}
