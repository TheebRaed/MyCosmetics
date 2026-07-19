import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/admin_repository.dart';
import '../../../../core/network/admin_api_client.dart';
part 'auth_provider.g.dart';

class AdminAuthState {
  const AdminAuthState({required this.isAuthenticated, this.fullName, this.role});
  final bool isAuthenticated; final String? fullName, role;
  static const unauth = AdminAuthState(isAuthenticated: false);
}

const _adminRoles = {'admin','staff','inventoryManager','customerSupport','marketingManager'};

@riverpod
class AdminAuth extends _$AdminAuth {
  @override
  Future<AdminAuthState> build() async {
    final token = await ref.watch(adminApiClientProvider).savedToken;
    if (token == null || token.isEmpty) return AdminAuthState.unauth;
    return const AdminAuthState(isAuthenticated: true);
  }

  Future<String?> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(adminRepositoryProvider).login(email, password);
      final user = result['user'] as Map<String,dynamic>;
      final role = user['role'] as String;
      if (!_adminRoles.contains(role)) { state = const AsyncData(AdminAuthState.unauth); return 'This account does not have admin access.'; }
      await ref.read(adminApiClientProvider).saveToken(result['token'] as String);
      state = AsyncData(AdminAuthState(isAuthenticated: true, fullName: user['fullName'] as String?, role: role));
      return null;
    } catch (e) {
      state = const AsyncData(AdminAuthState.unauth);
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<void> logout() async {
    await ref.read(adminApiClientProvider).clearToken();
    state = const AsyncData(AdminAuthState.unauth);
  }
}
