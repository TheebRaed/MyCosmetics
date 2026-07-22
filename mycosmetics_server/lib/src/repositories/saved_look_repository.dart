import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class SavedLookRepository {
  Future<List<SavedLook>> listForUser(Session session, int userId) {
    return SavedLook.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
  }

  Future<SavedLook?> findById(Session session, int id) {
    return SavedLook.db.findById(session, id);
  }

  Future<SavedLook> create(Session session, SavedLook look) {
    return SavedLook.db.insertRow(session, look);
  }

  Future<SavedLook> update(Session session, SavedLook look) {
    return SavedLook.db.updateRow(session, look);
  }

  Future<void> delete(Session session, {required int id, required int userId}) {
    return SavedLook.db.deleteWhere(session, where: (t) => t.id.equals(id) & t.userId.equals(userId));
  }
}
