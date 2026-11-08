import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'driver.dart';

class DriverRepository {
  DriverRepository(this._dio);
  final Dio _dio;

  Future<List<Driver>> list() async {
    final r = await _dio.get('/api/v1/drivers');
    return (r.data as List).map((e) => Driver.fromJson(e as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> _body(String name, String? phone, String? defaultVehicleId) => {
        'name': name,
        'phone': phone,
        'default_vehicle_id': defaultVehicleId,
      };

  Future<Driver> create(String name, String? phone, String? defaultVehicleId) async {
    final r = await _dio.post('/api/v1/drivers', data: _body(name, phone, defaultVehicleId));
    return Driver.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Driver> update(String id, String name, String? phone, String? defaultVehicleId) async {
    final r = await _dio.patch('/api/v1/drivers/$id', data: _body(name, phone, defaultVehicleId));
    return Driver.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/api/v1/drivers/$id');
}

final driverRepositoryProvider =
    Provider<DriverRepository>((ref) => DriverRepository(ref.watch(apiClientProvider).dio));

final driversProvider =
    FutureProvider<List<Driver>>((ref) => ref.watch(driverRepositoryProvider).list());
