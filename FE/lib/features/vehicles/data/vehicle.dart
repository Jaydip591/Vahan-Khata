import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../expenses/data/expense.dart';

enum VehicleType {
  eicher('eicher'),
  bolero('bolero'),
  tataAce('tata_ace'),
  truck('truck'),
  tempo('tempo'),
  other('other');

  const VehicleType(this.key);
  final String key;

  static VehicleType fromKey(String key) =>
      VehicleType.values.firstWhere((t) => t.key == key, orElse: () => VehicleType.other);

  String label(AppL10n t) => switch (this) {
        eicher => t.typeEicher,
        bolero => t.typeBolero,
        tataAce => t.typeTataAce,
        truck => t.typeTruck,
        tempo => t.typeTempo,
        other => t.typeOther,
      };

  IconData get icon => switch (this) {
        tempo || tataAce || bolero => Icons.local_shipping_outlined,
        _ => Icons.local_shipping_rounded,
      };
}

/// What the vehicle runs on. Chooses which fuel is preselected when fuel is added.
enum FuelType {
  diesel('diesel', [ExpenseCategory.diesel]),
  petrol('petrol', [ExpenseCategory.petrol]),
  cng('cng', [ExpenseCategory.cng]),
  cngPetrol('cng_petrol', [ExpenseCategory.cng, ExpenseCategory.petrol]);

  const FuelType(this.key, this.categories);
  final String key;

  /// Fuels this vehicle can take; the first one is the default.
  final List<ExpenseCategory> categories;

  ExpenseCategory get defaultCategory => categories.first;

  static FuelType fromKey(String? key) =>
      FuelType.values.firstWhere((f) => f.key == key, orElse: () => FuelType.diesel);

  String label(AppL10n t) => switch (this) {
        diesel => t.catDiesel,
        petrol => t.catPetrol,
        cng => t.catCng,
        cngPetrol => t.fuelCngPetrol,
      };
}

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);
String? _dateOut(DateTime? d) => d == null
    ? null
    : '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class Vehicle {
  const Vehicle({
    required this.id,
    required this.type,
    required this.name,
    required this.number,
    required this.isActive,
    this.fuelType = FuelType.diesel,
    this.insuranceExp,
    this.pucExp,
    this.fitnessExp,
    this.permitExp,
    this.taxExp,
  });

  final String id;
  final VehicleType type;
  final String name;
  final String number;
  final bool isActive;
  final FuelType fuelType;
  final DateTime? insuranceExp;
  final DateTime? pucExp;
  final DateTime? fitnessExp;
  final DateTime? permitExp;
  final DateTime? taxExp;

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: j['id'] as String,
        type: VehicleType.fromKey(j['vehicle_type'] as String),
        name: j['name'] as String,
        number: j['number'] as String,
        isActive: j['is_active'] as bool,
        fuelType: FuelType.fromKey(j['fuel_type'] as String?),
        insuranceExp: _date(j['insurance_exp']),
        pucExp: _date(j['puc_exp']),
        fitnessExp: _date(j['fitness_exp']),
        permitExp: _date(j['permit_exp']),
        taxExp: _date(j['tax_exp']),
      );
}

/// What the form sends. Dates are always included so a cleared date is saved as null.
class VehicleInput {
  const VehicleInput({
    required this.type,
    required this.name,
    required this.number,
    this.fuelType = FuelType.diesel,
    this.insuranceExp,
    this.pucExp,
    this.fitnessExp,
    this.permitExp,
    this.taxExp,
  });

  final VehicleType type;
  final FuelType fuelType;
  final String name;
  final String number;
  final DateTime? insuranceExp;
  final DateTime? pucExp;
  final DateTime? fitnessExp;
  final DateTime? permitExp;
  final DateTime? taxExp;

  Map<String, dynamic> toJson() => {
        'vehicle_type': type.key,
        'name': name,
        'number': number,
        'fuel_type': fuelType.key,
        'insurance_exp': _dateOut(insuranceExp),
        'puc_exp': _dateOut(pucExp),
        'fitness_exp': _dateOut(fitnessExp),
        'permit_exp': _dateOut(permitExp),
        'tax_exp': _dateOut(taxExp),
      };
}
