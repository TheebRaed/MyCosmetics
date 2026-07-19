import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/theme/admin_theme.dart';
import '../../../../shared/widgets/admin_widgets.dart';
import '../../../dashboard/data/models/admin_models.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';

part 'audit_log_screen.g.dart';

class _AuditFilter {
  const _AuditFilter({this.page = 0, this.entity, this.dateFrom});
  final int page; final String? entity, dateFrom;
}

@riverpod
class AuditFilterNotifier extends _$AuditFilterNotifier {
  @override _AuditFilter build() => const _AuditFilter();
  void setEntity(String? e) => state = _AuditFilter(page: 0, entity: e, dateFrom: state.dateFrom);
  void setPage(int p) => state = _AuditFilter(page: p, entity: state.entity, dateFrom: state.dateFrom);
}

@riverpod
Future<PaginatedData<AuditLogRow>> auditLogList(Ref ref) async {
  final f = ref.watch(auditFilterNotifierProvider);
  final result = await ref.watch(adminRepositoryProvider).listAuditLogs(page: f.page, entity: f.entity);
  final rows = (result['rows'] as List).map((r) => AuditLogRow.fromJson(r as Map<String, dynamic>)).toList();
  return PaginatedData(items: rows, totalCount: result['totalCount'] as int, page: f.page, pageSize: 50);
}

class AuditLogScreen extends ConsumerWidget {
  const AuditLogScreen({super.key});

  static const _entities = ['users', 'products', 'orders', 'product_variants', 'admin_notifications'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(auditLogListProvider);
    final f = ref.watch(auditFilterNotifierProvider);

    return Padding(
      padding: AdminSpacing.pagePadding,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AdminPageHeader(title: 'Audit Log', subtitle: 'Immutable record of all admin actions'),
        Row(children: [
          SizedBox(width: 200, child: DropdownButtonFormField<String?>(
            value: f.entity,
            decoration: const InputDecoration(hintText: 'Filter by entity', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
            items: [const DropdownMenuItem(value: null, child: Text('All Entities')), ..._entities.map((e) => DropdownMenuItem(value: e, child: Text(e)))],
            onChanged: (v) => ref.read(auditFilterNotifierProvider.notifier).setEntity(v),
          )),
          const SizedBox(width: 12),
          OutlinedButton.icon(onPressed: () => ref.invalidate(auditLogListProvider), icon: const Icon(Icons.refresh, size: 18), label: const Text('Refresh')),
        ]),
        const SizedBox(height: 16),
        Expanded(child: async.when(
          loading: () => const AdminLoading(),
          error: (e, _) => AdminError(message: e.toString(), onRetry: () => ref.invalidate(auditLogListProvider)),
          data: (data) => data.items.isEmpty
              ? const AdminEmpty(message: 'No audit logs yet', icon: Icons.history_outlined)
              : Card(child: Column(children: [
                  Expanded(child: SingleChildScrollView(child: DataTable(
                    columns: const [DataColumn(label: Text('Time')), DataColumn(label: Text('Admin')), DataColumn(label: Text('Action')), DataColumn(label: Text('Entity')), DataColumn(label: Text('ID')), DataColumn(label: Text('Detail'))],
                    rows: data.items.map((l) => DataRow(cells: [
                      DataCell(Text(l.createdAt.length >= 16 ? l.createdAt.substring(0, 16).replaceAll('T', ' ') : l.createdAt, style: AdminTextStyles.caption)),
                      DataCell(Text(l.adminName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(_ActionBadge(action: l.action)),
                      DataCell(Text(l.entity)),
                      DataCell(Text(l.entityId != null ? '#${l.entityId}' : '—')),
                      DataCell(ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(l.newValue ?? l.oldValue ?? '—', overflow: TextOverflow.ellipsis, style: AdminTextStyles.caption),
                      )),
                    ])).toList(),
                  ))),
                  Padding(padding: const EdgeInsets.all(12), child: AdminPaginationBar(page: data.page, totalPages: data.totalPages, onPageChanged: (p) => ref.read(auditFilterNotifierProvider.notifier).setPage(p))),
                ])),
        )),
      ]),
    );
  }
}

class _ActionBadge extends StatelessWidget {
  const _ActionBadge({required this.action});
  final String action;

  Color get _color => action.contains('delete') || action.contains('suspend') ? AdminColors.error
      : action.contains('create') || action.contains('insert') ? AdminColors.success
      : action.contains('update') || action.contains('adjust') ? AdminColors.info
      : AdminColors.textSec;

  @override
  Widget build(BuildContext context) => AdminStatusBadge(label: action.toUpperCase().replaceAll('_', ' '), color: _color);
}
