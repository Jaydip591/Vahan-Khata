import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import 'app_user.dart';

enum LoginFailure { invalid, disabled, network, unknown }

class LoginException implements Exception {
  const LoginException(this.failure);
  final LoginFailure failure;
}

class AuthRepository {
  AuthRepository({required this.api, required this.storage});

  final ApiClient api;
  final TokenStorage storage;

  Future<bool> hasSession() async => (await storage.readRefresh()) != null;

  Future<AppUser?> cachedUser() async {
    final json = await storage.readUser();
    return json == null ? null : AppUser.fromJson(json);
  }

  Future<AppUser> login(String username, String password) async {
    try {
      final r = await api.plain.post(
        '/api/v1/auth/login',
        data: {'username': username, 'password': password},
      );
      await storage.saveSession(
        access: r.data['access_token'] as String,
        refresh: r.data['refresh_token'] as String,
      );
      return await fetchMe();
    } on DioException catch (e) {
      throw LoginException(_failureFor(e));
    }
  }

  Future<AppUser> fetchMe() async {
    final r = await api.dio.get('/api/v1/users/me');
    final json = r.data as Map<String, dynamic>;
    await storage.saveUser(json);
    return AppUser.fromJson(json);
  }

  /// Ends the session on this phone. The server call is best effort: the
  /// local session is always cleared.
  Future<void> logout() async {
    final refresh = await storage.readRefresh();
    if (refresh != null) {
      try {
        await api.plain.post('/api/v1/auth/logout', data: {'refresh_token': refresh});
      } on DioException catch (_) {}
    }
    await storage.clear();
  }

  LoginFailure _failureFor(DioException e) {
    switch (e.response?.statusCode) {
      case 401:
        return LoginFailure.invalid;
      case 403:
        return LoginFailure.disabled;
    }
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return LoginFailure.network;
      default:
        return LoginFailure.unknown;
    }
  }
}
