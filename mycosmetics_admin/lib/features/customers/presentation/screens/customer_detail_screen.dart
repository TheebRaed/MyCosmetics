import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';
import '../providers/customers_providers.dart';

class CustomerDetailScreen extends ConsumerWidget {
  const CustomerDetailScreen({super.key, required this.userId});
  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(customerDetailProvider(userId));
    final fmt   = NumberFormat.currency(symbol: '\$');
    return Padding(padding: AdminSpacing.pagePadding, child: async.when(
      loading: () => const AdminLoading(),
      error: (e, _) => AdminError(message: e.toString(), onRetry: () => ref.invalidate(customerDetailProvider(userId))),
      data: (d) {
        if (d.isEmpty) return const AdminEmpty(message: 'Customer not found');
        final isActive = d['suspendedAt'] == null;
        return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            const SizedBox(width: 8),
            Text(d['fullName'] as String? ?? '', style: AdminTextStyles.headline),
            const SizedBox(width: 12),
            AdminStatusBadge(label: isActive ? 'Active' : 'Suspended', color: isActive ? AdminColors.success : AdminColors.error),
            const Spacer(),
            if (isActive)
              OutlinedButton.icon(
                onPressed: () => _suspendDialog(context, ref),
                icon: const Icon(Icons.block, size: 16, color: AdminColors.error),
                label: const Text('Suspend', style: TextStyle(color: AdminColors.error)),
              )
            else
              ElevatedButton.icon(
                onPressed: () async { await ref.read(adminRepositoryProvider).reactivateUser(userId); ref.invalidate(customerDetailProvider(userId)); },
                icon: const Icon(Icons.check_circle_outline, size: 16),
                label: const Text('Reactivate'),
              ),
          ]),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: _infoCard('Email',        d['email']       as String? ?? '—')),
            const SizedBox(width: 12),
            Expanded(child: _infoCard('Phone',        d['phone']       as String? ?? '—')),
            const SizedBox(width: 12),
            Expanded(child: _infoCard('Orders',       '${d['orderCount'] ?? 0}')),
            const SizedBox(width: 12),
            Expanded(child: _infoCard('Total Spent',  fmt.format((d['totalSpent'] as num? ?? 0).toDouble()))),
          ]),
          const SizedBox(height: 24),
          Card(child: Padding(padding: AdminSpacing.cardPadding, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Account Details', style: AdminTextStyles.title.copyWith(fontSize: 15)),
            const SizedBox(height: 12),
            _row('Role',    d['role']      as String? ?? 'customer'),
            _row('Joined',  (d['createdAt'] as String? ?? '').length >= 10 ? d['createdAt'].toString().substring(0,10) : '—'),
            _row('Avg Order', fmt.format((d['avgOrderValue'] as num? ?? 0).toDouble())),
            if (d['suspendedReason'] != null) _row('Suspension Reason', d['suspendedReason'] as String),
          ]))),
        ]));
      },
    ));
  }

  Widget _infoCard(String label, String value) => Card(child: Padding(padding: AdminSpacing.cardPadding, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label.toUpperCase(), style: AdminTextStyles.kpiLabel), const SizedBox(height: 6), Text(value, style: AdminTextStyles.title.copyWith(fontSize: 16))])));
  Widget _row(String l, String v) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [SizedBox(width: 160, child: Text(l, style: AdminTextStyles.subtitle)), Text(v)]));

  void _suspendDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Suspend Customer'),
      content: TextField(controller: ctrl, decoration: const InputDecoration(labelText: 'Reason'), maxLines: 3),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error), onPressed: () async {
          Navigator.pop(context);
          await ref.read(adminRepositoryProvider).suspendUser(userId, ctrl.text.trim().isEmpty ? 'Policy violation' : ctrl.text.trim());
          ref.invalidate(customerDetailProvider(userId));
        }, child: const Text('Suspend')),
      ],
    )).whenComplete(() => ctrl.dispose());
  }
}
