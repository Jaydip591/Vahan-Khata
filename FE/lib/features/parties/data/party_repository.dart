import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'party.dart';

class PartyRepository {
  PartyRepository(this._dio);
  final Dio _dio;

  Future<List<Party>> list() async {
    final r = await _dio.get('/api/v1/parties');
    return (r.data as List).map((e) => Party.fromJson(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> _body(String name, String? phone, PaymentCycle? cycle) =>
      {'name': name, 'phone': phone, 'payment_cycle': cycle?.key};

  Future<Party> create(String name, String? phone, PaymentCycle? cycle) async {
    final r = await _dio.post('/api/v1/parties', data: _body(name, phone, cycle));
    return Party.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Party> update(String id, String name, String? phone, PaymentCycle? cycle) async {
    final r = await _dio.patch('/api/v1/parties/$id', data: _body(name, phone, cycle));
    return Party.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/api/v1/parties/$id');
}

final partyRepositoryProvider =
    Provider<PartyRepository>((ref) => PartyRepository(ref.watch(apiClientProvider).dio));

final partiesProvider =
    FutureProvider<List<Party>>((ref) => ref.watch(partyRepositoryProvider).list());
