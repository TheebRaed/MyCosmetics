import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class RecommendationEventRepository {
  Future<RecommendationEvent> insert(Session session, RecommendationEvent event) {
    return RecommendationEvent.db.insertRow(session, event);
  }

  Future<RecommendationEvent?> findById(Session session, int id) {
    return RecommendationEvent.db.findById(session, id);
  }

  Future<List<RecommendationEvent>> listForUser(Session session, int userId, {int limit = 50}) {
    return RecommendationEvent.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Events of the given types for the given recommendation ids, across all
  /// users. Used by RecommendationService (via ShadeRecommendationRepository
  /// to resolve variantId -> recommendationIds first) to build popularity
  /// counts.
  Future<List<RecommendationEvent>> listForRecommendations(
    Session session,
    Set<int> recommendationIds, {
    Set<RecommendationEventType>? types,
  }) {
    if (recommendationIds.isEmpty) return Future.value(const []);
    return RecommendationEvent.db.find(
      session,
      where: (t) => types == null
          ? t.recommendationId.inSet(recommendationIds)
          : t.recommendationId.inSet(recommendationIds) & t.eventType.inSet(types),
    );
  }

  /// This user's own events for a set of recommendation ids -- used for
  /// scoreUserPreference (category-scoped) history lookups.
  Future<List<RecommendationEvent>> listForUserAndRecommendations(
    Session session,
    int userId,
    Set<int> recommendationIds,
  ) {
    if (recommendationIds.isEmpty) return Future.value(const []);
    return RecommendationEvent.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.recommendationId.inSet(recommendationIds),
    );
  }
}
