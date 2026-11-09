import 'package:flutter/material.dart';

import '../../../core/money.dart';
import '../../../l10n/app_localizations.dart';
import '../../trips/data/trip.dart';

enum ExpenseCategory {
  diesel('diesel', Icons.local_gas_station_rounded),
  petrol('petrol', Icons.local_gas_station_rounded),
  cng('cng', Icons.propane_tank_rounded),
  toll('toll', Icons.add_road_rounded),
  repair('repair', Icons.build_rounded),
  allowance('allowance', Icons.payments_outlined),
  challan('challan', Icons.warning_amber_rounded),
  other('other', Icons.more_horiz_rounded);

  const ExpenseCategory(this.key, this.icon);
  final String key;
  final IconData icon;

  /// Diesel, petrol and CNG are all "fuel": they carry liters (kg for CNG), rate and odometer.
  bool get isFuel => this == diesel || this == petrol || this == cng;

  /// The tiles on the Kharcha tab: one Fuel tile instead of one per fuel.
  static const tiles = [diesel, toll, repair, allowance, challan, other];

  /// Name on the Kharcha tile (diesel's tile is the general Fuel tile).
  String tileLabel(AppL10n t) => this == diesel ? t.fuelLabel : label(t);

  static ExpenseCategory fromKey(String key) =>
      ExpenseCategory.values.firstWhere((c) => c.key == key, orElse: () => ExpenseCategory.other);

  String label(AppL10n t) => switch (this) {
        diesel => t.catDiesel,
        petrol => t.catPetrol,
        cng => t.catCng,
        toll => t.catToll,
        repair => t.catRepair,
        allowance => t.catAllowance,
        challan => t.catChallan,
        other => t.catOther,
      };
}

enum RepairKind {
  tyre('tyre'),
  oil('oil'),
  engine('engine'),
  battery('battery'),
  service('service'),
  other('other');

  const RepairKind(this.key);
  final String key;

  static RepairKind? fromKey(String? key) {
    for (final k in RepairKind.values) {
      if (k.key == key) return k;
    }
    return null;
  }

  String label(AppL10n t) => switch (this) {
        tyre => t.rkTyre,
        oil => t.rkOil,
        engine => t.rkEngine,
        battery => t.rkBattery,
        service => t.rkService,
        other => t.catOther,
      };
}

class Expense {
  const Expense({
    required this.id,
    required this.vehicle,
    required this.category,
    required this.amount,
    required this.date,
    this.tripId,
    this.accountId,
    this.liters,
    this.rate,
    this.odometer,
    this.repairKind,
  });

  final String id;
  final NamedRef vehicle;
  final ExpenseCategory category;
  final double amount;
  final DateTime date;
  final String? tripId; // set when the expense belongs to a trip
  final String? accountId;
  final double? liters;
  final double? rate;
  final int? odometer;
  final RepairKind? repairKind;

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        vehicle: NamedRef.fromJson(j['vehicle'] as Map<String, dynamic>),
        category: ExpenseCategory.fromKey(j['category'] as String),
        amount: parseMoney(j['amount']),
        date: DateTime.parse(j['expense_date'] as String),
        tripId: j['trip_id'] as String?,
        accountId: (j['account'] as Map<String, dynamic>?)?['id'] as String?,
        liters: j['liters'] == null ? null : parseMoney(j['liters']),
        rate: j['rate'] == null ? null : parseMoney(j['rate']),
        odometer: j['odometer'] as int?,
        repairKind: RepairKind.fromKey(j['repair_kind'] as String?),
      );
}

class ExpenseInput {
  const ExpenseInput({
    required this.vehicleId,
    required this.category,
    required this.amount,
    required this.date,
    this.tripId,
    this.accountId,
    this.liters,
    this.rate,
    this.odometer,
    this.repairKind,
  });

  final String vehicleId;
  final ExpenseCategory category;
  final String amount; // exact text from the keypad, e.g. "5520" or "5520.50"
  final DateTime date;
  final String? tripId;
  final String? accountId;
  final String? liters;
  final String? rate;
  final int? odometer;
  final RepairKind? repairKind;

  Map<String, dynamic> toJson() => {
        'vehicle_id': vehicleId,
        'category': category.key,
        'amount': amount,
        'expense_date': dateKey(date),
        'trip_id': tripId,
        'account_id': accountId,
        'liters': liters,
        'rate': rate,
        'odometer': odometer,
        'repair_kind': repairKind?.key,
      };
}
