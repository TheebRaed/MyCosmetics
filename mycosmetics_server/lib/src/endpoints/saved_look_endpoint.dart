import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/saved_look_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class SavedLookEndpoint extends Endpoint {
  final SavedLookService _service = SavedLookService();

  Future<List<SavedLook>> list(Session session) async {
    final user = await AuthGuard.requireUser(session);
    return _service.list(session, user.id!);
  }

  Future<SavedLook> create(
    Session session, {
    required String name,
    required String imageUrl,
    required List<int> appliedVariantIds,
  }) async {
    final user = await AuthGuard.requireUser(session);
    return _service.create(
      session,
      userId: user.id!,
      name: name,
      imageUrl: imageUrl,
      appliedVariantIds: appliedVariantIds,
    );
  }

  Future<SavedLook> update(
    Session session, {
    required int id,
    String? name,
    bool? isFavorite,
  }) async {
    final user = await AuthGuard.requireUser(session);
    return _service.update(session, userId: user.id!, id: id, name: name, isFavorite: isFavorite);
  }

  Future<void> delete(Session session, {required int id}) async {
    final user = await AuthGuard.requireUser(session);
    await _service.delete(session, userId: user.id!, id: id);
  }
}
