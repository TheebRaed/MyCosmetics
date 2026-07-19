import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

/// All direct DB access for User lives here. Endpoints never call
/// User.db.* directly, so query logic can be unit-tested/changed in one place.
class UserRepository {
  Future<User?> findByEmail(Session session, String email) {
    return User.db.findFirstRow(
      session,
      where: (t) => t.email.equals(email.toLowerCase()) & t.deletedAt.equals(null),
    );
  }

  Future<User?> findById(Session session, int id) {
    return User.db.findById(session, id);
  }

  Future<User> create(Session session, User user) {
    return User.db.insertRow(session, user);
  }

  Future<User> update(Session session, User user) {
    return User.db.updateRow(session, user);
  }

  Future<void> softDelete(Session session, int id) async {
    final user = await findById(session, id);
    if (user == null) return;
    await User.db.updateRow(
      session,
      user.copyWith(deletedAt: DateTime.now().toUtc(), isActive: false),
    );
  }
}
