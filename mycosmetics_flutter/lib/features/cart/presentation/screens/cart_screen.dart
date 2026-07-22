import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../providers/cart_providers.dart';

/// Customer app Cart screen -- the "Cart" bottom-nav tab.
///
/// Built against real backend data (`CartEndpoint`/`CouponEndpoint`, see
/// cart_repository.dart):
/// - Item list with quantity controls and remove (`updateQuantity`/`removeItem`)
/// - "Save for later" -- reuses the wishlist mechanism, not a new backend
///   concept (see cart_repository.dart doc comment)
/// - Coupon apply/remove, validated server-side against the live subtotal
/// - Order summary: subtotal / discount / total, all from `CartSummary`
///
/// Deliberately shown as "Calculated at checkout" rather than invented:
/// - Delivery fee -- no fee is knowable until a shipping address is picked
///   (see checkout_repository.dart's `getShippingMethods`, which needs a
///   country + order total).
class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final _couponController = TextEditingController();
  bool _applyingCoupon = false;
  final Set<int> _busyItemIds = {};

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _withItemBusy(int cartItemId, Future<String?> Function() action) async {
    setState(() => _busyItemIds.add(cartItemId));
    final error = await action();
    if (!mounted) return;
    setState(() => _busyItemIds.remove(cartItemId));
    if (error != null) _showMessage(error);
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    setState(() => _applyingCoupon = true);
    final error = await ref.read(cartControllerProvider.notifier).applyCoupon(code);
    if (!mounted) return;
    setState(() => _applyingCoupon = false);
    if (error != null) {
      _showMessage(error);
    } else {
      _couponController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    if (!(authState.value?.hasSession ?? false)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cart')),
        body: Center(
          child: Text('Sign in to view your cart.', style: TextStyle(color: muted)),
        ),
      );
    }

    final asyncCart = ref.watch(cartControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: asyncCart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load your cart", style: TextStyle(color: muted)),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.read(cartControllerProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (cart) {
          if (cart.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_bag_outlined, size: 48, color: muted),
                  const SizedBox(height: AppSpacing.sm),
                  Text('Your cart is empty', style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Add products to see them here.', style: TextStyle(color: muted)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    ...cart.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _CartItemTile(
                          item: item,
                          busy: _busyItemIds.contains(item.cartItem.id),
                          onQuantityChanged: (qty) => _withItemBusy(
                            item.cartItem.id!,
                            () => ref.read(cartControllerProvider.notifier).updateQuantity(
                                  cartItemId: item.cartItem.id!,
                                  quantity: qty,
                                ),
                          ),
                          onRemove: () => _withItemBusy(
                            item.cartItem.id!,
                            () => ref.read(cartControllerProvider.notifier).removeItem(cartItemId: item.cartItem.id!),
                          ),
                          onSaveForLater: () => _withItemBusy(
                            item.cartItem.id!,
                            () => ref.read(cartControllerProvider.notifier).moveToWishlist(
                                  cartItemId: item.cartItem.id!,
                                  productId: item.productId,
                                ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _CouponSection(
                      cart: cart,
                      controller: _couponController,
                      applying: _applyingCoupon,
                      onApply: _applyCoupon,
                      onRemove: () async {
                        final error = await ref.read(cartControllerProvider.notifier).removeCoupon();
                        if (error != null) _showMessage(error);
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _OrderSummary(cart: cart),
                  ],
                ),
              ),
              _CheckoutBar(
                cart: cart,
                onCheckout: () => context.push(AppRoutes.checkout),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.busy,
    required this.onQuantityChanged,
    required this.onRemove,
    required this.onSaveForLater,
  });

  final CartItemDetail item;
  final bool busy;
  final void Function(int) onQuantityChanged;
  final VoidCallback onRemove;
  final VoidCallback onSaveForLater;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    return AppCard(
      child: Opacity(
        opacity: busy ? 0.6 : 1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.chip),
              child: SizedBox(
                width: 64,
                height: 64,
                child: item.imageUrl != null
                    ? Image.network(
                        item.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: muted.withValues(alpha: 0.12)),
                      )
                    : Container(
                        color: muted.withValues(alpha: 0.12),
                        child: Icon(Icons.spa_outlined, color: muted),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: heading, fontWeight: FontWeight.w600),
                  ),
                  if (item.shadeName != null && item.shadeName!.isNotEmpty)
                    Text(item.shadeName!, style: TextStyle(color: muted, fontSize: 12)),
                  if (!item.isAvailable) ...[
                    const SizedBox(height: 2),
                    Text('No longer available', style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  Text('\$${item.unitPrice.toStringAsFixed(2)}',
                      style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.xs),
                  if (item.isAvailable)
                    _QuantityStepper(
                      quantity: item.cartItem.quantity,
                      maxQuantity: item.availableStock,
                      busy: busy,
                      onChanged: onQuantityChanged,
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Wrap(
                    spacing: AppSpacing.md,
                    children: [
                      GestureDetector(
                        onTap: busy ? null : onSaveForLater,
                        child: Text('Save for later', style: TextStyle(color: chipText, fontSize: 12)),
                      ),
                      GestureDetector(
                        onTap: busy ? null : onRemove,
                        child: Text('Remove', style: TextStyle(color: muted, fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  const _QuantityStepper({
    required this.quantity,
    required this.maxQuantity,
    required this.busy,
    required this.onChanged,
  });

  final int quantity;
  final int maxQuantity;
  final bool busy;
  final void Function(int) onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? AppColorsDark.chipBg : AppColorsLight.chipBg;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;

    return Container(
      decoration: BoxDecoration(color: chipBg, borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: (busy || quantity <= 1) ? null : () => onChanged(quantity - 1),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
          Text('$quantity', style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: (busy || quantity >= maxQuantity) ? null : () => onChanged(quantity + 1),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}

class _CouponSection extends StatelessWidget {
  const _CouponSection({
    required this.cart,
    required this.controller,
    required this.applying,
    required this.onApply,
    required this.onRemove,
  });

  final CartSummary cart;
  final TextEditingController controller;
  final bool applying;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    return AppCard(
      child: cart.appliedCouponCode != null
          ? Row(
              children: [
                Icon(Icons.local_offer_outlined, color: chipText, size: 18),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text('Coupon "${cart.appliedCouponCode}" applied',
                      style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                ),
                TextButton(onPressed: onRemove, child: const Text('Remove')),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Coupon code',
                      hintStyle: TextStyle(color: muted),
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.input)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: applying ? null : onApply,
                  child: applying
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Apply'),
                ),
              ],
            ),
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.cart});

  final CartSummary cart;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          _SummaryRow(label: 'Subtotal', value: cart.subtotal, muted: muted, heading: heading),
          if (cart.discountAmount > 0)
            _SummaryRow(label: 'Discount', value: -cart.discountAmount, muted: muted, heading: heading),
          _SummaryRow(label: 'Delivery fee', valueLabel: 'Calculated at checkout', muted: muted, heading: heading),
          const Divider(height: AppSpacing.lg),
          _SummaryRow(label: 'Total', value: cart.total, muted: muted, heading: heading, bold: true),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    this.value,
    this.valueLabel,
    required this.muted,
    required this.heading,
    this.bold = false,
  });

  final String label;
  final double? value;
  final String? valueLabel;
  final Color muted;
  final Color heading;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final text = valueLabel ?? '${value! < 0 ? '-' : ''}\$${value!.abs().toStringAsFixed(2)}';
    final style = TextStyle(
      color: bold ? heading : muted,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(text, style: style)],
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.cart, required this.onCheckout});

  final CartSummary cart;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final hasAvailableItems = cart.items.any((i) => i.isAvailable);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.drawer(brightness),
        boxShadow: AppShadows.elevated(brightness),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: PillButton(
            label: 'Proceed to Checkout · \$${cart.total.toStringAsFixed(2)}',
            expand: true,
            onPressed: hasAvailableItems ? onCheckout : null,
          ),
        ),
      ),
    );
  }
}
