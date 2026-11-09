import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/network_errors.dart';
import '../../core/providers.dart';
import '../expenses/data/expense_repository.dart';
import '../ledger/data/ledger_repository.dart';
import '../reports/data/report_repository.dart';
import '../trips/data/trip_repository.dart';
import 'outbox_item.dart';

enum SaveOutcome { sent, queued }

const _prefsKey = 'outbox.items';
const _retryEvery = Duration(seconds: 30);

final outboxProvider = NotifierProvider<OutboxController, List<OutboxItem>>(
  OutboxController.new,
);

/// Entries made without a connection wait here, survive closing the app, and are
/// sent in the order they were made as soon as the server can be reached.
class OutboxController extends Notifier<List<OutboxItem>> {
  Timer? _timer;
  bool _syncing = false;

  @override
  List<OutboxItem> build() {
    ref.onDispose(() => _timer?.cancel());
    final items = _load();
    if (items.any((i) => !i.failed)) _scheduleRetry();
    return items;
  }

  List<OutboxItem> _load() {
    final raw = ref.read(sharedPreferencesProvider).getString(_prefsKey);
    if (raw == null) return const [];
    try {
      return [
        for (final j in jsonDecode(raw) as List)
          OutboxItem.fromJson(j as Map<String, dynamic>),
      ];
    } catch (_) {
      return const [];
    }
  }

  void _set(List<OutboxItem> items) {
    state = items;
    ref
        .read(sharedPreferencesProvider)
        .setString(_prefsKey, jsonEncode([for (final i in items) i.toJson()]));
  }

  Future<void> _post(OutboxItem item) =>
      ref.read(apiClientProvider).dio.post(item.kind.path, data: item.body);

  /// Sends the entry now. With no connection it is kept on the phone instead.
  /// Anything else the server says (a refusal) is thrown so the form can show it.
  Future<SaveOutcome> save(OutboxItem item) async {
    try {
      await _post(item);
      return SaveOutcome.sent;
    } on DioException catch (e) {
      if (!isNetworkProblem(e)) rethrow;
      _set([...state, item]);
      _scheduleRetry();
      return SaveOutcome.queued;
    }
  }

  void remove(String id) => _set([
    for (final i in state)
      if (i.id != id) i,
  ]);

  /// Forgets everything waiting (used when logging out).
  Future<void> clear() async {
    _timer?.cancel();
    _timer = null;
    _set(const []);
  }

  void _scheduleRetry() {
    if (_timer != null) return;
    _timer = Timer(_retryEvery, () async {
      _timer = null;
      await syncNow();
    });
  }

  /// Tries to send everything that is waiting. Stops at the first connection problem.
  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;
    var sentAny = false;
    try {
      for (final item in state.where((i) => !i.failed).toList()) {
        try {
          await _post(item);
          remove(item.id);
          sentAny = true;
        } on DioException catch (e) {
          final code = e.response?.statusCode ?? 0;
          if (isNetworkProblem(e) || code >= 500 || code == 401) break;
          _set([
            for (final i in state)
              if (i.id == item.id)
                i.copyWith(failed: true, error: _reason(e))
              else
                i,
          ]);
        } catch (_) {
          break;
        }
      }
    } finally {
      _syncing = false;
    }
    if (sentAny) _refreshScreens();
    if (state.any((i) => !i.failed)) _scheduleRetry();
  }

  String _reason(DioException e) {
    final d = e.response?.data;
    if (d is Map && d['detail'] is String) return d['detail'] as String;
    return 'HTTP ${e.response?.statusCode}';
  }

  void _refreshScreens() {
    ref.invalidate(tripsProvider);
    ref.invalidate(expensesProvider);
    ref.invalidate(partyBalancesProvider);
    ref.invalidate(partyLedgerProvider);
    ref.invalidate(recentRoutesProvider);
    invalidateReports(ref);
  }
}
