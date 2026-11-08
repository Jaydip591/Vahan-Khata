import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'vehicle.dart';

class VehicleRepository {
  VehicleRepository(this._dio);
  final Dio _dio;

  Future<List<Vehicle>> list() async {
    final r = await _dio.get('/api/v1/vehicles');
    return (r.data as List).map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Vehicle> create(VehicleInput input) async {
    final r = await _dio.post('/api/v1/vehicles', data: input.toJson());
    return Vehicle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Vehicle> update(String id, VehicleInput input) async {
    final r = await _dio.patch('/api/v1/vehicles/$id', data: input.toJson());
    return Vehicle.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/api/v1/vehicles/$id');

  Future<String> suggestName(VehicleType type) async {
    final r = await _dio.get('/api/v1/vehicles/suggest-name', queryParameters: {'type': type.key});
    return r.data['name'] as String;
  }
}

final vehicleRepositoryProvider =
    Provider<VehicleRepository>((ref) => VehicleRepository(ref.watch(apiClientProvider).dio));

final vehiclesProvider =
    FutureProvider<List<Vehicle>>((ref) => ref.watch(vehicleRepositoryProvider).list());
