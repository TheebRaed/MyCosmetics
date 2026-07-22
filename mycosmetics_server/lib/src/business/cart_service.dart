import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide CartRepository, ProductVariantRepository, ProductRepository, ProductImageRepository, CouponRepository;
import 'package:mycosmetics_server/src/repositories/cart_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_variant_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_repository.dart';
import 'package:mycosmetics_server/src/repositories/product_image_repository.dart';
import 'package:mycosmetics_server/src/repositories/coupon_repository.dart';
import 'package:mycosmetics_server/src/business/coupon_service.dart';
import 'package:mycosmetics_server/src/utils/shopping_validator.dart';

class CartService {
  final CartRepository _carts = CartRepository();
  final ProductVariantRepository _variants = ProductVariantRepository();
  final ProductRepository _products = ProductRepository();
  final ProductImageRepository _images = ProductImageRepository();
  final CouponRepository _coupons = CouponRepository();
  final CouponService _couponService = CouponService();

  Future<CartItemDetail> _composeItemDetail(Session session, CartItem item) async {
    final variant = await _variants.findById(session, item.variantId);
    if (variant == null) {
      // Variant was hard-removed from under an existing cart line (shouldn't
      // normally happen since variants cascade-delete their cart_items, but
      // guard defensively rather than crashing the whole cart read).
      return CartItemDetail(
        cartItem: item,
        productId: 0,
        productName: 'Unavailable item',
        unitPrice: 0,
        availableStock: 0,
        lineTotal: 0,
        isAvailable: false,
      );
    }
    final product = await _products.findById(session, variant.productId, includeInactive: true);
    final images = await _images.listForVariant(session, variant.id!);
    final fallbackImages = images.isEmpty ? await _images.listForProduct(session, variant.productId) : images;

    final isAvailable = variant.isActive &&
        variant.stockQty > 0 &&
        product != null &&
        product.isActive &&
        product.deletedAt == null;

    return CartItemDetail(
      cartItem: item,
      productId: variant.productId,
      productName: product?.name ?? 'Unknown product',
      shadeName: variant.shadeName,
      hexColor: variant.hexColor,
      imageUrl: fallbackImages.isNotEmpty ? fallbackImages.first.url : null,
      unitPrice: variant.price,
      availableStock: variant.stockQty,
      lineTotal: variant.price * item.quantity,
      isAvailable: isAvailable,
    );
  }

  Future<CartSummary> getCart(Session session, int userId) async {
    final cart = await _carts.getOrCreate(session, userId);
    final items = await _carts.listItems(session, cart.id!);
    final details = await Future.wait(items.map((i) => _composeItemDetail(session, i)));

    // Unavailable lines (out of stock / deactivated / deleted product)
    // still show in the cart for transparency but never count toward the
    // subtotal — matches "stock validation" being enforced at totals time,
    // not just at add-time.
    final subtotal = details.where((d) => d.isAvailable).fold(0.0, (sum, d) => sum + d.lineTotal);

    String? couponCode;
    double discount = 0;
    if (cart.appliedCouponId != null) {
      final coupon = await _coupons.findById(session, cart.appliedCouponId!);
      if (coupon != null) {
        final validation = await _couponService.validate(session, code: coupon.code, subtotal: subtotal);
        if (validation.isValid) {
          couponCode = coupon.code;
          discount = validation.discountAmount;
        } else {
          // Coupon became invalid (expired/exhausted/min spend no longer
          // met) since it was applied — silently drop it from the totals
          // rather than surfacing a confusing error on every cart read.
          await _carts.update(session, cart.copyWith(appliedCouponId: null, updatedAt: DateTime.now().toUtc()));
        }
      }
    }

    return CartSummary(
      cartId: cart.id!,
      items: details,
      subtotal: subtotal,
      appliedCouponCode: couponCode,
      discountAmount: discount,
      total: (subtotal - discount).clamp(0.0, double.infinity),
    );
  }

  Future<CartSummary> addItem(Session session, {required int userId, required int variantId, required int quantity}) async {
    ShoppingValidator.validateQuantity(quantity);

    final variant = await _variants.findById(session, variantId);
    if (variant == null || !variant.isActive) {
      throw ShoppingValidationException('This product variant is not available.');
    }
    final product = await _products.findById(session, variant.productId);
    if (product == null) {
      throw ShoppingValidationException('This product is not available.');
    }

    final cart = await _carts.getOrCreate(session, userId);
    final existing = await _carts.findItem(session, cart.id!, variantId);
    final desiredQty = (existing?.quantity ?? 0) + quantity;

    if (desiredQty > variant.stockQty) {
      throw ShoppingValidationException(
        'Only ${variant.stockQty} unit(s) of this item are in stock.',
      );
    }

    final now = DateTime.now().toUtc();
    if (existing != null) {
      await _carts.updateItem(session, existing.copyWith(quantity: desiredQty, updatedAt: now));
    } else {
      await _carts.addItem(
        session,
        CartItem(cartId: cart.id!, variantId: variantId, quantity: quantity, createdAt: now, updatedAt: now),
      );
    }
    return getCart(session, userId);
  }

  Future<CartSummary> updateQuantity(Session session, {required int userId, required int cartItemId, required int quantity}) async {
    ShoppingValidator.validateQuantity(quantity);

    final cart = await _carts.getOrCreate(session, userId);
    final item = await _carts.findItemById(session, cartItemId);
    if (item == null || item.cartId != cart.id) {
      throw ShoppingValidationException('Cart item not found.');
    }

    final variant = await _variants.findById(session, item.variantId);
    if (variant == null || !variant.isActive) {
      throw ShoppingValidationException('This product variant is no longer available.');
    }
    if (quantity > variant.stockQty) {
      throw ShoppingValidationException('Only ${variant.stockQty} unit(s) of this item are in stock.');
    }

    await _carts.updateItem(session, item.copyWith(quantity: quantity, updatedAt: DateTime.now().toUtc()));
    return getCart(session, userId);
  }

  Future<CartSummary> removeItem(Session session, {required int userId, required int cartItemId}) async {
    final cart = await _carts.getOrCreate(session, userId);
    final item = await _carts.findItemById(session, cartItemId);
    if (item == null || item.cartId != cart.id) {
      throw ShoppingValidationException('Cart item not found.');
    }
    await _carts.removeItem(session, cartItemId);
    return getCart(session, userId);
  }

  Future<CartSummary> clearCart(Session session, int userId) async {
    final cart = await _carts.getOrCreate(session, userId);
    await _carts.clearItems(session, cart.id!);
    if (cart.appliedCouponId != null) {
      await _carts.update(session, cart.copyWith(appliedCouponId: null, updatedAt: DateTime.now().toUtc()));
    }
    return getCart(session, userId);
  }
}
