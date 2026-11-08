import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'expense.dart';

class ExpenseRepository {
  ExpenseRepository(this._dio);
  final Dio _dio;

  Future<List<Expense>> list({String? month, int limit = 200}) async {
    final r = await _dio.get('/api/v1/expenses', queryParameters: {'month': ?month, 'limit': limit});
    return (r.data as List).map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Expense> create(ExpenseInput input) async {
    final r = await _dio.post('/api/v1/expenses', data: input.toJson());
    return Expense.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Expense> update(String id, ExpenseInput input) async {
    final r = await _dio.patch('/api/v1/expenses/$id', data: input.toJson());
    return Expense.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/api/v1/expenses/$id');
}

final expenseRepositoryProvider =
    Provider<ExpenseRepository>((ref) => ExpenseRepository(ref.watch(apiClientProvider).dio));

final expensesProvider = FutureProvider.family<List<Expense>, String>(
  (ref, month) => ref.watch(expenseRepositoryProvider).list(month: month),
);
