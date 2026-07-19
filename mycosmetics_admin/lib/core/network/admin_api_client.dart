import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'admin_api_client.g.dart';

const _baseUrl = 'http://localhost:8080/';
const _tokenKey = 'admin_auth_token';

@riverpod FlutterSecureStorage secureStorage(Ref ref) => const FlutterSecureStorage();

@riverpod
Dio dio(Ref ref) {
  final storage = ref.watch(secureStorageProvider);
  final dio = Dio(BaseOptions(baseUrl: _baseUrl, connectTimeout: const Duration(seconds: 15), receiveTimeout: const Duration(seconds: 30), headers: {'Content-Type': 'application/json'}));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (o, h) async { final t = await storage.read(key: _tokenKey); if (t != null) o.headers['Authorization'] = 'Bearer $t'; h.next(o); },
    onError: (e, h) {
      final msg = switch (e.response?.statusCode) { 401 => 'Session expired.', 403 => 'Permission denied.', _ => (e.response?.data is Map ? e.response!.data['message'] as String? : null) ?? 'Network error.' };
      h.reject(DioException(requestOptions: e.requestOptions, error: msg, type: e.type, response: e.response));
    },
  ));
  return dio;
}

class AdminApiClient {
  AdminApiClient(this._dio, this._storage);
  final Dio _dio; final FlutterSecureStorage _storage;
  Future<String?> get savedToken => _storage.read(key: _tokenKey);
  Future<void> saveToken(String t) => _storage.write(key: _tokenKey, value: t);
  Future<void> clearToken()        => _storage.delete(key: _tokenKey);

  Future<T> post<T>({required String endpoint, required String method, Map<String,dynamic>? body, required T Function(dynamic) fromJson}) async {
    try { final r = await _dio.post('$endpoint/$method', data: body); if (r.data is Map && (r.data as Map).containsKey('error')) throw Exception((r.data as Map)['message'] ?? 'Error'); return fromJson(r.data); }
    on DioException catch (e) { throw Exception(e.error ?? 'Request failed'); }
  }

  Future<List<T>> postList<T>({required String endpoint, required String method, Map<String,dynamic>? body, required T Function(Map<String,dynamic>) fromJson}) async {
    try { final r = await _dio.post('$endpoint/$method', data: body); if (r.data is! List) throw Exception('Unexpected response'); return (r.data as List).map((e) => fromJson(e as Map<String,dynamic>)).toList(); }
    on DioException catch (e) { throw Exception(e.error ?? 'Request failed'); }
  }
}

@riverpod AdminApiClient adminApiClient(Ref ref) => AdminApiClient(ref.watch(dioProvider), ref.watch(secureStorageProvider));
