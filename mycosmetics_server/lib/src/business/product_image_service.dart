import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/integrations/session_service.dart';
import 'package:mycosmetics_server/src/repositories/user_repository.dart';

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException([this.message = 'Unauthorized: invalid or expired session.']);
  @override
  String toString() => message;
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException([this.message = 'Forbidden: insufficient permissions.']);
  @override
  String toString() => message;
}

/// Single shared place for "who is calling, and are they allowed to do
/// this" checks, used by every endpoint that needs auth \u2014 avoids each
/// endpoint re-implementing (and potentially getting wrong) the same
/// token -> user -> role resolution.
class AuthGuard {
  static final UserRepository _users = UserRepository();

  static Future<User> requireUser(Session session, String token) async {
    final userId = await SessionService.resolveUserId(session, token);
    if (userId == null) throw UnauthorizedException();
    final user = await _users.findById(session, userId);
    if (user == null) throw UnauthorizedException();
    return user;
  }

  static Future<User> requireAdmin(Session session, String token) async {
    final user = await requireUser(session, token);
    if (user.role != UserRole.admin) {
      throw ForbiddenException();
    }
    return user;
  }

  /// Admin or staff (used for catalog management, where staff may also
  /// be permitted to edit products but not e.g. manage user roles).
  static Future<User> requireAdminOrStaff(Session session, String token) async {
    final user = await requireUser(session, token);
    if (user.role != UserRole.admin && user.role != UserRole.staff) {
      throw ForbiddenException();
    }
    return user;
  }
}
