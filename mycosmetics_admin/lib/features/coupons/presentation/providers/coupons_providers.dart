import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../dashboard/data/models/admin_models.dart';
import '../../../dashboard/data/repositories/admin_repository.dart';
part 'coupons_providers.g.dart';

@riverpod
Future<List<AdminCoupon>> adminCoupons(Ref ref) async {
  final rows = await ref.watch(adminRepositoryProvider).listCoupons();
  return rows.map((r) => AdminCoupon.fromJson(r)).toList();
}
