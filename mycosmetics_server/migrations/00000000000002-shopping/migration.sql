import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class CartRepository {
  Future<Cart?> findByUserId(Session session, int userId) {
    return Cart.db.findFirstRow(session, where: (t) => t.userId.equals(userId));
  }

  Future<Cart> create(Session session, int userId) {
    final now = DateTime.now().toUtc();
    return Cart.db.insertRow(session, Cart(userId: userId, createdAt: now, updatedAt: now));
  }

  /// Gets the user's cart, creating one if it doesn't exist yet. Centralizes
  /// the "lazy create" behavior so every caller gets identical semantics.
  Future<Cart> getOrCreate(Session session, int userId) async {
    final existing = await findByUserId(session, userId);
    if (existing != null) return existing;
    return create(session, userId);
  }

  Future<Cart> update(Session session, Cart cart) {
    return Cart.db.updateRow(session, cart);
  }

  Future<List<CartItem>> listItems(Session session, int cartId) {
    return CartItem.db.find(session, where: (t) => t.cartId.equals(cartId), orderBy: (t) => t.createdAt);
  }

  Future<CartItem?> findItem(Session session, int cartId, int variantId) {
    return CartItem.db.findFirstRow(
      session,
      where: (t) => t.cartId.equals(cartId) & t.variantId.equals(variantId),
    );
  }

  Future<CartItem?> findItemById(Session session, int id) {
    return CartItem.db.findById(session, id);
  }

  Future<CartItem> addItem(Session session, CartItem item) {
    return CartItem.db.insertRow(session, item);
  }

  Future<CartItem> updateItem(Session session, CartItem item) {
    return CartItem.db.updateRow(session, item);
  }

  Future<void> removeItem(Session session, int id) {
    return CartItem.db.deleteWhere(session, where: (t) => t.id.equals(id));
  }

  Future<void> clearItems(Session session, int cartId) {
    return CartItem.db.deleteWhere(session, where: (t) => t.cartId.equals(cartId));
  }
}
