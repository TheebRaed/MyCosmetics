import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../../../dashboard/data/models/admin_models.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';
import '../providers/inventory_providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminInventoryListProvider);
    final f = ref.watch(inventoryFilterNotifierProvider);
    return Padding(
      padding: AdminSpacing.pagePadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AdminPageHeader(title: 'Inventory', subtitle: 'Stock levels and adjustments',
          actions: [AdminSearchField(hint: 'Search SKU or product...', onChanged: (v) => ref.read(inventoryFilterNotifierProvider.notifier).setSearch(v))]),
        Row(children: [
          FilterChip(label: const Text('All'), selected: f.lowStock == null && f.outOfStock == null, onSelected: (_) => ref.read(inventoryFilterNotifierProvider.notifier).setAll()),
          const SizedBox(width: 8),
          FilterChip(label: const Text('⚠ Low Stock'), selected: f.lowStock == true, selectedColor: AdminColors.warning, onSelected: (_) => ref.read(inventoryFilterNotifierProvider.notifier).setLowStock()),
          const SizedBox(width: 8),
          FilterChip(label: const Text('✗ Out of Stock'), selected: f.outOfStock == true, selectedColor: AdminColors.error, onSelected: (_) => ref.read(inventoryFilterNotifierProvider.notifier).setOutOfStock()),
        ]),
        const SizedBox(height: 16),
        Expanded(child: async.when(
          loading: () => const AdminLoading(),
          error: (e, _) => AdminError(message: e.toString(), onRetry: () => ref.invalidate(adminInventoryListProvider)),
          data: (data) => data.items.isEmpty
              ? const AdminEmpty(message: 'No inventory items found', icon: Icons.warehouse_outlined)
              : Card(child: Column(children: [
                  Expanded(child: SingleChildScrollView(child: DataTable(
                    columns: const [DataColumn(label: Text('Product')), DataColumn(label: Text('SKU')), DataColumn(label: Text('Stock'), numeric: true), DataColumn(label: Text('Status')), DataColumn(label: Text(''))],
                    rows: data.items.map((i) {
                      final status = i.isOutOfStock ? 'Out of Stock' : i.isLowStock ? 'Low Stock' : 'In Stock';
                      final color  = i.isOutOfStock ? AdminColors.error : i.isLowStock ? AdminColors.warning : AdminColors.success;
                      return DataRow(cells: [
                        DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(i.productName), if (i.shadeName != null) Text(i.shadeName!, style: AdminTextStyles.caption)])),
                        DataCell(Text(i.sku)),
                        DataCell(Text('${i.stockQty}', style: TextStyle(fontWeight: FontWeight.w700, color: i.isOutOfStock ? AdminColors.error : null))),
                        DataCell(AdminStatusBadge(label: status, color: color)),
                        DataCell(IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () => _adjust(context, ref, i))),
                      ]);
                    }).toList(),
                  ))),
                  Padding(padding: const EdgeInsets.all(12), child: AdminPaginationBar(page: data.page, totalPages: data.totalPages, onPageChanged: (p) => ref.read(inventoryFilterNotifierProvider.notifier).setPage(p))),
                ])),
        )),
      ]),
    );
  }

  void _adjust(BuildContext context, WidgetRef ref, InventoryRow i) {
    final qtyCtrl    = TextEditingController(text: '${i.stockQty}');
    final reasonCtrl = TextEditingController();
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text('Adjust Stock — ${i.productName}${i.shadeName != null ? ' (${i.shadeName})' : ''}'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: qtyCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'New Quantity')),
        const SizedBox(height: 12),
        TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Reason for adjustment'), maxLines: 2),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: () async {
          final qty = int.tryParse(qtyCtrl.text);
          if (qty == null || qty < 0) return;
          Navigator.pop(context);
          await ref.read(adminRepositoryProvider).adjustStock(i.variantId, qty, reasonCtrl.text.trim().isEmpty ? 'Manual adjustment' : reasonCtrl.text.trim());
          ref.invalidate(adminInventoryListProvider);
        }, child: const Text('Save')),
      ],
    )).whenComplete(() { qtyCtrl.dispose(); reasonCtrl.dispose(); });
  }
}
