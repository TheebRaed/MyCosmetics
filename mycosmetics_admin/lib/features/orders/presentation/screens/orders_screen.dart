import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../../../dashboard/data/models/admin_models.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';
import '../providers/orders_providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});
  static const _statuses = ['pending','processing','packed','shipped','delivered','cancelled'];
  static const _flow = {'pending':['processing','cancelled'],'processing':['packed','cancelled'],'packed':['shipped','cancelled'],'shipped':['delivered'],'delivered':[],'cancelled':[]};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async  = ref.watch(adminOrdersListProvider);
    final filter = ref.watch(ordersFilterNotifierProvider);
    final fmt    = NumberFormat.currency(symbol: '\$');

    return Padding(padding: AdminSpacing.pagePadding, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      AdminPageHeader(title: 'Orders', subtitle: 'Track and manage customer orders',
        actions: [AdminSearchField(hint: 'Search customer or order #', onChanged: (v) => ref.read(ordersFilterNotifierProvider.notifier).setSearch(v))]),
      SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, children: [
        _chip('All', filter.status == null, () => ref.read(ordersFilterNotifierProvider.notifier).setStatus(null)),
        ..._statuses.map((s) => Padding(padding: const EdgeInsets.only(left: 8), child: _chip(s[0].toUpperCase()+s.substring(1), filter.status == s, () => ref.read(ordersFilterNotifierProvider.notifier).setStatus(s)))),
      ])),
      const SizedBox(height: 16),
      Expanded(child: async.when(
        loading: () => const AdminLoading(),
        error: (e, _) => AdminError(message: e.toString(), onRetry: () => ref.invalidate(adminOrdersListProvider)),
        data: (data) => data.items.isEmpty ? const AdminEmpty(message: 'No orders found', icon: Icons.receipt_long_outlined)
            : Card(child: Column(children: [
                Expanded(child: SingleChildScrollView(child: DataTable(
                  columns: const [DataColumn(label: Text('Order #')), DataColumn(label: Text('Customer')), DataColumn(label: Text('Items'), numeric: true), DataColumn(label: Text('Total'), numeric: true), DataColumn(label: Text('Payment')), DataColumn(label: Text('Status')), DataColumn(label: Text('Date'))],
                  rows: data.items.map((o) => DataRow(cells: [
                    DataCell(Text('#${o.id}', style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(o.customerName), Text(o.customerEmail, style: AdminTextStyles.caption)])),
                    DataCell(Text('${o.itemCount}')),
                    DataCell(Text(fmt.format(o.total))),
                    DataCell(AdminStatusBadge(label: o.paymentStatus.toUpperCase(), color: statusColor(o.paymentStatus))),
                    DataCell(_dropdown(context, ref, o.id, o.status)),
                    DataCell(Text(o.createdAt.length >= 10 ? o.createdAt.substring(0,10) : o.createdAt)),
                  ])).toList(),
                ))),
                Padding(padding: const EdgeInsets.all(12), child: AdminPaginationBar(page: data.page, totalPages: data.totalPages, onPageChanged: (p) => ref.read(ordersFilterNotifierProvider.notifier).setPage(p))),
              ])),
      )),
    ]));
  }

  Widget _chip(String label, bool sel, VoidCallback onTap) => ChoiceChip(label: Text(label, style: TextStyle(fontSize: 12, color: sel ? Colors.white : AdminColors.textPrimary)), selected: sel, onSelected: (_) => onTap(), selectedColor: AdminColors.primary);

  Widget _dropdown(BuildContext ctx, WidgetRef ref, int orderId, String current) {
    final next = _flow[current] ?? [];
    if (next.isEmpty) return AdminStatusBadge(label: current.toUpperCase(), color: statusColor(current));
    return DropdownButton<String>(
      value: current, underline: const SizedBox.shrink(),
      items: [current, ...next].map((s) => DropdownMenuItem(value: s, child: AdminStatusBadge(label: s.toUpperCase(), color: statusColor(s)))).toList(),
      onChanged: (v) async {
        if (v == null || v == current) return;
        await ref.read(adminRepositoryProvider).updateOrderStatus(orderId, v);
        ref.invalidate(adminOrdersListProvider);
      },
    );
  }
}
