import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class AddressRepository {
  Future<List<Address>> listForUser(Session session, int userId) {
    return Address.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.isDefault,
      orderDescending: true,
    );
  }

  Future<Address?> findById(Session session, int id) {
    return Address.db.findById(session, id);
  }

  Future<Address> create(Session session, Address address) {
    return Address.db.insertRow(session, address);
  }

  Future<Address> update(Session session, Address address) {
    return Address.db.updateRow(session, address);
  }

  Future<void> delete(Session session, int id) {
    return Address.db.deleteWhere(session, where: (t) => t.id.equals(id));
  }

  /// Clears isDefault on all of a user's other addresses (used when setting a new default).
  Future<void> clearDefaultForUser(Session session, int userId) async {
    final addresses = await listForUser(session, userId);
    for (final a in addresses.where((a) => a.isDefault)) {
      await update(session, a.copyWith(isDefault: false));
    }
  }
}
