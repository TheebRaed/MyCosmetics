import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/session_manager.dart';

part 'auth_repository.g.dart';

/// Thin wrapper around `client.auth` (the generated Serverpod endpoint --
/// see mycosmetics_server/lib/src/endpoints/auth_endpoint.dart). Persists
/// the session token on successful login/register and clears it on logout.
///
/// Note on error messages: the backend's `AuthException` (see
/// mycosmetics_server/lib/src/business/auth_service.dart) is a plain Dart
/// exception, not a Serverpod protocol exception, so today it likely
/// surfaces to the client as a generic "Internal server error" rather than
/// the specific message (e.g. "Invalid email or password"). That's a
/// backend fix (making AuthException a `serverpod generate`-registered
/// exception type) -- flagged, not worked around here.
class AuthRepository {
  AuthRepository(this._client, this._session);

  final Client _client;
  final SessionManager _session;

  Future<AuthUser> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final result = await _client.auth.register(email: email, password: password, fullName: fullName);
    await _session.put(result.token);
    return result.user;
  }

  Future<AuthUser> login({required String email, required String password}) async {
    final result = await _client.auth.login(email: email, password: password);
    await _session.put(result.token);
    return result.user;
  }

  Future<void> logout() async {
    final token = await _session.get();
    if (token != null) {
      await _client.auth.logout(token: token);
    }
    await _session.remove();
  }

  Future<void> forgotPassword({required String email}) => _client.auth.forgotPassword(email: email);

  Future<void> resetPassword({required String token, required String newPassword}) =>
      _client.auth.resetPassword(token: token, newPassword: newPassword);

  Future<bool> hasStoredSession() => _session.hasToken();
}

@riverpod
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(apiClientProvider), ref.watch(sessionManagerProvider));
