import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers.dart';

/// Remembers what the user picked last, so entry forms start pre-filled.
class Defaults {
  Defaults(this._prefs);
  final SharedPreferences _prefs;

  String? get vehicleId => _prefs.getString('d_vehicle');
  String? get partyId => _prefs.getString('d_party');
  String? get accountId => _prefs.getString('d_account');
  String get payMode => _prefs.getString('d_mode') ?? 'cash';

  Future<void> setVehicle(String id) => _prefs.setString('d_vehicle', id);
  Future<void> setParty(String id) => _prefs.setString('d_party', id);
  Future<void> setAccount(String id) => _prefs.setString('d_account', id);
  Future<void> setPayMode(String mode) => _prefs.setString('d_mode', mode);
}

final defaultsProvider = Provider<Defaults>((ref) => Defaults(ref.watch(sharedPreferencesProvider)));
