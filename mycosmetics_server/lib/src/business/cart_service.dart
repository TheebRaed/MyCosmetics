import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/repositories/coupon_repository.dart';
import 'package:mycosmetics_server/src/repositories/cart_repository.dart';
import 'package:mycosmetics_server/src/utils/shopping_validator.dart';

class CouponService {
  final CouponRepository _coupons = CouponRepository();
  final CartRepository _carts = CartRepository();

  /// Pure validation against a given subtotal \u2014 does not touch usedCount.
  /// Used both for the standalone "validate" endpoint and internally by
  /// CartService on every cart read (so a coupon that's expired or hit its
  /// limit since being applied is reflected immediately, not just at checkout).
  Future<CouponValidationResult> validate(Session session, {required String code, required double subtotal}) async {
    final coupon = await _coupons.findByCode(session, code);
    if (coupon == null) {
      return CouponValidationResult(isValid: false, message: 'Coupon code not found.', discountAmount: 0);
    }
    if (!coupon.isActive) {
      return CouponValidationResult(isValid: false, message: 'This coupon is no longer active.', discountAmount: 0);
    }
    if (coupon.expiresAt != null && coupon.expiresAt!.isBefore(DateTime.now().toUtc())) {
      return CouponValidationResult(isValid: false, message: 'This coupon has expired.', discountAmount: 0);
    }
    if (coupon.usageLimit != null && coupon.usedCount >= coupon.usageLimit!) {
      return CouponValidationResult(isValid: false, message: 'This coupon has reached its usage limit.', discountAmount: 0);
    }
    if (subtotal < coupon.minSpend) {
      return CouponValidationResult(
        isValid: false,
        message: 'Minimum spend of \$${coupon.minSpend.toStringAsFixed(2)} required for this coupon.',
        discountAmount: 0,
      );
    }

    double discount = coupon.type == CouponType.percentage ? subtotal * (coupon.value / 100) : coupon.value;
    if (coupon.maxDiscount != null && discount > coupon.maxDiscount!) {
      discount = coupon.maxDiscount!;
    }
    discount = discount.clamp(0, subtotal);

    return CouponValidationResult(isValid: true, message: 'Coupon applied.', discountAmount: discount);
  }

  Future<CouponValidationResult> apply(Session session, {required int userId, required String code, required double currentSubtotal}) async {
    ShoppingValidator.validateCouponCode(code);
    final result = await validate(session, code: code, subtotal: currentSubtotal);
    if (!result.isValid) return result;

    final coupon = await _coupons.findByCode(session, code);
    final cart = await _carts.getOrCreate(session, userId);
    await _carts.update(session, cart.copyWith(appliedCouponId: coupon!.id, updatedAt: DateTime.now().toUtc()));
    return result;
  }

  Future<void> remove(Session session, {required int userId}) async {
    final cart = await _carts.getOrCreate(session, userId);
    if (cart.appliedCouponId == null) return;
    await _carts.update(session, cart.copyWith(appliedCouponId: null, updatedAt: DateTime.now().toUtc()));
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
    final normalizedCode = code.trim().toUpperCase();
    ShoppingValidator.validateCouponCode(normalizedCode);
    if (value <= 0) throw ShoppingValidationException('Coupon value must be positive.');
    if (type == CouponType.percentage && value > 100) {
      throw ShoppingValidationException('Percentage coupon value cannot exceed 100.');
    }

    final existing = await _coupons.findByCode(session, normalizedCode);
    if (existing != null) throw ShoppingValidationException('A coupon with this code already exists.');

    final now = DateTime.now().toUtc();
    return _coupons.create(
      session,
      Coupon(
        code: normalizedCode,
        type: type,
        value: value,
        minSpend: minSpend,
        maxDiscount: maxDiscount,
        usageLimit: usageLimit,
        usedCount: 0,
        expiresAt: expiresAt,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<Coupon> setActive(Session session, {required int id, required bool isActive}) async {
    final coupon = await _coupons.findById(session, id);
    if (coupon == null) throw ShoppingValidationException('Coupon not found.');
    return _coupons.update(session, coupon.copyWith(isActive: isActive, updatedAt: DateTime.now().toUtc()));
  }
}
