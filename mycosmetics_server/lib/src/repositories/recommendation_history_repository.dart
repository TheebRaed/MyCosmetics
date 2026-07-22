import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class RecommendationHistoryRepository {
  Future<RecommendationHistory> insert(Session session, RecommendationHistory history) {
    return RecommendationHistory.db.insertRow(session, history);
  }

  Future<List<RecommendationHistory>> listForUser(Session session, int userId, {int limit = 20}) {
    return RecommendationHistory.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
    );
  }
}
