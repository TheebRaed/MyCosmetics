import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/coupon_service.dart';
import 'package:mycosmetics_server/src/business/cart_service.dart';
import 'package:mycosmetics_server/src/utils/auth_guard.dart';

class CouponEndpoint extends Endpoint {
  final CouponService _coupons = CouponService();
  final CartService _cart = CartService();

  /// Validates against the user's CURRENT live cart subtotal (recomputed
  /// here, never trusted from the client) so a manipulated subtotal can't
  /// be used to unlock a bigger discount than the real cart qualifies for.
  Future<CouponValidationResult> validate(Session session, {required String code}) async {
    final user = await AuthGuard.requireUser(session);
    final cartSummary = await _cart.getCart(session, user.id!);
    return _coupons.validate(session, code: code, subtotal: cartSummary.subtotal);
  }

  Future<CouponValidationResult> apply(Session session, {required String code}) async {
    final user = await AuthGuard.requireUser(session);
    final cartSummary = await _cart.getCart(session, user.id!);
    return _coupons.apply(session, userId: user.id!, code: code, currentSubtotal: cartSummary.subtotal);
  }

  Future<void> remove(Session session) async {
    final user = await AuthGuard.requireUser(session);
    await _coupons.remove(session, userId: user.id!);
  }

  Future<Coupon> create(
    Session session, {
    required String code,
    required CouponType type,
    required double value,
    double minSpend = 0,
    double? maxDiscount,
    int? usageLimit,
    DateTime? expiresAt,
  }) async {
    await AuthGuard.requireAdminOrStaff(session);
    return _coupons.create(
      session,
      code: code,
      type: type,
      value: value,
      minSpend: minSpend,
      maxDiscount: maxDiscount,
      usageLimit: usageLimit,
      expiresAt: expiresAt,
    );
  }

  Future<Coupon> setActive(Session session, {required int id, required bool isActive}) async {
    await AuthGuard.requireAdminOrStaff(session);
    return _coupons.setActive(session, id: id, isActive: isActive);
  }
}
