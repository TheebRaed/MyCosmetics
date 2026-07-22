import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../providers/customers_providers.dart';

class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(adminCustomersListProvider);
    final fmt   = NumberFormat.currency(symbol: '\$');
    return Padding(padding: AdminSpacing.pagePadding, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AdminPageHeader(title: 'Customers', subtitle: 'Manage customer accounts',
        actions: [AdminSearchField(hint: 'Search name or email...', onChanged: (v) => ref.read(customersSearchNotifierProvider.notifier).set(v))]),
      Expanded(child: async.when(
        loading: () => const AdminLoading(),
        error: (e, _) => AdminError(message: e.toString(), onRetry: () => ref.invalidate(adminCustomersListProvider)),
        data: (data) => data.items.isEmpty ? const AdminEmpty(message: 'No customers found', icon: Icons.people_outline)
            : Card(child: Column(children: [
                Expanded(child: SingleChildScrollView(child: DataTable(
                  columns: const [DataColumn(label: Text('Customer')), DataColumn(label: Text('Phone')), DataColumn(label: Text('Orders'), numeric: true), DataColumn(label: Text('Total Spent'), numeric: true), DataColumn(label: Text('Status')), DataColumn(label: Text('Joined')), DataColumn(label: Text(''))],
                  rows: data.items.map((c) => DataRow(cells: [
                    DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.w600)), Text(c.email, style: AdminTextStyles.caption)])),
                    DataCell(Text(c.phone ?? '—')),
                    DataCell(Text('${c.orderCount}')),
                    DataCell(Text(fmt.format(c.totalSpent))),
                    DataCell(AdminStatusBadge(label: c.isActive ? 'Active' : 'Suspended', color: c.isActive ? AdminColors.success : AdminColors.error)),
                    DataCell(Text(c.createdAt.length >= 10 ? c.createdAt.substring(0,10) : c.createdAt)),
                    DataCell(IconButton(icon: const Icon(Icons.arrow_forward, size: 18), onPressed: () => context.push('/customers/${c.id}'))),
                  ])).toList(),
                ))),
                Padding(padding: const EdgeInsets.all(12), child: AdminPaginationBar(page: data.page, totalPages: data.totalPages, onPageChanged: (p) => ref.read(customersPageNotifierProvider.notifier).set(p))),
              ])),
      )),
    ]));
  }
}
