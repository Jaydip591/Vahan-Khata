
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vahan_khata/app.dart';
import 'package:vahan_khata/core/network/api_client.dart';
import 'package:vahan_khata/core/network/response_cache.dart';
import 'package:vahan_khata/core/provider_retry.dart';
import 'package:vahan_khata/core/providers.dart';
import 'package:vahan_khata/core/storage/token_storage.dart';
import 'package:vahan_khata/features/auth/data/app_user.dart';
import 'package:vahan_khata/features/auth/data/auth_repository.dart';
import 'package:vahan_khata/features/export/export_service.dart';

import 'fake_api.dart';

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.loginFailure, this.session = false});

  LoginFailure? loginFailure;
  bool session;
  int logoutCalls = 0;
  static const user =
      AppUser(id: '1', username: 'jaydip', name: 'Jaydip', role: 'superadmin');

  @override
  Future<bool> hasSession() async => session;
  @override
  Future<AppUser?> cachedUser() async => session ? user : null;
  @override
  Future<AppUser> login(String username, String password) async {
    if (loginFailure != null) throw LoginException(loginFailure!);
    session = true;
    return user;
  }

  @override
  Future<AppUser> fetchMe() async => user;
  @override
  Future<void> logout() async {
    logoutCalls++;
    session = false;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Loads the bundled Gujarati font so text renders real glyphs in tests.
Future<void> loadAppFonts() async {
  final loader = FontLoader('NotoSansGujarati');
  for (final f in ['Regular', 'Medium', 'Bold']) {
    loader.addFont(rootBundle.load('assets/fonts/NotoSansGujarati-$f.ttf'));
  }
  await loader.load();
}

Future<Widget> appWith(
  FakeAuthRepository repo, {
  Map<String, Object> prefs = const {},
  FakeApi? api,
  List<Override> overrides = const [],
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  FlutterSecureStorage.setMockInitialValues({});
  final sp = await SharedPreferences.getInstance();
  final fake = api ?? FakeApi();
  return ProviderScope(
    retry: noAutoRetry,
    overrides: [
      ...overrides,
      sharedPreferencesProvider.overrideWithValue(sp),
      authRepositoryProvider.overrideWithValue(repo),
      apiClientProvider.overrideWithValue(ApiClient(
        baseUrl: 'http://test',
        storage: TokenStorage(),
        onSessionExpired: () {},
        adapter: fake,
        cache: ResponseCache(sp),
      )),
    ],
    child: const VahanKhataApp(),
  );
}

/// Scrolls the widget into view (forms are taller than the screen), then taps it.
Future<void> tapIt(WidgetTester t, Finder f, {bool settle = true}) async {
  await t.ensureVisible(f);
  await t.pump();
  await t.tap(f);
  if (settle) await t.pumpAndSettle();
}

/// Records what would be handed to the share sheet.
class FakeExportService implements ExportService {
  final shared = <({String fileName, String mimeType, Uint8List bytes, String text})>[];

  @override
  Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String text,
  }) async {
    shared.add((fileName: fileName, mimeType: mimeType, bytes: bytes, text: text));
  }
}
