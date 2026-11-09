import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'expense.dart';

class ExpenseRepository {
  ExpenseRepository(this._dio);
  final Dio _dio;

  Future<List<Expense>> list({
    String? month,
    String? vehicleId,
    String? tripId,
    int limit = 200,
  }) async {
    final r = await _dio.get(
      '/api/v1/expenses',
      queryParameters: {
        'month': ?month,
        'vehicle_id': ?vehicleId,
        'trip_id': ?tripId,
        'limit': limit,
      },
    );
    return (r.data as List)
        .map((e) => Expense.fromJson(e as Map<String, dynamic>))
        .toList();
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

final expenseRepositoryProvider = Provider<ExpenseRepository>(
  (ref) => ExpenseRepository(ref.watch(apiClientProvider).dio),
);

final expensesProvider = FutureProvider.family<List<Expense>, String>(
  (ref, month) => ref.watch(expenseRepositoryProvider).list(month: month),
);

/// Every expense of a month, or of one vehicle when [vehicleId] is given.
final monthExpensesProvider = FutureProvider.autoDispose
    .family<List<Expense>, ({String month, String? vehicleId})>(
      (ref, k) => ref
          .watch(expenseRepositoryProvider)
          .list(month: k.month, vehicleId: k.vehicleId, limit: 300),
    );

/// Everything spent on one trip (fuel, toll, food...).
final tripExpensesProvider = FutureProvider.autoDispose.family<List<Expense>, String>(
  (ref, tripId) => ref.watch(expenseRepositoryProvider).list(tripId: tripId, limit: 100),
);
