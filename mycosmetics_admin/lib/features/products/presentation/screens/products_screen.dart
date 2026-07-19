import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../../../dashboard/data/models/admin_models.dart';
import '../providers/products_providers.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminProductsListProvider);
    final fmt   = NumberFormat.currency(symbol: '\$');
    return Padding(padding: AdminSpacing.pagePadding, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AdminPageHeader(title: 'Products', subtitle: 'Manage your product catalog', actions: [
        AdminSearchField(hint: 'Search products...', onChanged: (v) => ref.read(productsFilterNotifierProvider.notifier).setSearch(v)),
        const SizedBox(width: 12),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.upload_file, size: 18), label: const Text('Import')),
        const SizedBox(width: 8),
        OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.download, size: 18), label: const Text('Export')),
        const SizedBox(width: 8),
        ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.add, size: 18), label: const Text('Add Product')),
      ]),
      Expanded(child: async.when(
        loading: () => const AdminLoading(),
        error: (e, _) => AdminError(message: e.toString(), onRetry: () => ref.invalidate(adminProductsListProvider)),
        data: (data) => data.items.isEmpty ? const AdminEmpty(message: 'No products found', icon: Icons.inventory_2_outlined)
            : Card(child: Column(children: [
                Expanded(child: SingleChildScrollView(child: DataTable(
                  columns: const [DataColumn(label: Text('Product')), DataColumn(label: Text('Category')), DataColumn(label: Text('Brand')), DataColumn(label: Text('Price'), numeric: true), DataColumn(label: Text('Stock'), numeric: true), DataColumn(label: Text('Rating'), numeric: true), DataColumn(label: Text('Status')), DataColumn(label: Text(''))],
                  rows: data.items.map((p) => DataRow(cells: [
                    DataCell(Row(children: [if (p.isFeatured) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.star, size: 14, color: AdminColors.accent)), ConstrainedBox(constraints: const BoxConstraints(maxWidth: 200), child: Text(p.name, overflow: TextOverflow.ellipsis))])),
                    DataCell(Text(p.categoryName)),
                    DataCell(Text(p.brandName)),
                    DataCell(Text(fmt.format(p.basePrice))),
                    DataCell(Text('${p.totalStock}')),
                    DataCell(Row(children: [const Icon(Icons.star, size: 13, color: AdminColors.accent), const SizedBox(width: 2), Text(p.ratingAvg.toStringAsFixed(1))])),
                    DataCell(AdminStatusBadge(label: p.isActive ? 'Active' : 'Inactive', color: p.isActive ? AdminColors.success : AdminColors.textHint)),
                    DataCell(Row(children: [IconButton(icon: const Icon(Icons.edit_outlined, size: 18), onPressed: () {}), IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AdminColors.error), onPressed: () {})])),
                  ])).toList(),
                ))),
                Padding(padding: const EdgeInsets.all(12), child: AdminPaginationBar(page: data.page, totalPages: data.totalPages, onPageChanged: (p) => ref.read(productsFilterNotifierProvider.notifier).setPage(p))),
              ])),
      )),
    ]));
  }
}
