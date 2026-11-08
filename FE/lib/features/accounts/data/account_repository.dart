import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'account.dart';

class AccountRepository {
  AccountRepository(this._dio);
  final Dio _dio;

  Future<List<Account>> list() async {
    final r = await _dio.get('/api/v1/accounts');
    return (r.data as List).map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> _body(String name, AccountKind kind, String openingBalance) =>
      {'name': name, 'kind': kind.key, 'opening_balance': openingBalance};

  Future<Account> create(String name, AccountKind kind, String openingBalance) async {
    final r = await _dio.post('/api/v1/accounts', data: _body(name, kind, openingBalance));
    return Account.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Account> update(String id, String name, AccountKind kind, String openingBalance) async {
    final r = await _dio.patch('/api/v1/accounts/$id', data: _body(name, kind, openingBalance));
    return Account.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/api/v1/accounts/$id');
}

final accountRepositoryProvider =
    Provider<AccountRepository>((ref) => AccountRepository(ref.watch(apiClientProvider).dio));

final accountsProvider =
    FutureProvider<List<Account>>((ref) => ref.watch(accountRepositoryProvider).list());
