import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';

class CouponRepository {
  Future<Coupon?> findByCode(Session session, String code) {
    return Coupon.db.findFirstRow(session, where: (t) => t.code.equals(code.toUpperCase()));
  }

  Future<Coupon?> findById(Session session, int id) {
    return Coupon.db.findById(session, id);
  }

  Future<Coupon> create(Session session, Coupon coupon) {
    return Coupon.db.insertRow(session, coupon);
  }

  Future<Coupon> update(Session session, Coupon coupon) {
    return Coupon.db.updateRow(session, coupon);
  }

  /// Atomically increments usedCount only if it is still under the limit,
  /// in a single UPDATE ... WHERE statement via raw SQL. This closes the
  /// race condition that would exist if we did
  /// "read usedCount, check < limit, write usedCount+1" as separate steps \u2014
  /// two concurrent checkouts could otherwise both pass the check and push
  /// usedCount past usageLimit. Returns true if the increment succeeded.
  Future<bool> tryIncrementUsage(Session session, int couponId) async {
    final result = await session.db.unsafeQuery(
      'UPDATE "coupons" SET "usedCount" = "usedCount" + 1, "updatedAt" = @now '
      'WHERE "id" = @id AND ("usageLimit" IS NULL OR "usedCount" < "usageLimit") '
      'RETURNING "id"',
      parameters: QueryParameters.named({
        'id': couponId,
        'now': DateTime.now().toUtc(),
      }),
    );
    return result.isNotEmpty;
  }

  /// Reverses tryIncrementUsage; used when an order built around the
  /// coupon fails after the increment (e.g. stock validation fails
  /// downstream in the same checkout transaction).
  Future<void> decrementUsage(Session session, int couponId) async {
    await session.db.unsafeQuery(
      'UPDATE "coupons" SET "usedCount" = GREATEST("usedCount" - 1, 0), "updatedAt" = @now WHERE "id" = @id',
      parameters: QueryParameters.named({'id': couponId, 'now': DateTime.now().toUtc()}),
    );
  }
}
