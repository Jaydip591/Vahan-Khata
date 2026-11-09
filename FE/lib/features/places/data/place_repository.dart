import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/network_errors.dart';
import '../../../core/providers.dart';
import 'place.dart';

const _knownKey = 'places.known';

class PlaceRepository {
  PlaceRepository(this._dio, this._prefs);
  final Dio _dio;
  final SharedPreferences _prefs;

  /// Searches the server. Every place ever seen is remembered on the phone, so with no
  /// internet the search still works on those.
  Future<List<Place>> search(String query, {int limit = 20}) async {
    try {
      final r = await _dio.get('/api/v1/places', queryParameters: {
        if (query.trim().isNotEmpty) 'q': query.trim(),
        'limit': limit,
      });
      final raw = (r.data as List).cast<Map<String, dynamic>>();
      _remember(raw);
      return raw.map(Place.fromJson).toList();
    } on DioException catch (e) {
      if (!isNetworkProblem(e)) rethrow;
      final q = query.trim().toLowerCase();
      final hits = _known().where((p) => q.isEmpty || p.nameEn.toLowerCase().contains(q) || p.nameGu.contains(q));
      return hits.take(limit).toList();
    }
  }

  Map<String, dynamic> _knownMap() {
    try {
      return jsonDecode(_prefs.getString(_knownKey) ?? '{}') as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  List<Place> _known() =>
      _knownMap().values.map((v) => Place.fromJson(v as Map<String, dynamic>)).toList();

  void _remember(List<Map<String, dynamic>> places) {
    final known = _knownMap();
    var changed = false;
    for (final p in places) {
      final id = p['id'] as String;
      if (known[id] == null) {
        known[id] = {'id': id, 'name_en': p['name_en'], 'name_gu': p['name_gu'], 'is_seed': p['is_seed']};
        changed = true;
      }
    }
    if (changed) _prefs.setString(_knownKey, jsonEncode(known));
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
    Provider<PlaceRepository>((ref) => PlaceRepository(ref.watch(apiClientProvider).dio, ref.watch(sharedPreferencesProvider)));
