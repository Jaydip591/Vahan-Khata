import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/providers.dart';
import 'ledger.dart';

class LedgerRepository {
  LedgerRepository(this._dio);
  final Dio _dio;

  Future<PartyBalances> balances() async {
    final r = await _dio.get('/api/v1/ledger/parties');
    return PartyBalances.fromJson(r.data as Map<String, dynamic>);
  }

  Future<PartyLedger> partyLedger(String partyId) async {
    final r = await _dio.get('/api/v1/ledger/parties/$partyId');
    return PartyLedger.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> addPayment({
    required String partyId,
    required int amount,
    required String mode,
    required String accountId,
    required DateTime paidOn,
  }) =>
      _dio.post('/api/v1/payments', data: {
        'party_id': partyId,
        'amount': amount.toString(),
        'mode': mode,
        'account_id': accountId,
        'paid_on': dateKey(paidOn),
      });

  Future<void> deletePayment(String id) => _dio.delete('/api/v1/payments/$id');
}

final ledgerRepositoryProvider =
    Provider<LedgerRepository>((ref) => LedgerRepository(ref.watch(apiClientProvider).dio));

final partyBalancesProvider =
    FutureProvider<PartyBalances>((ref) => ref.watch(ledgerRepositoryProvider).balances());

final partyLedgerProvider = FutureProvider.family<PartyLedger, String>(
  (ref, partyId) => ref.watch(ledgerRepositoryProvider).partyLedger(partyId),
);
