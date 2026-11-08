import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vahan_khata/core/network/api_client.dart';
import 'package:vahan_khata/core/storage/token_storage.dart';

typedef Handler = FutureOr<ResponseBody> Function(RequestOptions o);

class _Adapter implements HttpClientAdapter {
  _Adapter(this.handler);
  final Handler handler;
  final List<RequestOptions> calls = [];

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    calls.add(o);
    return handler(o);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int status, Object body) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );

void main() {
  late TokenStorage storage;
  late int expired;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storage = TokenStorage();
    await storage.saveSession(access: 'old-access', refresh: 'refresh-1');
    expired = 0;
  });

  ApiClient client(_Adapter a) => ApiClient(
        baseUrl: 'http://test',
        storage: storage,
        onSessionExpired: () => expired++,
        adapter: a,
      );

  test('adds the bearer token to requests', () async {
    final a = _Adapter((o) => _json(200, {'ok': true}));
    await client(a).dio.get('/api/v1/users/me');
    expect(a.calls.single.headers['Authorization'], 'Bearer old-access');
  });

  test('on 401 it refreshes once and retries with the new token', () async {
    final a = _Adapter((o) {
      if (o.path == '/api/v1/auth/refresh') return _json(200, {'access_token': 'new-access'});
      return o.headers['Authorization'] == 'Bearer new-access'
          ? _json(200, {'name': 'ok'})
          : _json(401, {'detail': 'expired'});
    });
    final r = await client(a).dio.get('/api/v1/users/me');
    expect(r.data['name'], 'ok');
    expect(await storage.readAccess(), 'new-access');
    expect(expired, 0);
  });

  test('parallel 401s share a single refresh call', () async {
    final a = _Adapter((o) async {
      if (o.path == '/api/v1/auth/refresh') {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _json(200, {'access_token': 'new-access'});
      }
      return o.headers['Authorization'] == 'Bearer new-access'
          ? _json(200, {'ok': true})
          : _json(401, {});
    });
    final c = client(a);
    await Future.wait([c.dio.get('/a'), c.dio.get('/b'), c.dio.get('/c')]);
    expect(a.calls.where((o) => o.path == '/api/v1/auth/refresh').length, 1);
  });

  test('a rejected refresh token clears the session and signals expiry', () async {
    final a = _Adapter((o) => _json(401, {'detail': 'no'}));
    await expectLater(client(a).dio.get('/api/v1/users/me'), throwsA(isA<DioException>()));
    expect(expired, 1);
    expect(await storage.readRefresh(), isNull);
  });

  test('being offline during refresh keeps the user logged in', () async {
    final a = _Adapter((o) {
      if (o.path == '/api/v1/auth/refresh') {
        throw DioException.connectionError(requestOptions: o, reason: 'offline');
      }
      return _json(401, {});
    });
    await expectLater(client(a).dio.get('/api/v1/users/me'), throwsA(isA<DioException>()));
    expect(expired, 0);
    expect(await storage.readRefresh(), 'refresh-1');
  });

  test('does not loop forever if the retried request is still 401', () async {
    final a = _Adapter((o) {
      if (o.path == '/api/v1/auth/refresh') return _json(200, {'access_token': 'new'});
      return _json(401, {});
    });
    await expectLater(client(a).dio.get('/api/v1/users/me'), throwsA(isA<DioException>()));
    expect(a.calls.where((o) => o.path == '/api/v1/auth/refresh').length, 1);
  });
}
