import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class SkinProfileRepository {
  Future<SkinProfile?> findByUserId(Session session, int userId) {
    return SkinProfile.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId),
    );
  }

  Future<SkinProfile> upsert(Session session, SkinProfile profile) async {
    final existing = await findByUserId(session, profile.userId);
    if (existing == null) {
      return SkinProfile.db.insertRow(session, profile);
    }
    return SkinProfile.db.updateRow(session, profile.copyWith(id: existing.id));
  }

  Future<SkinProfile?> findById(Session session, int id) {
    return SkinProfile.db.findById(session, id);
  }

  /// Deletes the user's skin profile (reset-profile flow). Downstream rows
  /// (SkinAnalysisResult.skinProfileId, RecommendationHistory.skinProfileId,
  /// ShadeRecommendation.skinProfileId) are handled by their own FK
  /// onDelete behavior (SetNull / Restrict / Cascade per protocol) -- this
  /// method does not need to cascade manually.
  Future<void> delete(Session session, int userId) {
    return SkinProfile.db.deleteWhere(session, where: (t) => t.userId.equals(userId));
  }
}
