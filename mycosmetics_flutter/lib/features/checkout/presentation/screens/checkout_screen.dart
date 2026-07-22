import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/pill_button.dart';
import '../../../cart/presentation/providers/cart_providers.dart';
import '../../data/checkout_repository.dart';
import '../providers/checkout_providers.dart';
import '../widgets/address_form_sheet.dart';

/// Checkout screen, reached from Cart's "Proceed to Checkout" -- `/checkout`.
///
/// Built against real backend data (see checkout_repository.dart for exact
/// endpoints and the honesty notes on shipping fee / payment):
/// - Addresses: real CRUD via `ProfileEndpoint`
/// - Shipping methods: real via `PaymentEndpoint.getShippingMethods`, fee
///   shown as an estimate (not yet part of `Order.total` server-side)
/// - Coupon: carried over from Cart's `CartController` state, not re-entered
/// - Order summary: real cart totals
/// - Payment: Cash on Delivery only (the one real, end-to-end path) --
///   Stripe card payment is a server-side mock with no client SDK wired in,
///   so it's not offered as a selectable option
/// - On success: navigates to the order confirmation screen with the real
///   `OrderDetail` returned by `OrderEndpoint.checkout`
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int? _selectedAddressId;
  String? _selectedShippingMethodId;
  bool _placingOrder = false;

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _addAddress() async {
    final draft = await showAddressFormSheet(context);
    if (draft == null) return;
    try {
      final created = await ref.read(addressListProvider.notifier).add(draft);
      if (created?.id != null) setState(() => _selectedAddressId = created!.id);
    } catch (_) {
      _showMessage("Couldn't save address");
    }
  }

  Future<void> _placeOrder(CartSummary cart) async {
    final addressId = _selectedAddressId;
    if (addressId == null) {
      _showMessage('Select a shipping address.');
      return;
    }
    setState(() => _placingOrder = true);
    try {
      final repo = ref.read(checkoutRepositoryProvider);
      final orderDetail = await repo.checkout(addressId: addressId);
      await repo.payCashOnDelivery(orderId: orderDetail.order.id!);
      ref.invalidate(cartControllerProvider);
      if (!mounted) return;
      context.pushReplacement(AppRoutes.orderConfirmation, extra: orderDetail);
    } catch (e) {
      if (!mounted) return;
      _showMessage(_friendlyCheckoutError(e));
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    final asyncCart = ref.watch(cartControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: asyncCart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text("Couldn't load your cart", style: TextStyle(color: muted))),
        data: (cart) {
          if (cart.items.isEmpty) {
            return Center(child: Text('Your cart is empty.', style: TextStyle(color: muted)));
          }

          final asyncAddresses = ref.watch(addressListProvider);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text('Shipping Address', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              asyncAddresses.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (_, __) => Text("Couldn't load addresses", style: TextStyle(color: muted)),
                data: (addresses) {
                  if (addresses.isNotEmpty && _selectedAddressId == null) {
                    final defaultAddr = addresses.where((a) => a.isDefault);
                    _selectedAddressId = (defaultAddr.isNotEmpty ? defaultAddr.first : addresses.first).id;
                  }
                  final selected = addresses.where((a) => a.id == _selectedAddressId);
                  final selectedAddress = selected.isEmpty ? null : selected.first;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (addresses.isEmpty)
                        Text('No saved addresses yet.', style: TextStyle(color: muted))
                      else
                        ...addresses.map(
                          (a) => AppCard(
                            padding: EdgeInsets.zero,
                            child: RadioListTile<int>(
                              value: a.id!,
                              groupValue: _selectedAddressId,
                              onChanged: (v) => setState(() => _selectedAddressId = v),
                              title: Text(a.fullName, style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${a.line1}${a.line2 != null ? ', ${a.line2}' : ''}, ${a.city}, ${a.country}',
                                style: TextStyle(color: muted),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.sm),
                      TextButton.icon(
                        onPressed: _addAddress,
                        icon: const Icon(Icons.add),
                        label: const Text('Add new address'),
                      ),
                      if (selectedAddress != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text('Shipping Method', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpacing.sm),
                        _ShippingMethodSection(
                          country: selectedAddress.country,
                          orderTotal: cart.total,
                          selectedId: _selectedShippingMethodId,
                          onSelected: (id) => setState(() => _selectedShippingMethodId = id),
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Payment Method', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.payments_outlined, color: heading),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cash on Delivery', style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                          Text('Pay when your order arrives.', style: TextStyle(color: muted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle, color: heading),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  'Card payment (Stripe) is coming soon.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _OrderSummaryCard(cart: cart),
              const SizedBox(height: AppSpacing.lg),
              PillButton(
                label: _placingOrder ? 'Placing Order...' : 'Place Order · \$${cart.total.toStringAsFixed(2)}',
                expand: true,
                onPressed: _placingOrder ? null : () => _placeOrder(cart),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          );
        },
      ),
    );
  }
}

class _ShippingMethodSection extends ConsumerWidget {
  const _ShippingMethodSection({
    required this.country,
    required this.orderTotal,
    required this.selectedId,
    required this.onSelected,
  });

  final String country;
  final double orderTotal;
  final String? selectedId;
  final void Function(String?) onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    final asyncMethods = ref.watch(shippingMethodsProvider(country: country, orderTotal: orderTotal));

    return asyncMethods.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Text("Couldn't load shipping methods", style: TextStyle(color: muted)),
      data: (methods) {
        if (methods.isEmpty) {
          return Text('No shipping methods available for this address.', style: TextStyle(color: muted));
        }
        // Default to the first method once loaded.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (selectedId == null) onSelected(methods.first['id'] as String);
        });
        return Column(
          children: methods.map((m) {
            final id = m['id'] as String;
            final fee = (m['fee'] as num).toDouble();
            final isFree = m['isFree'] == true;
            return AppCard(
              padding: EdgeInsets.zero,
              child: RadioListTile<String>(
                value: id,
                groupValue: selectedId,
                onChanged: onSelected,
                title: Text(m['name'] as String, style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                subtitle: Text('${m['estimatedDays']} day(s)', style: TextStyle(color: muted)),
                secondary: Text(
                  isFree ? 'Free' : '\$${fee.toStringAsFixed(2)}',
                  style: TextStyle(color: heading, fontWeight: FontWeight.w700),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _OrderSummaryCard extends ConsumerWidget {
  const _OrderSummaryCard({required this.cart});

  final CartSummary cart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
          const SizedBox(height: AppSpacing.sm),
          _row('Subtotal', '\$${cart.subtotal.toStringAsFixed(2)}', muted, heading),
          if (cart.discountAmount > 0)
            _row(
              'Discount${cart.appliedCouponCode != null ? ' (${cart.appliedCouponCode})' : ''}',
              '-\$${cart.discountAmount.toStringAsFixed(2)}',
              muted,
              heading,
            ),
          const Divider(height: AppSpacing.lg),
          _row('Total charged', '\$${cart.total.toStringAsFixed(2)}', heading, heading, bold: true),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Delivery fee shown above is an estimate and is not yet included in the charged total.',
            style: TextStyle(color: muted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, Color labelColor, Color valueColor, {bool bold = false}) {
    final style = TextStyle(color: labelColor, fontWeight: bold ? FontWeight.w700 : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}

String _friendlyCheckoutError(Object e) {
  final raw = e.toString();
  if (raw.contains('Internal server error')) return 'Something went wrong. Please try again.';
  final match = RegExp(r'^ServerpodClientException:\s*(.*?),\s*statusCode').firstMatch(raw);
  return match?.group(1) ?? 'Something went wrong. Please try again.';
}
