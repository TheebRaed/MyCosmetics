import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/order_status_stepper.dart';
import '../widgets/write_review_sheet.dart';

/// Order detail, reached from the order list -- `/profile/orders/:id`.
/// Real via `OrderEndpoint.getDetails` (see orders_repository.dart):
/// items, shipping address, and the real tracking timeline
/// (`OrderStatusStepper`, driven by `OrderDetail.statusHistory`).
///
/// Cancel is only offered while `order.status` is in [cancellableStatuses]
/// (pending/processing) -- matches the real state machine in
/// order_service.dart, the server re-validates the same transition anyway.
///
/// "Write a review" is offered per delivered item using its real
/// `orderItemId` -- eligibility (delivered + not already reviewed) is
/// enforced server-side by `ReviewService.add`; a rejection (e.g. "You have
/// already reviewed this purchase.") surfaces as a snackbar rather than
/// being pre-computed client-side (no bulk "already reviewed" endpoint
/// exists to check that up front).
class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  void _showMessage(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _cancelOrder(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep Order')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Cancel Order')),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await ref.read(orderDetailControllerProvider(orderId).notifier).cancel();
    if (!context.mounted) return;
    _showMessage(context, error ?? 'Order cancelled.');
  }

  Future<void> _writeReview(BuildContext context, WidgetRef ref, OrderItem item) async {
    final label = '${item.productNameSnapshot}${item.shadeNameSnapshot != null ? ' (${item.shadeNameSnapshot})' : ''}';
    final result = await showWriteReviewSheet(context, productLabel: label);
    if (result == null) return;
    final error = await ref.read(orderDetailControllerProvider(orderId).notifier).submitReview(
          orderItemId: item.id!,
          rating: result.rating,
          comment: result.comment,
        );
    if (!context.mounted) return;
    _showMessage(context, error ?? 'Review submitted. Thank you!');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    final asyncDetail = ref.watch(orderDetailControllerProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: asyncDetail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load this order", style: TextStyle(color: muted)),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.invalidate(orderDetailControllerProvider(orderId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (detail) {
          final order = detail.order;
          final canCancel = cancellableStatuses.contains(order.status);

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Order #${order.id}', style: TextStyle(color: heading, fontWeight: FontWeight.w700, fontSize: 16)),
                        OrderStatusBadge(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('Placed ${_formatDate(order.createdAt)}', style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Tracking', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: OrderStatusStepper(order: order, statusHistory: detail.statusHistory),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Items', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < detail.items.length; i++) ...[
                      if (i > 0) const Divider(height: AppSpacing.lg),
                      _ItemRow(
                        item: detail.items[i],
                        isDelivered: order.status == OrderStatus.delivered,
                        heading: heading,
                        muted: muted,
                        onWriteReview: () => _writeReview(context, ref, detail.items[i]),
                      ),
                    ],
                    const Divider(height: AppSpacing.lg),
                    _row('Subtotal', order.subtotal, muted, heading),
                    if (order.discountAmount > 0) _row('Discount', -order.discountAmount, muted, heading),
                    _row('Total', order.total, heading, heading, bold: true),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text('Shipping Address', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(detail.shippingAddress.fullName, style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                    Text(
                      '${detail.shippingAddress.line1}, ${detail.shippingAddress.city}, ${detail.shippingAddress.country}',
                      style: TextStyle(color: muted),
                    ),
                  ],
                ),
              ),
              if (canCancel) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: () => _cancelOrder(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red.shade700,
                    side: BorderSide(color: Colors.red.shade200),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill)),
                  ),
                  child: const Text('Cancel Order'),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
            ],
          );
        },
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

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.item,
    required this.isDelivered,
    required this.heading,
    required this.muted,
    required this.onWriteReview,
  });

  final OrderItem item;
  final bool isDelivered;
  final Color heading;
  final Color muted;
  final VoidCallback onWriteReview;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
        if (isDelivered) ...[
          const SizedBox(height: AppSpacing.xs),
          GestureDetector(
            onTap: onWriteReview,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_border_rounded, size: 16, color: chipText),
                const SizedBox(width: 4),
                Text('Write a review', style: TextStyle(color: chipText, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}
