import 'package:flutter/material.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_tokens.dart';
import 'order_status_badge.dart';

/// The forward-moving pipeline stages a "normal" order progresses through.
/// Matches `order_service.dart`'s `_allowedTransitions` happy path
/// (pending -> processing -> shipped -> delivered). Cancelled/Returned are
/// terminal side-branches, not steps on this line -- rendered separately.
const _pipeline = [OrderStatus.pending, OrderStatus.processing, OrderStatus.shipped, OrderStatus.delivered];

/// Real order tracking timeline driven by [OrderDetail.statusHistory] and
/// the order's current [OrderStatus] -- not a plain list. Uses tasteful,
/// simple motion consistent with docs/DESIGN_SYSTEM.md's soft/luxury motion
/// language: each reached step fades/slides in on first build (staggered,
/// like `floatSoft`), and the current/active step gets a soft pulsing ring
/// (`pulseRing`) rather than a static dot.
class OrderStatusStepper extends StatefulWidget {
  const OrderStatusStepper({super.key, required this.order, required this.statusHistory});

  final Order order;
  final List<OrderStatusHistory> statusHistory;

  @override
  State<OrderStatusStepper> createState() => _OrderStatusStepperState();
}

class _OrderStatusStepperState extends State<OrderStatusStepper> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();
    _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  DateTime? _reachedAt(OrderStatus status) {
    for (final h in widget.statusHistory) {
      if (h.status == status) return h.createdAt;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final accentGold = isDark ? AppColorsDark.accentGold : AppColorsLight.accentGold;
    final chipText = isDark ? AppColorsDark.chipText : AppColorsLight.chipText;

    final isTerminalNegative = widget.order.status == OrderStatus.cancelled || widget.order.status == OrderStatus.returned;

    if (isTerminalNegative) {
      // Cancelled/Returned don't map onto the forward pipeline -- show the
      // real history entries as a simple timeline instead of forcing them
      // onto steps that were never reached.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < widget.statusHistory.length; i++)
            _HistoryRow(
              entry: widget.statusHistory[i],
              isLast: i == widget.statusHistory.length - 1,
              entrance: _entrance,
              index: i,
              color: i == widget.statusHistory.length - 1 ? chipText : muted,
            ),
        ],
      );
    }

    final currentIndex = _pipeline.indexOf(widget.order.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < _pipeline.length; i++)
          _PipelineStep(
            status: _pipeline[i],
            reachedAt: _reachedAt(_pipeline[i]),
            isReached: i <= currentIndex,
            isActive: i == currentIndex,
            isLast: i == _pipeline.length - 1,
            entrance: _entrance,
            pulse: _pulse,
            index: i,
            accentGold: accentGold,
            heading: heading,
            muted: muted,
          ),
      ],
    );
  }
}

class _PipelineStep extends StatelessWidget {
  const _PipelineStep({
    required this.status,
    required this.reachedAt,
    required this.isReached,
    required this.isActive,
    required this.isLast,
    required this.entrance,
    required this.pulse,
    required this.index,
    required this.accentGold,
    required this.heading,
    required this.muted,
  });

  final OrderStatus status;
  final DateTime? reachedAt;
  final bool isReached;
  final bool isActive;
  final bool isLast;
  final AnimationController entrance;
  final AnimationController pulse;
  final int index;
  final Color accentGold;
  final Color heading;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final delay = index * 0.12;
    final curved = CurvedAnimation(
      parent: entrance,
      curve: Interval(delay.clamp(0.0, 1.0), (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: Listenable.merge([curved, pulse]),
      builder: (context, child) {
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 12),
            child: child,
          ),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                _Dot(reached: isReached, active: isActive, pulse: pulse, accentGold: accentGold, muted: muted),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: isReached ? accentGold.withValues(alpha: 0.5) : muted.withValues(alpha: 0.2),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusLabel(status),
                      style: TextStyle(
                        color: isReached ? heading : muted,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    if (reachedAt != null)
                      Text(_formatDate(reachedAt!), style: TextStyle(color: muted, fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.reached, required this.active, required this.pulse, required this.accentGold, required this.muted});

  final bool reached;
  final bool active;
  final AnimationController pulse;
  final Color accentGold;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    const size = 18.0;
    if (!active) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: reached ? accentGold : Colors.transparent,
          border: Border.all(color: reached ? accentGold : muted.withValues(alpha: 0.4), width: 2),
        ),
        child: reached ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
      );
    }

    // Active step: soft pulsing ring (docs/DESIGN_SYSTEM.md `pulseRing`
    // motif) instead of a static dot -- this is the "beautiful order
    // tracking animation" the product brief called out.
    return SizedBox(
      width: size + 12,
      height: size + 12,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size + (pulse.value * 12),
            height: size + (pulse.value * 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentGold.withValues(alpha: (1 - pulse.value) * 0.35),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accentGold),
            child: const Icon(Icons.circle, size: 8, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.isLast, required this.entrance, required this.index, required this.color});

  final OrderStatusHistory entry;
  final bool isLast;
  final AnimationController entrance;
  final int index;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final heading = isDark ? AppColorsDark.textHeading : AppColorsLight.textHeading;
    final muted = isDark ? AppColorsDark.textMuted : AppColorsLight.textMuted;
    final delay = index * 0.12;
    final curved = CurvedAnimation(
      parent: entrance,
      curve: Interval(delay.clamp(0.0, 1.0), (delay + 0.4).clamp(0.0, 1.0), curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(offset: Offset(0, (1 - curved.value) * 12), child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.circle, size: 10, color: color),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(statusLabel(entry.status), style: TextStyle(color: heading, fontWeight: FontWeight.w700)),
                  if (entry.note != null) Text(entry.note!, style: TextStyle(color: muted, fontSize: 12)),
                  Text(_formatDate(entry.createdAt), style: TextStyle(color: muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(DateTime dt) {
  final local = dt.toLocal();
  final month = _months[local.month - 1];
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month ${local.day}, ${local.year} · $hour:$minute';
}

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
