import '../../../core/money.dart';
import '../../places/data/place.dart';

enum PayStatus { unpaid, partial, paid }

class NamedRef {
  const NamedRef({required this.id, required this.name, this.number});
  final String id;
  final String name;
  final String? number;

  factory NamedRef.fromJson(Map<String, dynamic> j) =>
      NamedRef(id: j['id'] as String, name: j['name'] as String, number: j['number'] as String?);
}

class Trip {
  const Trip({
    required this.id,
    required this.vehicle,
    this.driver,
    required this.party,
    required this.from,
    required this.to,
    required this.tripDate,
    required this.bhada,
    required this.advance,
    required this.paid,
    required this.due,
    required this.payStatus,
    required this.closed,
    this.note,
  });

  final String id;
  final NamedRef vehicle;
  final NamedRef? driver;
  final NamedRef party;
  final Place from;
  final Place to;
  final DateTime tripDate;
  final double bhada;
  final double advance;
  final double paid;
  final double due;
  final PayStatus payStatus;
  final bool closed;
  final String? note;

  factory Trip.fromJson(Map<String, dynamic> j) => Trip(
        id: j['id'] as String,
        vehicle: NamedRef.fromJson(j['vehicle'] as Map<String, dynamic>),
        driver: j['driver'] == null ? null : NamedRef.fromJson(j['driver'] as Map<String, dynamic>),
        party: NamedRef.fromJson(j['party'] as Map<String, dynamic>),
        from: Place.fromJson(j['from_place'] as Map<String, dynamic>),
        to: Place.fromJson(j['to_place'] as Map<String, dynamic>),
        tripDate: DateTime.parse(j['trip_date'] as String),
        bhada: parseMoney(j['bhada']),
        advance: parseMoney(j['advance']),
        paid: parseMoney(j['paid']),
        due: parseMoney(j['due']),
        payStatus: PayStatus.values.firstWhere(
          (s) => s.name == j['pay_status'],
          orElse: () => PayStatus.unpaid,
        ),
        closed: j['status'] == 'closed',
        note: j['note'] as String?,
      );
}

class RecentRoute {
  const RecentRoute({required this.from, required this.to, required this.trips, required this.lastBhada});
  final Place from;
  final Place to;
  final int trips;
  final double lastBhada;

  factory RecentRoute.fromJson(Map<String, dynamic> j) => RecentRoute(
        from: Place.fromJson(j['from_place'] as Map<String, dynamic>),
        to: Place.fromJson(j['to_place'] as Map<String, dynamic>),
        trips: j['trips'] as int,
        lastBhada: parseMoney(j['last_bhada']),
      );
}

class AdvanceInput {
  const AdvanceInput({required this.amount, required this.mode, required this.accountId});
  final int amount;
  final String mode; // cash | online
  final String accountId;

  Map<String, dynamic> toJson() =>
      {'amount': amount.toString(), 'mode': mode, 'account_id': accountId};
}

class TripInput {
  const TripInput({
    required this.vehicleId,
    this.driverId,
    required this.partyId,
    required this.fromPlaceId,
    required this.toPlaceId,
    required this.tripDate,
    required this.bhada,
    this.advance,
  });

  final String vehicleId;
  final String? driverId;
  final String partyId;
  final String fromPlaceId;
  final String toPlaceId;
  final DateTime tripDate;
  final int bhada;
  final AdvanceInput? advance;

  Map<String, dynamic> toJson({bool includeAdvance = true}) => {
        'vehicle_id': vehicleId,
        'driver_id': driverId,
        'party_id': partyId,
        'from_place_id': fromPlaceId,
        'to_place_id': toPlaceId,
        'trip_date': dateKey(tripDate),
        'bhada': bhada.toString(),
        if (includeAdvance && advance != null) 'advance': advance!.toJson(),
      };
}
