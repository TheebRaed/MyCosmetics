import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:serverpod_client/serverpod_client.dart';

part 'session_manager.g.dart';

const _tokenKey = 'mc_session_token';

/// [AuthenticationKeyManager] backed by [flutter_secure_storage], plugged
/// into the generated Serverpod [Client] so every call automatically
/// carries the bearer session token (see CLAUDE.md -- Redis bearer UUID
/// tokens, 7-day sliding expiry). Never read/write the raw token outside
/// this class.
class SessionManager extends AuthenticationKeyManager {
  SessionManager(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> get() => _storage.read(key: _tokenKey);

  @override
  Future<void> put(String key) => _storage.write(key: _tokenKey, value: key);

  @override
  Future<void> remove() => _storage.delete(key: _tokenKey);

  /// Convenience check used by the splash screen -- true if a token is
  /// currently stored. Doesn't validate server-side; an expired/revoked
  /// token still resolves true here and the first authenticated call will
  /// fail and should route back to login.
  Future<bool> hasToken() async {
    final token = await get();
    return token != null && token.isNotEmpty;
  }
}

@riverpod
FlutterSecureStorage secureStorage(Ref ref) => const FlutterSecureStorage();

@riverpod
SessionManager sessionManager(Ref ref) => SessionManager(ref.watch(secureStorageProvider));
