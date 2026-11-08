import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import 'managed_user.dart';

class UserRepository {
  UserRepository(this._dio);
  final Dio _dio;

  Future<List<ManagedUser>> list() async {
    final r = await _dio.get('/api/v1/users');
    return (r.data as List).map((e) => ManagedUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ManagedUser> create({
    required String username,
    required String name,
    required String password,
  }) async {
    final r = await _dio.post(
      '/api/v1/users',
      data: {'username': username, 'name': name, 'password': password},
    );
    return ManagedUser.fromJson(r.data as Map<String, dynamic>);
  }

  /// Only the fields that are given are changed.
  Future<ManagedUser> update(String id, {String? name, String? password, bool? isActive}) async {
    final r = await _dio.patch('/api/v1/users/$id', data: {
      'name': ?name,
      'password': ?password,
      'is_active': ?isActive,
    });
    return ManagedUser.fromJson(r.data as Map<String, dynamic>);
  }
}

final userRepositoryProvider =
    Provider<UserRepository>((ref) => UserRepository(ref.watch(apiClientProvider).dio));

final usersProvider =
    FutureProvider<List<ManagedUser>>((ref) => ref.watch(userRepositoryProvider).list());
