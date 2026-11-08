import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vahan_khata/features/auth/data/auth_repository.dart';

import 'support/fakes.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> boot(WidgetTester tester, FakeAuthRepository repo,
      {Map<String, Object> prefs = const {}}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(await appWith(repo, prefs: prefs));
    await tester.pumpAndSettle();
  }

  group('login', () {
    testWidgets('opens on the Gujarati login screen when there is no session', (t) async {
      await boot(t, FakeAuthRepository());
      expect(find.text('વાહન ખાતા'), findsOneWidget);
      expect(find.text('લોગિન કરો'), findsOneWidget);
      expect(find.text('એક વાર લોગિન, લોગઆઉટ સુધી ચાલુ'), findsOneWidget);
    });

    testWidgets('empty fields show validation messages', (t) async {
      await boot(t, FakeAuthRepository());
      await t.tap(find.text('લોગિન કરો'));
      await t.pumpAndSettle();
      expect(find.text('યુઝરનેમ લખો'), findsOneWidget);
      expect(find.text('પાસવર્ડ લખો'), findsOneWidget);
    });

    testWidgets('wrong password shows an error and stays on login', (t) async {
      await boot(t, FakeAuthRepository(loginFailure: LoginFailure.invalid));
      await t.enterText(find.byType(TextFormField).at(0), 'admin');
      await t.enterText(find.byType(TextFormField).at(1), 'wrong');
      await t.tap(find.text('લોગિન કરો'));
      await t.pumpAndSettle();
      expect(find.text('યુઝરનેમ અથવા પાસવર્ડ ખોટો છે'), findsOneWidget);
    });

    testWidgets('no network shows the connection message', (t) async {
      await boot(t, FakeAuthRepository(loginFailure: LoginFailure.network));
      await t.enterText(find.byType(TextFormField).at(0), 'admin');
      await t.enterText(find.byType(TextFormField).at(1), 'secret');
      await t.tap(find.text('લોગિન કરો'));
      await t.pumpAndSettle();
      expect(find.text('સર્વર સાથે જોડાઈ શકાયું નથી. ઇન્ટરનેટ તપાસો'), findsOneWidget);
    });

    testWidgets('successful login lands on Home with the five tabs', (t) async {
      await boot(t, FakeAuthRepository());
      await t.enterText(find.byType(TextFormField).at(0), 'jaydip');
      await t.enterText(find.byType(TextFormField).at(1), 'secret1');
      await t.tap(find.text('લોગિન કરો'));
      await t.pumpAndSettle();
      expect(find.text('નમસ્તે, Jaydip'), findsOneWidget);
      for (final tab in ['હોમ', 'ટ્રીપ', 'ખર્ચ', 'ખાતા', 'રિપોર્ટ']) {
        expect(find.text(tab), findsOneWidget);
      }
    });
  });

  group('session', () {
    testWidgets('a saved session skips login and opens Home', (t) async {
      await boot(t, FakeAuthRepository(session: true));
      expect(find.text('નમસ્તે, Jaydip'), findsOneWidget);
      expect(find.text('લોગિન કરો'), findsNothing);
    });

    testWidgets('logout asks for confirmation, then returns to login', (t) async {
      final repo = FakeAuthRepository(session: true);
      await boot(t, repo);
      await t.tap(find.byIcon(Icons.menu_rounded));
      await t.pumpAndSettle();
      await t.tap(find.text('લોગઆઉટ'));
      await t.pumpAndSettle();
      expect(find.text('લોગઆઉટ કરવું છે?'), findsOneWidget);

      // Cancel keeps the session.
      await t.tap(find.text('રદ કરો'));
      await t.pumpAndSettle();
      expect(repo.logoutCalls, 0);

      await t.tap(find.text('લોગઆઉટ'));
      await t.pumpAndSettle();
      await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('લોગઆઉટ')));
      await t.pumpAndSettle();
      expect(repo.logoutCalls, 1);
      expect(find.text('લોગિન કરો'), findsOneWidget);
    });
  });

  group('language', () {
    testWidgets('switching to English changes the UI and is remembered', (t) async {
      await boot(t, FakeAuthRepository(session: true));
      await t.tap(find.byIcon(Icons.menu_rounded));
      await t.pumpAndSettle();
      await t.tap(find.text('English'));
      await t.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('locale'), 'en');
    });

    testWidgets('a saved English choice is used on the next start', (t) async {
      await boot(t, FakeAuthRepository(), prefs: {'locale': 'en'});
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Vahan Khata'), findsOneWidget);
    });
  });
}
