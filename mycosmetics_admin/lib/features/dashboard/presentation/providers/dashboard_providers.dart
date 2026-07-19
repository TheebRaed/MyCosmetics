import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/admin_models.dart';
import '../../data/repositories/admin_repository.dart';
part 'dashboard_providers.g.dart';

@riverpod Future<DashboardOverview> dashboardOverview(Ref ref) => ref.watch(adminRepositoryProvider).getOverview();
@riverpod Future<DashboardCharts>  dashboardCharts(Ref ref)   => ref.watch(adminRepositoryProvider).getCharts();
