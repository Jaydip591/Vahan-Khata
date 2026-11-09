import '../../../core/money.dart';

class MonthSummary {
  const MonthSummary({
    required this.income,
    required this.expense,
    required this.profit,
    required this.trips,
    required this.collected,
    required this.totalDue,
    required this.prevProfit,
  });

  final double income;
  final double expense;
  final double profit;
  final int trips;
  final double collected;
  final double totalDue;
  final double prevProfit;

  factory MonthSummary.fromJson(Map<String, dynamic> j) => MonthSummary(
        income: parseMoney(j['income']),
        expense: parseMoney(j['expense']),
        profit: parseMoney(j['profit']),
        trips: j['trips'] as int,
        collected: parseMoney(j['collected']),
        totalDue: parseMoney(j['total_due']),
        prevProfit: parseMoney(j['prev_profit']),
      );
}

class FuelTotal {
  const FuelTotal({required this.category, required this.amount, required this.quantity, required this.entries});

  final String category; // diesel / petrol / cng
  final double amount;
  final double quantity; // liters, kg for CNG
  final int entries;

  factory FuelTotal.fromJson(Map<String, dynamic> j) => FuelTotal(
        category: j['category'] as String,
        amount: parseMoney(j['amount']),
        quantity: parseMoney(j['quantity']),
        entries: j['entries'] as int,
      );
}

class VehicleReport {
  const VehicleReport({
    required this.id,
    required this.name,
    required this.number,
    required this.income,
    required this.expense,
    required this.profit,
    required this.trips,
    this.fuels = const [],
    this.km,
    this.mileage,
  });

  final String id;
  final String name;
  final String number;
  final double income;
  final double expense;
  final double profit;
  final int trips;
  final List<FuelTotal> fuels;
  final int? km;
  final double? mileage; // km per liter (km per kg when the only fuel is CNG)

  bool get mileageIsKg => fuels.length == 1 && fuels.first.category == 'cng';

  factory VehicleReport.fromJson(Map<String, dynamic> j) => VehicleReport(
        id: j['vehicle_id'] as String,
        name: j['name'] as String,
        number: j['number'] as String,
        income: parseMoney(j['income']),
        expense: parseMoney(j['expense']),
        profit: parseMoney(j['profit']),
        trips: j['trips'] as int,
        fuels: [for (final f in (j['fuels'] as List? ?? const [])) FuelTotal.fromJson(f as Map<String, dynamic>)],
        km: j['km'] as int?,
        mileage: j['mileage'] == null ? null : parseMoney(j['mileage']),
      );
}

class PartyReport {
  const PartyReport({
    required this.id,
    required this.name,
    required this.bhada,
    required this.received,
    required this.balance,
    required this.trips,
  });

  final String id;
  final String name;
  final double bhada;
  final double received;
  final double balance;
  final int trips;

  factory PartyReport.fromJson(Map<String, dynamic> j) => PartyReport(
        id: j['party_id'] as String,
        name: j['name'] as String,
        bhada: parseMoney(j['bhada']),
        received: parseMoney(j['received']),
        balance: parseMoney(j['balance']),
        trips: j['trips'] as int,
      );
}

class TrendPoint {
  const TrendPoint({required this.month, required this.income, required this.expense, required this.profit});

  final DateTime month;
  final double income;
  final double expense;
  final double profit;

  factory TrendPoint.fromJson(Map<String, dynamic> j) => TrendPoint(
        month: DateTime.parse('${j['month']}-01'),
        income: parseMoney(j['income']),
        expense: parseMoney(j['expense']),
        profit: parseMoney(j['profit']),
      );
}

class CategoryTotal {
  const CategoryTotal({required this.category, required this.amount, required this.count});

  final String category;
  final double amount;
  final int count;

  factory CategoryTotal.fromJson(Map<String, dynamic> j) => CategoryTotal(
        category: j['category'] as String,
        amount: parseMoney(j['amount']),
        count: j['count'] as int,
      );
}

class ExpenseReport {
  const ExpenseReport({required this.total, required this.categories});

  final double total;
  final List<CategoryTotal> categories;

  factory ExpenseReport.fromJson(Map<String, dynamic> j) => ExpenseReport(
        total: parseMoney(j['total']),
        categories: [
          for (final c in j['categories'] as List) CategoryTotal.fromJson(c as Map<String, dynamic>),
        ],
      );
}
