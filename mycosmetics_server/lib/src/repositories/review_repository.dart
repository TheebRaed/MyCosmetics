import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class ReviewRepository {
  Future<List<Review>> listForProduct(Session session, int productId, {int page = 0, int pageSize = 20}) {
    return Review.db.find(
      session,
      where: (t) => t.productId.equals(productId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: pageSize,
      offset: page * pageSize,
    );
  }

  Future<Review?> findById(Session session, int id) {
    return Review.db.findById(session, id);
  }

  Future<Review?> findByUserAndOrderItem(Session session, int userId, int orderItemId) {
    return Review.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.orderItemId.equals(orderItemId),
    );
  }

  Future<Review> create(Session session, Review review) {
    return Review.db.insertRow(session, review);
  }

  Future<Review> update(Session session, Review review) {
    return Review.db.updateRow(session, review);
  }

  Future<void> delete(Session session, {required int id, required int userId}) {
    return Review.db.deleteWhere(session, where: (t) => t.id.equals(id) & t.userId.equals(userId));
  }

  /// Single aggregate query (COUNT + AVG in one round trip) rather than
  /// fetching every review row and averaging in Dart — scales correctly
  /// as review counts grow into the thousands per product.
  Future<({double avg, int count})> aggregateForProduct(Session session, int productId) async {
    final rows = await session.db.unsafeQuery(
      'SELECT COALESCE(AVG("rating"), 0) as avg, COUNT(*) as cnt FROM "reviews" WHERE "productId" = @productId',
      parameters: QueryParameters.named({'productId': productId}),
    );
    final map = rows.first.toColumnMap();
    return (avg: (map['avg'] as num).toDouble(), count: map['cnt'] as int);
  }
}
