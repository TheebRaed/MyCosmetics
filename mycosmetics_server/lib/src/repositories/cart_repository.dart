import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class WishlistRepository {
  Future<List<WishlistItem>> listForUser(Session session, int userId) {
    return WishlistItem.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
  }

  Future<WishlistItem?> find(Session session, int userId, int productId) {
    return WishlistItem.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.productId.equals(productId),
    );
  }

  Future<WishlistItem?> findById(Session session, int id) {
    return WishlistItem.db.findById(session, id);
  }

  Future<WishlistItem> add(Session session, WishlistItem item) {
    return WishlistItem.db.insertRow(session, item);
  }

  Future<void> remove(Session session, {required int id, required int userId}) {
    return WishlistItem.db.deleteWhere(session, where: (t) => t.id.equals(id) & t.userId.equals(userId));
  }
}
