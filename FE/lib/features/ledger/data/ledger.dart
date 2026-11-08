import '../../../core/money.dart';
import '../../places/data/place.dart';
import '../../trips/data/trip.dart';

class PartyBalance {
  const PartyBalance({
    required this.partyId,
    required this.name,
    required this.balance,
    required this.unpaidTrips,
    this.oldestUnpaid,
  });

  final String partyId;
  final String name;
  final double balance; // positive = they owe us
  final int unpaidTrips;
  final DateTime? oldestUnpaid;

  factory PartyBalance.fromJson(Map<String, dynamic> j) => PartyBalance(
        partyId: j['party_id'] as String,
        name: j['party_name'] as String,
        balance: parseMoney(j['balance']),
        unpaidTrips: j['unpaid_trips'] as int,
        oldestUnpaid: j['oldest_unpaid_date'] == null
            ? null
            : DateTime.parse(j['oldest_unpaid_date'] as String),
      );
}

class PartyBalances {
  const PartyBalances({required this.totalDue, required this.parties});
  final double totalDue;
  final List<PartyBalance> parties;

  factory PartyBalances.fromJson(Map<String, dynamic> j) => PartyBalances(
        totalDue: parseMoney(j['total_due']),
        parties: (j['parties'] as List)
            .map((e) => PartyBalance.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class LedgerTrip {
  const LedgerTrip({
    required this.id,
    required this.date,
    required this.from,
    required this.to,
    required this.vehicleName,
    required this.bhada,
    required this.paid,
    required this.due,
    required this.status,
  });

  final String id;
  final DateTime date;
  final Place from;
  final Place to;
  final String vehicleName;
  final double bhada;
  final double paid;
  final double due;
  final PayStatus status;

  factory LedgerTrip.fromJson(Map<String, dynamic> j) => LedgerTrip(
        id: j['id'] as String,
        date: DateTime.parse(j['trip_date'] as String),
        from: Place.fromJson(j['from_place'] as Map<String, dynamic>),
        to: Place.fromJson(j['to_place'] as Map<String, dynamic>),
        vehicleName: j['vehicle_name'] as String,
        bhada: parseMoney(j['bhada']),
        paid: parseMoney(j['paid']),
        due: parseMoney(j['due']),
        status: PayStatus.values.firstWhere((s) => s.name == j['pay_status'], orElse: () => PayStatus.unpaid),
      );
}

class LedgerPayment {
  const LedgerPayment({
    required this.id,
    required this.amount,
    required this.mode,
    required this.date,
    required this.accountName,
    required this.isAdvance,
  });

  final String id;
  final double amount;
  final String mode;
  final DateTime date;
  final String accountName;
  final bool isAdvance;

  factory LedgerPayment.fromJson(Map<String, dynamic> j) => LedgerPayment(
        id: j['id'] as String,
        amount: parseMoney(j['amount']),
        mode: j['mode'] as String,
        date: DateTime.parse(j['paid_on'] as String),
        accountName: (j['account'] as Map<String, dynamic>)['name'] as String,
        isAdvance: j['trip_id'] != null,
      );
}

class PartyLedger {
  const PartyLedger({
    required this.partyId,
    required this.name,
    this.phone,
    required this.totalBhada,
    required this.totalPaid,
    required this.balance,
    required this.trips,
    required this.payments,
  });

  final String partyId;
  final String name;
  final String? phone;
  final double totalBhada;
  final double totalPaid;
  final double balance;
  final List<LedgerTrip> trips;
  final List<LedgerPayment> payments;

  factory PartyLedger.fromJson(Map<String, dynamic> j) {
    final p = j['party'] as Map<String, dynamic>;
    return PartyLedger(
      partyId: p['id'] as String,
      name: p['name'] as String,
      phone: p['phone'] as String?,
      totalBhada: parseMoney(j['total_bhada']),
      totalPaid: parseMoney(j['total_paid']),
      balance: parseMoney(j['balance']),
      trips: (j['trips'] as List).map((e) => LedgerTrip.fromJson(e as Map<String, dynamic>)).toList(),
      payments:
          (j['payments'] as List).map((e) => LedgerPayment.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
