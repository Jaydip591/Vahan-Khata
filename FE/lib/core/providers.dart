import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_controller.dart';
import 'config/app_config.dart';
import 'network/api_client.dart';
import 'network/response_cache.dart';
import 'storage/token_storage.dart';

/// Overridden in main() with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final responseCacheProvider =
    Provider<ResponseCache>((ref) => ResponseCache(ref.watch(sharedPreferencesProvider)));

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    cache: ref.watch(responseCacheProvider),
    baseUrl: AppConfig.apiBaseUrl,
    storage: ref.watch(tokenStorageProvider),
    onSessionExpired: () => ref.read(authControllerProvider.notifier).sessionExpired(),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(apiClientProvider),
    storage: ref.watch(tokenStorageProvider),
  );
});
