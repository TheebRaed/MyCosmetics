import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class SkinAnalysisRepository {
  Future<SkinAnalysisResult> insert(Session session, SkinAnalysisResult result) {
    return SkinAnalysisResult.db.insertRow(session, result);
  }

  Future<SkinAnalysisResult?> findLatestByUserId(Session session, int userId) async {
    final rows = await SkinAnalysisResult.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<List<SkinAnalysisResult>> findHistoryByUserId(Session session, int userId, {int limit = 20}) {
    return SkinAnalysisResult.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
      limit: limit,
    );
  }
}
