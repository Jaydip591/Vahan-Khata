import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import '../../expenses/data/expense_repository.dart';
import '../../trips/data/trip_repository.dart';
import 'report.dart';

class ReportRepository {
  ReportRepository(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>> _get(String path, Map<String, dynamic> q) async =>
      (await _dio.get('/api/v1/reports/$path', queryParameters: q)).data as Map<String, dynamic>;

  Future<MonthSummary> summary(String month) async =>
      MonthSummary.fromJson(await _get('summary', {'month': month}));

  Future<List<VehicleReport>> vehicles(String month) async => [
        for (final v in (await _get('vehicles', {'month': month}))['vehicles'] as List)
          VehicleReport.fromJson(v as Map<String, dynamic>),
      ];

  Future<List<PartyReport>> parties(String month) async => [
        for (final p in (await _get('parties', {'month': month}))['parties'] as List)
          PartyReport.fromJson(p as Map<String, dynamic>),
      ];

  Future<List<TrendPoint>> trend(String month) async => [
        for (final p in (await _get('trend', {'month': month, 'months': 6}))['points'] as List)
          TrendPoint.fromJson(p as Map<String, dynamic>),
      ];

  Future<ExpenseReport> expenses(String month) async =>
      ExpenseReport.fromJson(await _get('expenses', {'month': month}));

  Future<AccountBalances> accounts() async => AccountBalances.fromJson(await _get('accounts', {}));
}

final reportRepositoryProvider =
    Provider<ReportRepository>((ref) => ReportRepository(ref.watch(apiClientProvider).dio));

/// The month shown on Home and in Reports. Starts on the current month.
class SelectedMonth extends Notifier<DateTime> {
  @override
  DateTime build() {
    final n = DateTime.now();
    return DateTime(n.year, n.month);
  }

  void set(DateTime m) => state = DateTime(m.year, m.month);

  void shift(int delta) => state = DateTime(state.year, state.month + delta);
}

final selectedMonthProvider = NotifierProvider<SelectedMonth, DateTime>(SelectedMonth.new);

final summaryProvider = FutureProvider.family<MonthSummary, String>(
    (ref, month) => ref.watch(reportRepositoryProvider).summary(month));
final vehicleReportProvider = FutureProvider.family<List<VehicleReport>, String>(
    (ref, month) => ref.watch(reportRepositoryProvider).vehicles(month));
final partyReportProvider = FutureProvider.family<List<PartyReport>, String>(
    (ref, month) => ref.watch(reportRepositoryProvider).parties(month));
final trendProvider = FutureProvider.family<List<TrendPoint>, String>(
    (ref, month) => ref.watch(reportRepositoryProvider).trend(month));
final expenseReportProvider = FutureProvider.family<ExpenseReport, String>(
    (ref, month) => ref.watch(reportRepositoryProvider).expenses(month));

final accountBalancesProvider =
    FutureProvider<AccountBalances>((ref) => ref.watch(reportRepositoryProvider).accounts());

/// Key used by the family providers above.
String selectedMonthKey(DateTime d) => monthKey(d);

/// Call after any trip, expense or payment changes so Home and Reports show fresh numbers.
/// Pass `ref` (works with both Ref and WidgetRef).
void invalidateReports(dynamic ref) {
  ref.invalidate(summaryProvider);
  ref.invalidate(vehicleReportProvider);
  ref.invalidate(partyReportProvider);
  ref.invalidate(trendProvider);
  ref.invalidate(expenseReportProvider);
  ref.invalidate(accountBalancesProvider);
  ref.invalidate(vehicleTripsProvider);
  ref.invalidate(monthExpensesProvider);
}
