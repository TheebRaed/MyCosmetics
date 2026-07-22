import 'package:serverpod/serverpod.dart';
import 'package:mycosmetics_server/src/generated/protocol.dart' hide UserRepository;
import 'package:mycosmetics_server/src/repositories/user_repository.dart';
import 'package:mycosmetics_server/src/utils/session_service.dart';
import 'package:mycosmetics_server/src/utils/password_service.dart';
import 'package:mycosmetics_server/src/integrations/email_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

// AuthException is now a generated Serverpod protocol exception -- see
// lib/protocol/auth_exception.spy.yaml. Its specific messages (invalid
// credentials, account suspended, reset link expired, etc.) now propagate
// to the Flutter client's catch blocks instead of surfacing as a generic
// Internal Server Error.

class AuthService {
  final UserRepository _users = UserRepository();

  AuthUser _toAuthUser(User u) => AuthUser(
        id: u.id!,
        email: u.email,
        fullName: u.fullName,
        role: u.role,
        avatarUrl: u.avatarUrl,
      );

  Future<AuthResult> register(
    Session session, {
    required String email,
    required String password,
    required String fullName,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalizedEmail)) {
      throw AuthException(message: 'Invalid email address.');
    }
    final strengthError = PasswordService.validateStrength(password);
    if (strengthError != null) throw AuthException(message: strengthError);

    final existing = await _users.findByEmail(session, normalizedEmail);
    if (existing != null) {
      // Generic message: never reveal whether the email exists.
      throw AuthException(message: 'Unable to register with the provided details.');
    }

    final now = DateTime.now().toUtc();
    final user = await _users.create(
      session,
      User(
        email: normalizedEmail,
        passwordHash: PasswordService.hash(password),
        fullName: fullName.trim(),
        role: UserRole.customer,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final token = await SessionService.createSession(session, user.id!);
    return AuthResult(user: _toAuthUser(user), token: token);
  }

  Future<AuthResult> login(Session session, {required String email, required String password}) async {
    final normalizedEmail = email.trim().toLowerCase();

    if (!await SessionService.checkLoginAllowed(session, normalizedEmail)) {
      throw AuthException(message: 'Too many failed attempts. Try again later.');
    }

    final user = await _users.findByEmail(session, normalizedEmail);
    // Constant generic error to avoid leaking which part was wrong (email vs password).
    const invalidCredsMsg = 'Invalid email or password.';

    if (user == null || user.suspendedAt != null) {
      await SessionService.recordFailedLogin(session, normalizedEmail);
      throw AuthException(message: invalidCredsMsg);
    }
    if (!PasswordService.verify(password, user.passwordHash)) {
      await SessionService.recordFailedLogin(session, normalizedEmail);
      throw AuthException(message: invalidCredsMsg);
    }

    await SessionService.clearFailedLogins(session, normalizedEmail);
    final token = await SessionService.createSession(session, user.id!);
    return AuthResult(user: _toAuthUser(user), token: token);
  }

  Future<void> logout(Session session, String token) async {
    await SessionService.revokeSession(session, token);
  }

  Future<void> changePassword(
    Session session, {
    required int userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = await _users.findById(session, userId);
    if (user == null) throw AuthException(message: 'User not found.');
    if (!PasswordService.verify(currentPassword, user.passwordHash)) {
      throw AuthException(message: 'Current password is incorrect.');
    }
    final strengthError = PasswordService.validateStrength(newPassword);
    if (strengthError != null) throw AuthException(message: strengthError);

    await _users.update(
      session,
      user.copyWith(
        passwordHash: PasswordService.hash(newPassword),
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Generates a reset token, stores only its hash, and emails the RAW token
  /// to the user via [EmailService]. The raw token is never persisted and
  /// never returned to the caller -- delivery happens entirely server-side
  /// so the endpoint (and therefore the response body) never sees it.
  Future<void> requestPasswordReset(Session session, String email) async {
    final user = await _users.findByEmail(session, email.trim().toLowerCase());
    if (user == null) {
      // Don't reveal existence; caller still returns a generic success response.
      return;
    }
    final rawToken = const Uuid().v4();
    final tokenHash = sha256.convert(utf8.encode(rawToken)).toString();
    final now = DateTime.now().toUtc();

    await PasswordResetToken.db.insertRow(
      session,
      PasswordResetToken(
        userId: user.id!,
        tokenHash: tokenHash,
        expiresAt: now.add(const Duration(minutes: 30)),
        createdAt: now,
      ),
    );

    await EmailService.sendPasswordResetEmail(
      session,
      toEmail: user.email,
      resetToken: rawToken,
    );
  }

  Future<void> resetPassword(Session session, {required String rawToken, required String newPassword}) async {
    final tokenHash = sha256.convert(utf8.encode(rawToken)).toString();
    final record = await PasswordResetToken.db.findFirstRow(
      session,
      where: (t) => t.tokenHash.equals(tokenHash) & t.usedAt.equals(null),
    );
    if (record == null || record.expiresAt.isBefore(DateTime.now().toUtc())) {
      throw AuthException(message: 'Reset link is invalid or has expired.');
    }
    final strengthError = PasswordService.validateStrength(newPassword);
    if (strengthError != null) throw AuthException(message: strengthError);

    final user = await _users.findById(session, record.userId);
    if (user == null) throw AuthException(message: 'User not found.');

    await _users.update(
      session,
      user.copyWith(passwordHash: PasswordService.hash(newPassword), updatedAt: DateTime.now().toUtc()),
    );
    await PasswordResetToken.db.updateRow(
      session,
      record.copyWith(usedAt: DateTime.now().toUtc()),
    );
  }
}
