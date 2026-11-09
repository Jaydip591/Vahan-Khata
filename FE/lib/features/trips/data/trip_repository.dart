import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'trip.dart';

class TripRepository {
  TripRepository(this._dio);
  final Dio _dio;

  Future<List<Trip>> list({
    String? month,
    String? vehicleId,
    int limit = 200,
  }) async {
    final r = await _dio.get(
      '/api/v1/trips',
      queryParameters: {
        'month': ?month,
        'vehicle_id': ?vehicleId,
        'limit': limit,
      },
    );
    return (r.data as List)
        .map((e) => Trip.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Trip> get(String id) async {
    final r = await _dio.get('/api/v1/trips/$id');
    return Trip.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Trip> create(TripInput input) async {
    final r = await _dio.post('/api/v1/trips', data: input.toJson());
    return Trip.fromJson(r.data as Map<String, dynamic>);
  }

  /// Edits the trip itself. The advance is a payment and is not changed here.
  Future<Trip> update(String id, TripInput input) async {
    final r = await _dio.patch(
      '/api/v1/trips/$id',
      data: input.toJson(includeAdvance: false),
    );
    return Trip.fromJson(r.data as Map<String, dynamic>);
  }

  Future<Trip> setClosed(String id, bool closed) async {
    final r = await _dio.patch(
      '/api/v1/trips/$id',
      data: {'status': closed ? 'closed' : 'running'},
    );
    return Trip.fromJson(r.data as Map<String, dynamic>);
  }

  Future<void> delete(String id) => _dio.delete('/api/v1/trips/$id');

  Future<List<RecentRoute>> recentRoutes() async {
    final r = await _dio.get('/api/v1/trips/routes/recent');
    return (r.data as List)
        .map((e) => RecentRoute.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final tripRepositoryProvider = Provider<TripRepository>(
  (ref) => TripRepository(ref.watch(apiClientProvider).dio),
);

/// Trips of one month ('2026-11').
final tripsProvider = FutureProvider.family<List<Trip>, String>(
  (ref, month) => ref.watch(tripRepositoryProvider).list(month: month),
);

/// Trips of one vehicle in one month. Auto-disposed so it is fresh each time it is opened.
final vehicleTripsProvider = FutureProvider.autoDispose
    .family<List<Trip>, ({String month, String vehicleId})>(
      (ref, k) => ref
          .watch(tripRepositoryProvider)
          .list(month: k.month, vehicleId: k.vehicleId, limit: 300),
    );

final recentRoutesProvider = FutureProvider<List<RecentRoute>>(
  (ref) => ref.watch(tripRepositoryProvider).recentRoutes(),
);
