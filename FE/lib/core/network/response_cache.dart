import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'network_errors.dart';

/// Remembers the last good answer of every GET so lists and pickers still open
/// when there is no network. Only used when the request itself fails to connect.
class ResponseCache extends Interceptor {
  ResponseCache(this._prefs, {this.maxEntries = 80});

  final SharedPreferences _prefs;
  final int maxEntries;
  static const _indexKey = 'rc:index';
  static const _maxBytes = 400 * 1024;

  String _key(RequestOptions o) => 'rc:${o.uri.path}?${o.uri.query}';

  bool _cacheable(RequestOptions o) =>
      o.method == 'GET' && !o.uri.path.contains('/auth/');

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final o = response.requestOptions;
    if (_cacheable(o) &&
        response.statusCode == 200 &&
        response.extra['fromCache'] != true) {
      _store(_key(o), response.data);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    if (_cacheable(o) && isNetworkProblem(err)) {
      final raw = _prefs.getString(_key(o));
      if (raw != null) {
        return handler.resolve(
          Response(
            requestOptions: o,
            statusCode: 200,
            data: jsonDecode(raw),
            extra: {'fromCache': true},
          ),
        );
      }
    }
    handler.next(err);
  }

  void _store(String key, Object? data) {
    try {
      final raw = jsonEncode(data);
      if (raw.length > _maxBytes) return;
      final index = _prefs.getStringList(_indexKey) ?? <String>[];
      index.remove(key);
      index.add(key);
      while (index.length > maxEntries) {
        _prefs.remove(index.removeAt(0));
      }
      _prefs.setString(key, raw);
      _prefs.setStringList(_indexKey, index);
    } catch (_) {
      // A cache problem must never break a request.
    }
  }

  Future<void> clear() async {
    for (final k in _prefs.getStringList(_indexKey) ?? const <String>[]) {
      await _prefs.remove(k);
    }
    await _prefs.remove(_indexKey);
  }
}
