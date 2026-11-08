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
    'trips': [],
    'payments': [],
    'expenses': [],
  };

  /// Recent routes the server would suggest: maps with from/to place names.
  List<Map<String, dynamic>> routes = [];

  /// "METHOD /path" -> status code to return once (body {"detail":"error"}).
  final Map<String, int> failNext = {};

  static const seedPlaces = [
    ('Surat', 'સુરત'),
    ('Surendranagar', 'સુરેન્દ્રનગર'),
    ('Rajkot', 'રાજકોટ'),
    ('Vapi', 'વાપી'),
    ('Valsad', 'વલસાડ'),
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
    final body = o.data is Map ? Map<String, dynamic>.from(o.data as Map) : <String, dynamic>{};
    if (coll == 'ledger') return _ledger(rest);
    final list = db[coll];
    if (list == null) return _json(404, {'detail': 'no route'});

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

    if (coll == 'trips') return _trips(o, rest, body);
    if (coll == 'payments') return _payments(o, rest, body);
    if (coll == 'expenses') return _expenses(o, rest, body);

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


  // ───────────────────────── trips, payments, expenses, ledger ─────────────────────────
  Map<String, dynamic>? _find(String coll, Object? id) {
    for (final e in db[coll]!) {
      if (e['id'] == id) return e;
    }
    return null;
  }

  Map<String, dynamic>? _brief(String coll, Object? id) {
    final e = _find(coll, id);
    if (e == null) return null;
    return {
      'id': e['id'],
      if (e.containsKey('name')) 'name': e['name'],
      if (e.containsKey('number')) 'number': e['number'],
      if (e.containsKey('name_en')) 'name_en': e['name_en'],
      if (e.containsKey('name_gu')) 'name_gu': e['name_gu'],
    };
  }

  String _m(num v) => v.toStringAsFixed(2);

  /// Paid amount per trip id for one party: advance to its own trip first, the
  /// rest oldest trip first (same rules as the backend).
  Map<String, double> _allocate(String partyId) {
    final trips = db['trips']!.where((t) => t['party_id'] == partyId).toList()
      ..sort((a, b) => (a['trip_date'] as String).compareTo(b['trip_date'] as String));
    final pays = db['payments']!.where((p) => p['party_id'] == partyId);
    final paid = {for (final t in trips) t['id'] as String: 0.0};
    var pool = 0.0;
    for (final p in pays) {
      final amount = double.parse(p['amount'] as String);
      final tid = p['trip_id'];
      if (tid != null && paid.containsKey(tid)) {
        final trip = trips.firstWhere((t) => t['id'] == tid);
        final room = double.parse(trip['bhada'] as String) - paid[tid]!;
        final used = amount < room ? amount : room;
        paid[tid as String] = paid[tid]! + used;
        pool += amount - used;
      } else {
        pool += amount;
      }
    }
    for (final t in trips) {
      final id = t['id'] as String;
      final room = double.parse(t['bhada'] as String) - paid[id]!;
      final take = pool < room ? pool : room;
      paid[id] = paid[id]! + take;
      pool -= take;
    }
    return paid;
  }

  Map<String, dynamic> _tripOut(Map<String, dynamic> t) {
    final bhada = double.parse(t['bhada'] as String);
    final paid = _allocate(t['party_id'] as String)[t['id']] ?? 0;
    final advance = db['payments']!
        .where((p) => p['trip_id'] == t['id'])
        .fold<double>(0, (a, p) => a + double.parse(p['amount'] as String));
    return {
      'id': t['id'],
      'vehicle': _brief('vehicles', t['vehicle_id']),
      'driver': t['driver_id'] == null ? null : _brief('drivers', t['driver_id']),
      'party': _brief('parties', t['party_id']),
      'from_place': _brief('places', t['from_place_id']),
      'to_place': _brief('places', t['to_place_id']),
      'trip_date': t['trip_date'],
      'bhada': _m(bhada),
      'advance': _m(advance),
      'paid': _m(paid),
      'due': _m(bhada - paid),
      'pay_status': paid <= 0 ? 'unpaid' : (paid >= bhada ? 'paid' : 'partial'),
      'status': t['status'],
      'note': t['note'],
    };
  }

  ResponseBody _trips(RequestOptions o, List<String> rest, Map<String, dynamic> body) {
    final list = db['trips']!;
    if (o.method == 'GET' && rest.length == 2 && rest[0] == 'routes') return _json(200, routes);
    if (o.method == 'GET' && rest.isEmpty) {
      final month = o.queryParameters['month'] as String?;
      final limit = (o.queryParameters['limit'] as int?) ?? 100;
      final rows = list
          .where((t) => month == null || (t['trip_date'] as String).startsWith(month))
          .toList()
        ..sort((a, b) => (b['trip_date'] as String).compareTo(a['trip_date'] as String));
      return _json(200, rows.take(limit).map(_tripOut).toList());
    }
    if (o.method == 'POST') {
      final id = _id();
      final trip = {
        'id': id,
        'status': 'running',
        'note': null,
        ...body..remove('advance'),
      };
      list.add(trip);
      final adv = (o.data as Map)['advance'] as Map?;
      if (adv != null) {
        db['payments']!.add({
          'id': _id(),
          'party_id': trip['party_id'],
          'trip_id': id,
          'account_id': adv['account_id'],
          'amount': adv['amount'],
          'mode': adv['mode'],
          'paid_on': trip['trip_date'],
        });
      }
      return _json(201, _tripOut(trip));
    }
    final trip = _find('trips', rest.first);
    if (trip == null) return _json(404, {'detail': 'not found'});
    if (o.method == 'GET') return _json(200, _tripOut(trip));
    if (o.method == 'PATCH') {
      trip.addAll(body);
      return _json(200, _tripOut(trip));
    }
    if (o.method == 'DELETE') {
      list.remove(trip);
      for (final p in db['payments']!) {
        if (p['trip_id'] == trip['id']) p['trip_id'] = null;
      }
      return _json(204, null);
    }
    return _json(405, {});
  }

  Map<String, dynamic> _paymentOut(Map<String, dynamic> p) => {
        'id': p['id'],
        'party': _brief('parties', p['party_id']),
        'trip_id': p['trip_id'],
        'account': _brief('accounts', p['account_id']),
        'amount': _m(double.parse(p['amount'] as String)),
        'mode': p['mode'],
        'paid_on': p['paid_on'],
        'note': null,
      };

  ResponseBody _payments(RequestOptions o, List<String> rest, Map<String, dynamic> body) {
    final list = db['payments']!;
    if (o.method == 'GET') return _json(200, list.map(_paymentOut).toList());
    if (o.method == 'POST') {
      final p = {'id': _id(), 'trip_id': null, ...body};
      list.add(p);
      return _json(201, _paymentOut(p));
    }
    if (o.method == 'DELETE') {
      list.removeWhere((p) => p['id'] == rest.first);
      return _json(204, null);
    }
    return _json(405, {});
  }

  Map<String, dynamic> _expenseOut(Map<String, dynamic> e) => {
        'id': e['id'],
        'vehicle': _brief('vehicles', e['vehicle_id']),
        'trip_id': e['trip_id'],
        'account': e['account_id'] == null ? null : _brief('accounts', e['account_id']),
        'category': e['category'],
        'amount': _m(double.parse(e['amount'] as String)),
        'expense_date': e['expense_date'],
        'liters': e['liters'],
        'rate': e['rate'],
        'odometer': e['odometer'],
        'repair_kind': e['repair_kind'],
        'note': null,
      };

  ResponseBody _expenses(RequestOptions o, List<String> rest, Map<String, dynamic> body) {
    final list = db['expenses']!;
    if (o.method == 'GET') {
      final month = o.queryParameters['month'] as String?;
      final rows = list
          .where((e) => month == null || (e['expense_date'] as String).startsWith(month))
          .toList()
        ..sort((a, b) => (b['expense_date'] as String).compareTo(a['expense_date'] as String));
      return _json(200, rows.map(_expenseOut).toList());
    }
    if (o.method == 'POST') {
      final e = {'id': _id(), 'trip_id': null, ...body};
      list.add(e);
      return _json(201, _expenseOut(e));
    }
    final e = _find('expenses', rest.first);
    if (e == null) return _json(404, {'detail': 'not found'});
    if (o.method == 'PATCH') {
      e.addAll(body);
      return _json(200, _expenseOut(e));
    }
    if (o.method == 'DELETE') {
      list.remove(e);
      return _json(204, null);
    }
    return _json(405, {});
  }

  ResponseBody _ledger(List<String> rest) {
    // rest = ['parties'] or ['parties', id]
    if (rest.length == 1) {
      final rows = <Map<String, dynamic>>[];
      for (final p in db['parties']!) {
        final trips = db['trips']!.where((t) => t['party_id'] == p['id']).toList();
        final paidMap = _allocate(p['id'] as String);
        final unpaid = trips.where((t) => paidMap[t['id']]! < double.parse(t['bhada'] as String)).toList();
        final totalBhada = trips.fold<double>(0, (a, t) => a + double.parse(t['bhada'] as String));
        final totalPaid = db['payments']!
            .where((x) => x['party_id'] == p['id'])
            .fold<double>(0, (a, x) => a + double.parse(x['amount'] as String));
        final dates = unpaid.map((t) => t['trip_date'] as String).toList()..sort();
        rows.add({
          'party_id': p['id'],
          'party_name': p['name'],
          'balance': _m(totalBhada - totalPaid),
          'unpaid_trips': unpaid.length,
          'oldest_unpaid_date': dates.isEmpty ? null : dates.first,
        });
      }
      rows.sort((a, b) {
        final ao = double.parse(a['balance'] as String) > 0 ? 0 : 1;
        final bo = double.parse(b['balance'] as String) > 0 ? 0 : 1;
        if (ao != bo) return ao - bo;
        return ((a['oldest_unpaid_date'] ?? '9999') as String).compareTo((b['oldest_unpaid_date'] ?? '9999') as String);
      });
      final due = rows
          .map((r) => double.parse(r['balance'] as String))
          .where((b) => b > 0)
          .fold<double>(0, (a, b) => a + b);
      return _json(200, {'total_due': _m(due), 'parties': rows});
    }
    final party = _find('parties', rest[1]);
    if (party == null) return _json(404, {'detail': 'not found'});
    final trips = db['trips']!.where((t) => t['party_id'] == party['id']).toList()
      ..sort((a, b) => (b['trip_date'] as String).compareTo(a['trip_date'] as String));
    final paidMap = _allocate(party['id'] as String);
    final pays = db['payments']!.where((x) => x['party_id'] == party['id']).toList();
    final totalBhada = trips.fold<double>(0, (a, t) => a + double.parse(t['bhada'] as String));
    final totalPaid = pays.fold<double>(0, (a, x) => a + double.parse(x['amount'] as String));
    return _json(200, {
      'party': {'id': party['id'], 'name': party['name'], 'phone': party['phone']},
      'total_bhada': _m(totalBhada),
      'total_paid': _m(totalPaid),
      'balance': _m(totalBhada - totalPaid),
      'trips': [
        for (final t in trips)
          {
            'id': t['id'],
            'trip_date': t['trip_date'],
            'from_place': _brief('places', t['from_place_id']),
            'to_place': _brief('places', t['to_place_id']),
            'vehicle_name': _find('vehicles', t['vehicle_id'])!['name'],
            'bhada': _m(double.parse(t['bhada'] as String)),
            'paid': _m(paidMap[t['id']]!),
            'due': _m(double.parse(t['bhada'] as String) - paidMap[t['id']]!),
            'pay_status': paidMap[t['id']]! <= 0
                ? 'unpaid'
                : (paidMap[t['id']]! >= double.parse(t['bhada'] as String) ? 'paid' : 'partial'),
          },
      ],
      'payments': pays.reversed.map(_paymentOut).toList(),
    });
  }

  void addAccount(String name, {String kind = 'cash'}) => db['accounts']!.add({
        'id': _id(),
        'name': name,
        'kind': kind,
        'opening_balance': '0',
        'is_active': true,
      });

  void addDriver(String name, {String? defaultVehicleId}) => db['drivers']!.add({
        'id': _id(),
        'name': name,
        'phone': null,
        'default_vehicle_id': defaultVehicleId,
        'is_active': true,
      });

  String placeId(String nameEn) =>
      db['places']!.firstWhere((p) => p['name_en'] == nameEn)['id'] as String;

  /// Add a trip directly (as if it was created earlier).
  Map<String, dynamic> addTrip({
    required String vehicleId,
    required String partyId,
    required String from,
    required String to,
    String date = '2026-11-05',
    String bhada = '12000',
  }) {
    final t = <String, dynamic>{
      'id': _id(),
      'vehicle_id': vehicleId,
      'driver_id': null,
      'party_id': partyId,
      'from_place_id': placeId(from),
      'to_place_id': placeId(to),
      'trip_date': date,
      'bhada': bhada,
      'status': 'running',
      'note': null,
    };
    db['trips']!.add(t);
    return t;
  }

  @override
  void close({bool force = false}) {}
}
