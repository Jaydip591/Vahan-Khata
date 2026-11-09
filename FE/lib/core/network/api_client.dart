import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';
import 'response_cache.dart';

const _retriedKey = 'retried_after_refresh';

/// Dio wrapper that adds the access token and, on 401, refreshes it once and
/// retries. If the refresh token itself is rejected the session is cleared and
/// [onSessionExpired] runs. Network failures never log the user out.
class ApiClient {
  ApiClient({
    required String baseUrl,
    required this.storage,
    required this.onSessionExpired,
    HttpClientAdapter? adapter,
    ResponseCache? cache,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 20),
           contentType: Headers.jsonContentType,
         ),
       ),
       _plain = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 15),
           receiveTimeout: const Duration(seconds: 20),
           contentType: Headers.jsonContentType,
         ),
       ) {
    if (adapter != null) {
      dio.httpClientAdapter = adapter;
      _plain.httpClientAdapter = adapter;
    }
    dio.interceptors.add(
      InterceptorsWrapper(onRequest: _attachToken, onError: _handleError),
    );
    if (cache != null) dio.interceptors.add(cache);
  }

  final Dio dio;
  final Dio _plain; // no interceptors: used for auth calls
  final TokenStorage storage;
  final void Function() onSessionExpired;
  Future<String?>? _refreshing;

  /// For login / logout / refresh calls that must not go through the retry logic.
  Dio get plain => _plain;

  Future<void> _attachToken(
    RequestOptions o,
    RequestInterceptorHandler h,
  ) async {
    final token = await storage.readAccess();
    if (token != null) o.headers['Authorization'] = 'Bearer $token';
    h.next(o);
  }

  Future<void> _handleError(DioException e, ErrorInterceptorHandler h) async {
    final req = e.requestOptions;
    if (e.response?.statusCode != 401 || req.extra[_retriedKey] == true) {
      return h.next(e);
    }
    final fresh = await _refreshAccessToken();
    if (fresh == null) return h.next(e);
    try {
      req.extra[_retriedKey] = true;
      req.headers['Authorization'] = 'Bearer $fresh';
      h.resolve(await dio.fetch(req));
    } on DioException catch (retryError) {
      h.next(retryError);
    }
  }

  /// Single-flight refresh: concurrent 401s share one refresh call.
  Future<String?> _refreshAccessToken() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<String?> _doRefresh() async {
    final refresh = await storage.readRefresh();
    if (refresh == null) {
      onSessionExpired();
      return null;
    }
    try {
      final r = await _plain.post(
        '/api/v1/auth/refresh',
        data: {'refresh_token': refresh},
      );
      final access = r.data['access_token'] as String;
      await storage.saveAccess(access);
      return access;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await storage.clear();
        onSessionExpired();
      }
      return null; // offline or server down: keep the session
    }
  }
}
