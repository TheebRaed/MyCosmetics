import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart';
import 'package:mycosmetics_server/src/business/auth_service.dart';
import 'package:mycosmetics_server/src/integrations/session_service.dart';

class AuthEndpoint extends Endpoint {
  final AuthService _auth = AuthService();

  Future<AuthResult> register(
    Session session, {
    required String email,
    required String password,
    required String fullName,
    String? phone,
  }) async {
    return _auth.register(session, email: email, password: password, fullName: fullName, phone: phone);
  }

  Future<AuthResult> login(Session session, {required String email, required String password}) async {
    return _auth.login(session, email: email, password: password);
  }

  /// Requires the caller to pass the session token they received at login.
  /// Token validity is checked by AuthGuard middleware logic (see endpoint base).
  Future<void> logout(Session session, {required String token}) async {
    await _auth.logout(session, token);
  }

  Future<void> changePassword(
    Session session, {
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    await _auth.changePassword(session, userId: userId, currentPassword: currentPassword, newPassword: newPassword);
  }

  /// Always returns void/success regardless of whether the email exists,
  /// to prevent account enumeration. Actual email dispatch is a TODO
  /// integration point (e.g. via a mail service) for a later phase.
  Future<void> forgotPassword(Session session, {required String email}) async {
    final rawToken = await _auth.requestPasswordReset(session, email);
    if (rawToken != null) {
      // TODO(Phase 4 or earlier): send rawToken via email/SMS provider.
      session.log('Password reset token generated for $email (delivery not yet wired).');
    }
  }

  Future<void> resetPassword(Session session, {required String token, required String newPassword}) async {
    await _auth.resetPassword(session, rawToken: token, newPassword: newPassword);
  }

  /// Helper for other endpoints/middleware to resolve a token to a userId.
  Future<int?> resolveSession(Session session, {required String token}) async {
    return SessionService.resolveUserId(session, token);
  }
}
