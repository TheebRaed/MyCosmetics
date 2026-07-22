import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/skin_analysis_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class SkinAnalysisEndpoint extends Endpoint {
  final SkinAnalysisService _service = SkinAnalysisService();

  Future<SkinAnalysisResult> submit(
    Session session, {
    required String skinToneHex,
    required String undertone,
    double? brightness,
    double? uniformityScore,
    String? deviceModel,
  }) async {
    final user = await AuthGuard.requireUser(session);
    return _service.submit(
      session,
      userId: user.id!,
      skinToneHex: skinToneHex,
      undertone: undertone,
      brightness: brightness,
      uniformityScore: uniformityScore,
      deviceModel: deviceModel,
    );
  }

  Future<SkinAnalysisResult?> latest(Session session) async {
    final user = await AuthGuard.requireUser(session);
    return _service.latest(session, user.id!);
  }

  Future<List<SkinAnalysisResult>> history(Session session, {int limit = 20}) async {
    final user = await AuthGuard.requireUser(session);
    return _service.history(session, user.id!, limit: limit);
  }
}
