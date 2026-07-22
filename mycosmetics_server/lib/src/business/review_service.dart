import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide ReviewRepository, OrderRepository, ProductRepository;
import 'package:mycosmetics_server/src/repositories/review_repository.dart';
import 'package:mycosmetics_server/src/repositories/order_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_repository.dart';
import 'package:mycosmetics_server/src/utils/shopping_validator.dart';

class ReviewService {
  final ReviewRepository _reviews = ReviewRepository();
  final OrderRepository _orders = OrderRepository();
  final ProductRepository _products = ProductRepository();

  Future<List<Review>> listForProduct(Session session, int productId, {int page = 0, int pageSize = 20}) {
    ShoppingValidator.validatePagination(page, pageSize);
    return _reviews.listForProduct(session, productId, page: page, pageSize: pageSize);
  }

  /// Enforces "only verified purchasers can review products": the review
  /// must reference an order_item the user actually has, belonging to a
  /// Delivered order, for a variant of the product being reviewed.
  Future<Review> add(
    Session session, {
    required int userId,
    required int orderItemId,
    required int rating,
    String? comment,
  }) async {
    ShoppingValidator.validateRating(rating);

    final orderItem = await _orders.findItemById(session, orderItemId);
    if (orderItem == null) {
      throw ShoppingValidationException('Order item not found.');
    }
    final order = await _orders.findById(session, orderItem.orderId);
    if (order == null || order.userId != userId) {
      throw ShoppingValidationException('You can only review items from your own orders.');
    }
    if (order.status != OrderStatus.delivered) {
      throw ShoppingValidationException('You can only review items after they have been delivered.');
    }

    final existing = await _reviews.findByUserAndOrderItem(session, userId, orderItemId);
    if (existing != null) {
      throw ShoppingValidationException('You have already reviewed this purchase.');
    }

    // productId is derived from the variant on the order item, never
    // trusted as a separate client-supplied parameter — otherwise a caller
    // could submit a valid orderItemId/Delivered order but attach the
    // review to an unrelated product.
    final variant = await _orders.findItemById(session, orderItemId);
    final productId = await _resolveProductIdForVariant(session, variant!.variantId);

    final now = DateTime.now().toUtc();
    final review = await _reviews.create(
      session,
      Review(
        productId: productId,
        userId: userId,
        orderItemId: orderItemId,
        rating: rating,
        comment: comment,
        createdAt: now,
        updatedAt: now,
      ),
    );

    await _recomputeProductRating(session, productId);
    return review;
  }

  Future<Review> update(Session session, {required int userId, required int reviewId, int? rating, String? comment}) async {
    final existing = await _reviews.findById(session, reviewId);
    if (existing == null || existing.userId != userId) {
      throw ShoppingValidationException('Review not found.');
    }
    if (rating != null) ShoppingValidator.validateRating(rating);

    final updated = await _reviews.update(
      session,
      existing.copyWith(
        rating: rating ?? existing.rating,
        comment: comment ?? existing.comment,
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    if (rating != null) {
      await _recomputeProductRating(session, existing.productId);
    }
    return updated;
  }

  Future<void> delete(Session session, {required int userId, required int reviewId}) async {
    final existing = await _reviews.findById(session, reviewId);
    if (existing == null || existing.userId != userId) {
      throw ShoppingValidationException('Review not found.');
    }
    await _reviews.delete(session, id: reviewId, userId: userId);
    await _recomputeProductRating(session, existing.productId);
  }

  /// Recomputes Product.ratingAvg/ratingCount from the reviews table via a
  /// single aggregate query, then writes the result back onto the product
  /// row. This is what keeps the catalog's denormalized rating fields
  /// (used by Phase 2's list/search/sort) accurate after any review change.
  Future<void> _recomputeProductRating(Session session, int productId) async {
    final aggregate = await _reviews.aggregateForProduct(session, productId);
    final product = await _products.findById(session, productId, includeInactive: true);
    if (product == null) return;
    await _products.update(
      session,
      product.copyWith(
        ratingAvg: double.parse(aggregate.avg.toStringAsFixed(2)),
        ratingCount: aggregate.count,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<int> _resolveProductIdForVariant(Session session, int variantId) async {
    final variant = await session.db.unsafeQuery(
      'SELECT "productId" FROM "product_variants" WHERE "id" = @id',
      parameters: QueryParameters.named({'id': variantId}),
    );
    if (variant.isEmpty) {
      throw ShoppingValidationException('Product variant for this order item no longer exists.');
    }
    return variant.first.toColumnMap()['productId'] as int;
  }
}
