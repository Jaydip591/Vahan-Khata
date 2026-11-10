import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'payee.dart';

class PayeeRepository {
  PayeeRepository(this._dio);
  final Dio _dio;

  Future<List<Payee>> list() async {
    final r = await _dio.get('/api/v1/payees');
    return (r.data as List).map((e) => Payee.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Payee> create(String name, String upiId) async {
    final r = await _dio.post('/api/v1/payees', data: {'name': name, 'upi_id': upiId});
    return Payee.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Payee> update(String id, String name, String upiId) async {
    final r = await _dio.patch('/api/v1/payees/$id', data: {'name': name, 'upi_id': upiId});
    return Payee.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/api/v1/payees/$id');
}

final payeeRepositoryProvider = Provider<PayeeRepository>((ref) => PayeeRepository(ref.watch(apiClientProvider).dio));

final payeesProvider = FutureProvider<List<Payee>>((ref) => ref.watch(payeeRepositoryProvider).list());
