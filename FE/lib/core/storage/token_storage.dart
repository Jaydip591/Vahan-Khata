import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the login session on the device. Access token is also cached in memory.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';
  static const _kUser = 'user_json';

  final FlutterSecureStorage _storage;
  String? _accessCache;
  bool _accessLoaded = false;

  Future<String?> readAccess() async {
    if (!_accessLoaded) {
      _accessCache = await _storage.read(key: _kAccess);
      _accessLoaded = true;
    }
    return _accessCache;
  }

  Future<String?> readRefresh() => _storage.read(key: _kRefresh);

  Future<void> saveSession({required String access, required String refresh}) async {
    _accessCache = access;
    _accessLoaded = true;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> saveAccess(String access) async {
    _accessCache = access;
    _accessLoaded = true;
    await _storage.write(key: _kAccess, value: access);
  }

  Future<void> saveUser(Map<String, dynamic> json) =>
      _storage.write(key: _kUser, value: jsonEncode(json));

  Future<Map<String, dynamic>?> readUser() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    _accessCache = null;
    _accessLoaded = true;
    await _storage.deleteAll();
  }
}
