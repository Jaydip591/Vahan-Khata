import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'place.dart';

class PlaceRepository {
  PlaceRepository(this._dio);
  final Dio _dio;

  Future<List<Place>> search(String query, {int limit = 20}) async {
    final r = await _dio.get('/api/v1/places', queryParameters: {
      if (query.trim().isNotEmpty) 'q': query.trim(),
      'limit': limit,
    });
    return (r.data as List).map((e) => Place.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Gujarati spellings for an English name. Empty when unavailable (offline etc.).
  Future<List<String>> transliterate(String text) async {
    try {
      final r = await _dio.get('/api/v1/places/transliterate', queryParameters: {'text': text});
      return (r.data['suggestions'] as List).cast<String>();
    } on DioException {
      return const [];
    }
  }

  Future<Place> create({required String nameEn, required String nameGu}) async {
    final r = await _dio.post('/api/v1/places', data: {'name_en': nameEn, 'name_gu': nameGu});
    return Place.fromJson(r.data as Map<String, dynamic>);
  }
}

final placeRepositoryProvider =
    Provider<PlaceRepository>((ref) => PlaceRepository(ref.watch(apiClientProvider).dio));
