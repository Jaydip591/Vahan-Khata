import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// In-memory stand-in for the backend: the real repositories talk to this over Dio,
/// so JSON mapping and request bodies are exercised too.
class FakeApi implements HttpClientAdapter {
  final List<RequestOptions> calls = [];
  final Map<String, List<Map<String, dynamic>>> db = {
    'vehicles': [],
    'drivers': [],
    'parties': [],
    'accounts': [],
    'users': [],
    'places': [],
  };

  /// "METHOD /path" -> status code to return once (body {"detail":"error"}).
  final Map<String, int> failNext = {};

  static const seedPlaces = [
    ('Surat', 'સુરત'),
    ('Surendranagar', 'સુરેન્દ્રનગર'),
    ('Rajkot', 'રાજકોટ'),
    ('Vapi', 'વાપી'),
  ];
  Map<String, List<String>> translit = {
    'mundra': ['મુન્દ્રા', 'મુંદ્રા'],
  };

  int _n = 0;
  String _id() => 'id-${++_n}';

  FakeApi() {
    for (final (en, gu) in seedPlaces) {
      db['places']!.add({'id': _id(), 'name_en': en, 'name_gu': gu, 'is_seed': true});
    }
  }

  void addVehicle(String name, String number, {String type = 'eicher'}) =>
      db['vehicles']!.add({
        'id': _id(),
        'vehicle_type': type,
        'name': name,
        'number': number,
        'is_active': true,
        'insurance_exp': null,
        'puc_exp': null,
        'fitness_exp': null,
        'permit_exp': null,
        'tax_exp': null,
      });

  void addParty(String name, {String? phone}) => db['parties']!.add({
        'id': _id(),
        'name': name,
        'phone': phone,
        'payment_cycle': null,
        'is_active': true,
      });

  Iterable<RequestOptions> where(String method, String path) =>
      calls.where((c) => c.method == method && c.path == path);

  ResponseBody _json(int status, Object? body) => ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
      );

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    calls.add(o);
    final key = '${o.method} ${o.path}';
    final fail = failNext.remove(key);
    if (fail != null) return _json(fail, {'detail': 'error'});

    final parts = o.path.replaceFirst('/api/v1/', '').split('/');
    final coll = parts.first;
    final rest = parts.skip(1).toList();
    final list = db[coll];
    if (list == null) return _json(404, {'detail': 'no route'});
    final body = o.data is Map ? Map<String, dynamic>.from(o.data as Map) : <String, dynamic>{};

    if (coll == 'vehicles' && rest.length == 1 && rest[0] == 'suggest-name') {
      final type = o.queryParameters['type'] as String;
      final label = {
        'eicher': 'Eicher',
        'bolero': 'Bolero',
        'tata_ace': 'Tata Ace',
        'truck': 'Truck',
        'tempo': 'Tempo',
        'other': 'Vehicle',
      }[type]!;
      final used = list.map((v) => v['name'] as String).toSet();
      var n = 1;
      while (used.contains('$label $n')) {
        n++;
      }
      return _json(200, {'name': '$label $n'});
    }
    if (coll == 'places' && rest.length == 1 && rest[0] == 'transliterate') {
      final text = (o.queryParameters['text'] as String).toLowerCase();
      return _json(200, {'suggestions': translit[text] ?? <String>[]});
    }

    switch (o.method) {
      case 'GET':
        if (coll == 'places') {
          final q = ((o.queryParameters['q'] as String?) ?? '').toLowerCase();
          final hits = list
              .where((p) =>
                  q.isEmpty ||
                  (p['name_en'] as String).toLowerCase().contains(q) ||
                  (p['name_gu'] as String).contains(q))
              .toList();
          return _json(200, hits);
        }
        return _json(200, list.where((e) => e['is_active'] == true).toList());
      case 'POST':
        final item = <String, dynamic>{
          'id': _id(),
          'is_active': true,
          'is_seed': false,
          'role': 'superadmin',
          ...body,
        };
        list.add(item);
        return _json(201, item);
      case 'PATCH':
        final item = list.firstWhere((e) => e['id'] == rest.first);
        item.addAll(body);
        return _json(200, item);
      case 'DELETE':
        list.removeWhere((e) => e['id'] == rest.first);
        return _json(204, null);
    }
    return _json(405, {});
  }

  @override
  void close({bool force = false}) {}
}
