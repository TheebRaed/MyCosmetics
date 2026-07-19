import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/integrations/session_service.dart';
import 'package:mycosmetics_server/src/repositories/user_repository.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized.']);
  @override String toString() => message;
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException([this.message = 'Forbidden.']);
  @override String toString() => message;
}

const Map<UserRole, Set<String>> _rolePermissions = {
  UserRole.customer: {},
  UserRole.customerSupport: {'orders:read','orders:update','customers:read','customers:support','audit:read'},
  UserRole.inventoryManager: {'products:read','products:write','inventory:read','inventory:write','brands:write','categories:write','audit:read'},
  UserRole.marketingManager: {'products:read','coupons:read','coupons:write','notifications:write','reports:read','analytics:read','audit:read'},
  UserRole.staff: {'products:read','products:write','orders:read','orders:update','customers:read','inventory:read','inventory:write','coupons:read','coupons:write','analytics:read','audit:read'},
  UserRole.admin: {'products:read','products:write','products:delete','orders:read','orders:update','orders:cancel','customers:read','customers:write','customers:support','inventory:read','inventory:write','coupons:read','coupons:write','coupons:delete','notifications:write','reports:read','reports:export','analytics:read','audit:read','brands:write','categories:write','payments:read','refunds:write'},
};

String? _extractToken(Session session) {
  try {
    final h = session.httpRequest.headers['authorization']?.first ?? session.httpRequest.headers['Authorization']?.first;
    if (h == null || !h.startsWith('Bearer ')) return null;
    final t = h.substring(7).trim();
    return t.isEmpty ? null : t;
  } catch (_) { return null; }
}

class AuthGuard {
  static final UserRepository _users = UserRepository();

  static Future<int> requireUserId(Session session) async {
    final token = _extractToken(session);
    if (token == null) throw UnauthorizedException();
    final userId = await SessionService.resolveUserId(session, token);
    if (userId == null) throw UnauthorizedException();
    return userId;
  }

  static Future<User> requireUser(Session session) async {
    final userId = await requireUserId(session);
    final user = await _users.findById(session, userId);
    if (user == null) throw UnauthorizedException();
    return user;
  }

  static Future<User> requireAdmin(Session session) async {
    final user = await requireUser(session);
    if (user.role != UserRole.admin) throw ForbiddenException();
    return user;
  }

  static Future<User> requireAdminOrStaff(Session session) async {
    final user = await requireUser(session);
    if (user.role != UserRole.admin && user.role != UserRole.staff) throw ForbiddenException();
    return user;
  }

  static Future<User> requirePermission(Session session, String permission) async {
    final user = await requireUser(session);
    final perms = _rolePermissions[user.role] ?? {};
    if (!perms.contains(permission)) throw ForbiddenException('Role ${user.role.name} lacks: $permission');
    return user;
  }

  static String? rawToken(Session session) => _extractToken(session);
}
