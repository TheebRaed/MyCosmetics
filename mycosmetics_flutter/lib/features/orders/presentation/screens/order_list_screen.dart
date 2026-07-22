import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../shared/widgets/app_card.dart';
import '../providers/orders_providers.dart';
import '../widgets/order_status_badge.dart';

/// Order list, reached from Profile -- `/profile/orders`. Real via
/// `OrderEndpoint.listMyOrders` (see orders_repository.dart). Each row
/// shows status, date, item count, and total -- tapping opens the detail
/// screen for the real `OrderDetail`/tracking timeline.
class OrderListScreen extends ConsumerWidget {
  const OrderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    final asyncOrders = ref.watch(orderListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: asyncOrders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load your orders", style: TextStyle(color: muted)),
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: () => ref.read(orderListProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 48, color: muted),
                  const SizedBox(height: AppSpacing.sm),
                  Text('No orders yet', style: TextStyle(color: heading, fontWeight: FontWeight.w600)),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Your orders will show up here.', style: TextStyle(color: muted)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(orderListProvider.notifier).refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: orders.length,
              itemBuilder: (context, i) {
                final order = orders[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _OrderRow(
                    order: order,
                    heading: heading,
                    muted: muted,
                    onTap: () => context.push(AppRoutes.orderDetails(order.id!)),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.heading, required this.muted, required this.onTap});

  final Order order;
  final Color heading;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: muted.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(Icons.shopping_bag_outlined, color: muted),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Order #${order.id}', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(_formatDate(order.createdAt), style: TextStyle(color: muted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              OrderStatusBadge(status: order.status),
              const SizedBox(height: 4),
              Text('\$${order.total.toStringAsFixed(2)}', style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[local.month - 1]} ${local.day}, ${local.year}';
}
