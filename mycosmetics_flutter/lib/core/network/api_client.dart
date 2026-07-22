import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mycosmetics_client/mycosmetics_client.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'session_manager.dart';

part 'api_client.g.dart';

/// Server host. Sourced from `--dart-define=API_BASE_URL=...` at build time
/// (never hardcoded in widget code per CLAUDE.md) with a localhost fallback
/// for local development against `serverpod run`.
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/',
);

/// The generated Serverpod client, wired with the secure-storage-backed
/// [SessionManager] so the bearer token is attached automatically. All
/// backend calls MUST go through this -- never a raw http/dio call against
/// a mycosmetics endpoint (CLAUDE.md golden rule #6).
@riverpod
Client apiClient(Ref ref) {
  final sessionManager = ref.watch(sessionManagerProvider);
  return Client(_apiBaseUrl, authenticationKeyManager: sessionManager);
}
