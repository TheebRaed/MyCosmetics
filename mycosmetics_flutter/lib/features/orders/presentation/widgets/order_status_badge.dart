import 'package:flutter/material.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';

/// Small pill badge for an [OrderStatus] -- used in the order list rows and
/// the order detail header. Cancelled/Returned get a muted treatment,
/// everything else uses the chip rose/gold palette.
class OrderStatusBadge extends StatelessWidget {
  const OrderStatusBadge({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? AppColorsDark.chipBg : AppColorsLight.chipBg;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;

    final isTerminalNegative = status == OrderStatus.cancelled || status == OrderStatus.returned;
    final bg = isTerminalNegative ? muted.withValues(alpha: 0.14) : chipBg;
    final fg = isTerminalNegative ? muted : chipText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Text(
        statusLabel(status),
        style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}

String statusLabel(OrderStatus status) => switch (status) {
      OrderStatus.pending => 'Pending',
      OrderStatus.processing => 'Processing',
      OrderStatus.shipped => 'Shipped',
      OrderStatus.delivered => 'Delivered',
      OrderStatus.cancelled => 'Cancelled',
      OrderStatus.returned => 'Returned',
    };
