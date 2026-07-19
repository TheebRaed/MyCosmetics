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
}
