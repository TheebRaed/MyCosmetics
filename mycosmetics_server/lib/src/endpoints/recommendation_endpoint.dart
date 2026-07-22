import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/recommendation_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class RecommendationEndpoint extends Endpoint {
  final RecommendationService _service = RecommendationService();

  Future<RecommendationResult> generate(Session session, {String? categoryFilter}) async {
    final user = await AuthGuard.requireUser(session);
    return _service.generate(session, userId: user.id!, categoryFilter: categoryFilter);
  }

  Future<List<RecommendationHistory>> history(Session session, {int limit = 20}) async {
    final user = await AuthGuard.requireUser(session);
    return _service.history(session, user.id!, limit: limit);
  }

  Future<RecommendationEvent> recordEvent(
    Session session, {
    required int recommendationId,
    required RecommendationEventType eventType,
  }) async {
    final user = await AuthGuard.requireUser(session);
    return _service.recordEvent(
      session,
      userId: user.id!,
      recommendationId: recommendationId,
      eventType: eventType,
    );
  }

  /// Minimal digital swatch preview logging (no AR/image processing) --
  /// see RecommendationService.recordTryOn.
  Future<TryOnEvent> recordTryOn(
    Session session, {
    required int productVariantId,
    required String productCategory,
    required String sessionId,
  }) async {
    final user = await AuthGuard.requireUser(session);
    return _service.recordTryOn(
      session,
      userId: user.id!,
      productVariantId: productVariantId,
      productCategory: productCategory,
      sessionId: sessionId,
    );
  }
}
