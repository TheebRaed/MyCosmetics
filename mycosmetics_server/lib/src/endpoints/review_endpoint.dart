import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/review_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class ReviewEndpoint extends Endpoint {
  final ReviewService _reviews = ReviewService();

  Future<List<Review>> listForProduct(Session session, {required int productId, int page = 0, int pageSize = 20}) {
    return _reviews.listForProduct(session, productId, page: page, pageSize: pageSize);
  }

  Future<Review> add(
    Session session, {
    required int orderItemId,
    required int rating,
    String? comment,
  }) async {
    final user = await AuthGuard.requireUser(session);
    return _reviews.add(session, userId: user.id!, orderItemId: orderItemId, rating: rating, comment: comment);
  }

  Future<Review> update(Session session, {required int reviewId, int? rating, String? comment}) async {
    final user = await AuthGuard.requireUser(session);
    return _reviews.update(session, userId: user.id!, reviewId: reviewId, rating: rating, comment: comment);
  }

  Future<void> delete(Session session, {required int reviewId}) async {
    final user = await AuthGuard.requireUser(session);
    await _reviews.delete(session, userId: user.id!, reviewId: reviewId);
  }
}
