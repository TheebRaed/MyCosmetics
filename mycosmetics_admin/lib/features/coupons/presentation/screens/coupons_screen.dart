import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../../../dashboard/data/models/admin_models.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';
import '../providers/coupons_providers.dart';

class CouponsScreen extends ConsumerWidget {
  const CouponsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCouponsProvider);
    final fmt = NumberFormat.currency(symbol: '\$');
    return Padding(
      padding: AdminSpacing.pagePadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AdminPageHeader(
          title: 'Promotions',
          subtitle: 'Coupons and discount campaigns',
          actions: [ElevatedButton.icon(onPressed: () => _create(context, ref), icon: const Icon(Icons.add, size: 18), label: const Text('Create Coupon'))],
        ),
        Expanded(child: async.when(
          loading: () => const AdminLoading(),
          error: (e, _) => AdminError(message: e.toString(), onRetry: () => ref.invalidate(adminCouponsProvider)),
          data: (list) => list.isEmpty
              ? const AdminEmpty(message: 'No coupons yet', icon: Icons.local_offer_outlined)
              : Card(child: SingleChildScrollView(child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Code')), DataColumn(label: Text('Type')),
                    DataColumn(label: Text('Value')), DataColumn(label: Text('Used')),
                    DataColumn(label: Text('Expires')), DataColumn(label: Text('Active')),
                  ],
                  rows: list.map((c) => DataRow(cells: [
                    DataCell(Text(c.code, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'monospace'))),
                    DataCell(Text(c.type == 'percentage' ? 'Percentage' : 'Fixed')),
                    DataCell(Text(c.type == 'percentage' ? '${c.value.toStringAsFixed(0)}%' : fmt.format(c.value))),
                    DataCell(Text('${c.usedCount}${c.usageLimit != null ? ' / ${c.usageLimit}' : ''}')),
                    DataCell(Text(c.expiresAt != null ? c.expiresAt!.substring(0, 10) : 'Never')),
                    DataCell(Switch(
                      value: c.isActive, activeColor: AdminColors.primary,
                      onChanged: (v) async {
                        await ref.read(adminRepositoryProvider).setCouponActive(c.id, v);
                        ref.invalidate(adminCouponsProvider);
                      },
                    )),
                  ])).toList(),
                ))),
        )),
      ]),
    );
  }

  void _create(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String type = 'percentage';
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (_, ss) => AlertDialog(
      title: const Text('Create Coupon'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: codeCtrl, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Code (e.g. SAVE20)')),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(value: type, decoration: const InputDecoration(labelText: 'Type'),
          items: const [DropdownMenuItem(value: 'percentage', child: Text('Percentage %')), DropdownMenuItem(value: 'fixedAmount', child: Text('Fixed Amount \$'))],
          onChanged: (v) => ss(() => type = v!)),
        const SizedBox(height: 12),
        TextField(controller: valueCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Value')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () async {
            final val = double.tryParse(valueCtrl.text);
            if (codeCtrl.text.trim().isEmpty || val == null) return;
            Navigator.pop(ctx);
            await ref.read(adminRepositoryProvider).createCoupon(code: codeCtrl.text.trim().toUpperCase(), type: type, value: val);
            ref.invalidate(adminCouponsProvider);
          },
          child: const Text('Create'),
        ),
      ],
    ))).whenComplete(() { codeCtrl.dispose(); valueCtrl.dispose(); });
  }
}
