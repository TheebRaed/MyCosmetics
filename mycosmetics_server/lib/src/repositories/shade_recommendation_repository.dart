import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class ShadeRecommendationRepository {
  Future<ShadeRecommendation> insert(Session session, ShadeRecommendation rec) {
    return ShadeRecommendation.db.insertRow(session, rec);
  }

  Future<ShadeRecommendation?> findById(Session session, int id) {
    return ShadeRecommendation.db.findById(session, id);
  }

  Future<List<ShadeRecommendation>> listForUser(Session session, int userId, {int limit = 20}) {
    return ShadeRecommendation.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
    );
  }

  Future<List<ShadeRecommendation>> listByIds(Session session, Set<int> ids) {
    if (ids.isEmpty) return Future.value(const []);
    return ShadeRecommendation.db.find(session, where: (t) => t.id.inSet(ids));
  }

  /// All ShadeRecommendation rows pointing at any of the given variants --
  /// used to resolve variantId -> recommendationIds when aggregating event
  /// counts per variant.
  Future<List<ShadeRecommendation>> listByVariantIds(Session session, Set<int> variantIds) {
    if (variantIds.isEmpty) return Future.value(const []);
    return ShadeRecommendation.db.find(session, where: (t) => t.productVariantId.inSet(variantIds));
  }

  /// All ShadeRecommendation rows for a given category -- used to resolve
  /// this user's preference history within that category.
  Future<List<ShadeRecommendation>> listByCategory(Session session, String category) {
    return ShadeRecommendation.db.find(session, where: (t) => t.category.equals(category));
  }
}
