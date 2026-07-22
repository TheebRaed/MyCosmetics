import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class TryOnEventRepository {
  Future<TryOnEvent> insert(Session session, TryOnEvent event) {
    return TryOnEvent.db.insertRow(session, event);
  }

  /// All try-on events (any user) for the given variants -- used for the
  /// popularity score component.
  Future<List<TryOnEvent>> listForVariants(Session session, Set<int> variantIds) {
    if (variantIds.isEmpty) return Future.value(const []);
    return TryOnEvent.db.find(session, where: (t) => t.productVariantId.inSet(variantIds));
  }

  /// This user's own try-on events for the given variants -- used for the
  /// scoreTryOnActivity component.
  Future<List<TryOnEvent>> listForUserAndVariants(Session session, int userId, Set<int> variantIds) {
    if (variantIds.isEmpty) return Future.value(const []);
    return TryOnEvent.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.productVariantId.inSet(variantIds),
    );
  }
}
