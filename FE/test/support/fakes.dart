import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vahan_khata/app.dart';
import 'package:vahan_khata/core/providers.dart';
import 'package:vahan_khata/features/auth/data/app_user.dart';
import 'package:vahan_khata/features/auth/data/auth_repository.dart';

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
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final sp = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: const VahanKhataApp(),
  );
}
