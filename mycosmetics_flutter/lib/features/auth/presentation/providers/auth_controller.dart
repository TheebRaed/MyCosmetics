import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/auth_repository.dart';

part 'auth_controller.g.dart';

/// Whole-app auth state.
///
/// [user] is null in two cases: definitely signed out, or "a token is
/// stored but we haven't confirmed identity with the server yet" (there's
/// no `whoAmI`/`me` endpoint on AuthEndpoint today -- see
/// mycosmetics_server/lib/src/endpoints/auth_endpoint.dart -- so splash can
/// only check "is a token present", not validate it). [hasSession]
/// distinguishes those two cases for the splash/router redirect; a stale or
/// revoked token still routes into the shell and the first 401 from any
/// authenticated call should bounce the user back to login.
class AuthState {
  const AuthState({required this.hasSession, this.user});

  final bool hasSession;
  final AuthUser? user;

  static const signedOut = AuthState(hasSession: false);

  AuthState copyWith({AuthUser? user}) => AuthState(hasSession: true, user: user ?? this.user);
}

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<AuthState> build() async {
    final repo = ref.watch(authRepositoryProvider);
    final hasSession = await repo.hasStoredSession();
    return hasSession ? const AuthState(hasSession: true) : AuthState.signedOut;
  }

  Future<String?> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).login(email: email, password: password);
      state = AsyncData(AuthState(hasSession: true, user: user));
      return null;
    } catch (e) {
      state = const AsyncData(AuthState.signedOut);
      return friendlyAuthErrorMessage(e);
    }
  }

  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            fullName: fullName,
          );
      state = AsyncData(AuthState(hasSession: true, user: user));
      return null;
    } catch (e) {
      state = const AsyncData(AuthState.signedOut);
      return friendlyAuthErrorMessage(e);
    }
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthState.signedOut);
  }
}

/// Strips Serverpod's exception-class prefix and falls back to a generic
/// message. See auth_repository.dart's note -- most backend `AuthException`s
/// currently arrive as an opaque "Internal server error" until the backend
/// registers `AuthException` as a proper Serverpod protocol exception, so
/// this can't reliably show e.g. "Invalid email or password" yet.
String friendlyAuthErrorMessage(Object e) {
  final raw = e.toString();
  if (raw.contains('Internal server error')) {
    return 'Something went wrong. Please try again.';
  }
  final match = RegExp(r'^ServerpodClientException:\s*(.*?),\s*statusCode').firstMatch(raw);
  return match?.group(1) ?? 'Something went wrong. Please try again.';
}
