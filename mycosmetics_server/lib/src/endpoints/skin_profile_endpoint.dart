import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/skin_profile_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class SkinProfileEndpoint extends Endpoint {
  final SkinProfileService _service = SkinProfileService();

  Future<SkinProfile?> get(Session session) async {
    final user = await AuthGuard.requireUser(session);
    return _service.get(session, user.id!);
  }

  Future<SkinProfile> save(
    Session session, {
    String? skinToneHex,
    String? undertone,
    String? concerns,
  }) async {
    final user = await AuthGuard.requireUser(session);
    return _service.save(
      session,
      userId: user.id!,
      skinToneHex: skinToneHex,
      undertone: undertone,
      concerns: concerns,
    );
  }

  Future<void> reset(Session session) async {
    final user = await AuthGuard.requireUser(session);
    await _service.reset(session, user.id!);
  }
}
