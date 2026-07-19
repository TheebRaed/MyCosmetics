import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme/admin_theme.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({super.key, required this.label, required this.value, required this.icon, this.color = AdminColors.primary, this.trend});
  final String label, value; final IconData icon; final Color color; final String? trend;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: AdminSpacing.cardPadding, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)), const Spacer(), if (trend != null) Text(trend!, style: const TextStyle(color: AdminColors.success, fontSize: 11, fontWeight: FontWeight.w700))]),
    const SizedBox(height: 12),
    Text(value, style: AdminTextStyles.kpiValue),
    const SizedBox(height: 2),
    Text(label.toUpperCase(), style: AdminTextStyles.kpiLabel),
  ])));
}

class KpiCardSkeleton extends StatelessWidget {
  const KpiCardSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: AdminSpacing.cardPadding, child: Shimmer.fromColors(baseColor: AdminColors.divider, highlightColor: AdminColors.white, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 36, height: 36, color: AdminColors.divider), const SizedBox(height: 16), Container(width: 80, height: 26, color: AdminColors.divider), const SizedBox(height: 6), Container(width: 100, height: 12, color: AdminColors.divider),
  ]))));
}

class AdminLoading extends StatelessWidget {
  const AdminLoading({super.key});
  @override Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class AdminError extends StatelessWidget {
  const AdminError({super.key, required this.message, this.onRetry});
  final String message; final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.error_outline, size: 48, color: AdminColors.error), const SizedBox(height: 12),
    Text(message, style: AdminTextStyles.body, textAlign: TextAlign.center),
    if (onRetry != null) ...[const SizedBox(height: 16), OutlinedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry'))],
  ]));
}

class AdminEmpty extends StatelessWidget {
  const AdminEmpty({super.key, required this.message, this.icon = Icons.inbox_outlined});
  final String message; final IconData icon;
  @override
  Widget build(BuildContext context) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 48, color: AdminColors.textHint), const SizedBox(height: 12), Text(message, style: AdminTextStyles.subtitle),
  ]));
}

class AdminStatusBadge extends StatelessWidget {
  const AdminStatusBadge({super.key, required this.label, required this.color});
  final String label; final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
  );
}

Color statusColor(String s) => switch (s.toLowerCase()) {
  'delivered'||'completed'||'paid'||'active'||'in stock' => AdminColors.success,
  'shipped'||'processing'                                  => AdminColors.info,
  'cancelled'||'refunded'||'suspended'||'failed'           => AdminColors.error,
  'pending'||'packed'||'unpaid'||'low stock'               => AdminColors.warning,
  _ => AdminColors.textSec,
};

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({super.key, required this.title, this.subtitle, this.actions});
  final String title; final String? subtitle; final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 20), child: Row(children: [
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: AdminTextStyles.headline),
      if (subtitle != null) Text(subtitle!, style: AdminTextStyles.subtitle),
    ])),
    if (actions != null) ...actions!,
  ]));
}

class AdminSearchField extends StatelessWidget {
  const AdminSearchField({super.key, this.onChanged, this.hint = 'Search...'});
  final ValueChanged<String>? onChanged; final String hint;
  @override
  Widget build(BuildContext context) => SizedBox(width: 280, child: TextField(onChanged: onChanged, decoration: InputDecoration(hintText: hint, prefixIcon: const Icon(Icons.search, size: 20), isDense: true)));
}

class AdminPaginationBar extends StatelessWidget {
  const AdminPaginationBar({super.key, required this.page, required this.totalPages, required this.onPageChanged});
  final int page, totalPages; final ValueChanged<int> onPageChanged;
  @override
  Widget build(BuildContext context) => Row(mainAxisAlignment: MainAxisAlignment.end, children: [
    Text('Page ${page+1} of ${totalPages == 0 ? 1 : totalPages}', style: AdminTextStyles.caption),
    const SizedBox(width: 12),
    IconButton(icon: const Icon(Icons.chevron_left), onPressed: page > 0 ? () => onPageChanged(page-1) : null),
    IconButton(icon: const Icon(Icons.chevron_right), onPressed: page+1 < totalPages ? () => onPageChanged(page+1) : null),
  ]);
}
