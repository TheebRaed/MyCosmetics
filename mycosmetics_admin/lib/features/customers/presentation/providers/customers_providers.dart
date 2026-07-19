import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../dashboard/data/models/admin_models.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';
part 'customers_providers.g.dart';

@riverpod class CustomersSearchNotifier extends _$CustomersSearchNotifier { @override String build() => ''; void set(String v) => state = v; }
@riverpod class CustomersPageNotifier extends _$CustomersPageNotifier   { @override int    build() => 0;  void set(int p)    => state = p; }

@riverpod Future<PaginatedData<AdminCustomerRow>> adminCustomersList(Ref ref) async {
  final s = ref.watch(customersSearchNotifierProvider);
  final p = ref.watch(customersPageNotifierProvider);
  final result = await ref.watch(adminRepositoryProvider).listCustomers(page: p, search: s.isEmpty ? null : s);
  final rows = (result['rows'] as List).map((r) => AdminCustomerRow.fromJson(r as Map<String,dynamic>)).toList();
  return PaginatedData(items: rows, totalCount: result['totalCount'] as int, page: p, pageSize: 20);
}

@riverpod Future<Map<String,dynamic>> customerDetail(Ref ref, int userId) =>
    ref.watch(adminRepositoryProvider).getCustomerDetail(userId);
