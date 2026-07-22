import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/pill_button.dart';

/// Order confirmation, reached after a real `OrderEndpoint.checkout()`
/// success -- shows the actual created order (id, items, address, total),
/// not a generic "thank you".
class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({super.key, required this.orderDetail});

  final OrderDetail orderDetail;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final order = orderDetail.order;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const SizedBox(height: AppSpacing.xl),
            Icon(Icons.check_circle, color: chipText, size: 64),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'Order Placed',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: heading),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text('Order #${order.id}', style: TextStyle(color: muted)),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Items', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.sm),
                  ...orderDetail.items.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${item.productNameSnapshot}${item.shadeNameSnapshot != null ? ' (${item.shadeNameSnapshot})' : ''} x${item.quantity}',
                              style: TextStyle(color: heading),
                            ),
                          ),
                          Text('\$${item.lineTotal.toStringAsFixed(2)}', style: TextStyle(color: heading)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: AppSpacing.lg),
                  _row('Subtotal', order.subtotal, muted, heading),
                  if (order.discountAmount > 0) _row('Discount', -order.discountAmount, muted, heading),
                  _row('Total', order.total, heading, heading, bold: true),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shipping Address', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.sm),
                  Text(orderDetail.shippingAddress.fullName, style: TextStyle(color: heading)),
                  Text(
                    '${orderDetail.shippingAddress.line1}, ${orderDetail.shippingAddress.city}, ${orderDetail.shippingAddress.country}',
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              child: Row(
                children: [
                  Icon(Icons.local_shipping_outlined, color: heading),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Payment: Cash on Delivery. Order status: ${order.status.name}.',
                      style: TextStyle(color: heading),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            PillButton(
              label: 'Back to Home',
              expand: true,
              onPressed: () => context.go(AppRoutes.home),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, Color labelColor, Color valueColor, {bool bold = false}) {
    final style = TextStyle(color: labelColor, fontWeight: bold ? FontWeight.w700 : FontWeight.w500);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('${value < 0 ? '-' : ''}\$${value.abs().toStringAsFixed(2)}', style: style.copyWith(color: valueColor)),
        ],
      ),
    );
  }
}
