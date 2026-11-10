import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

void main() {
  setUpAll(loadAppFonts);

  late FakeAuthRepository auth;

  setUp(() {
    auth = FakeAuthRepository(session: true);
    PackageInfo.setMockInitialValues(
      appName: 'Vahan Khata',
      packageName: 'com.jaydip.vahan_khata',
      version: '1.0.0',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  Future<void> openProfile(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(auth, api: FakeApi()));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.menu_rounded));
    await t.pumpAndSettle();
    await tapIt(t, find.text('@jaydip'));
  }

  testWidgets('More shows settings with the app version', (t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(auth, api: FakeApi()));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.menu_rounded));
    await t.pumpAndSettle();
    expect(find.text('સેટિંગ્સ'.toUpperCase()), findsOneWidget);
    await t.scrollUntilVisible(find.text('1.0.0 (7)'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('એપ વર્ઝન'), findsOneWidget);
  });

  testWidgets('profile shows company and role, and edits name and phone', (t) async {
    await openProfile(t);
    expect(find.text('પ્રોફાઇલ'), findsOneWidget);
    expect(find.text('Prajapati Transport'), findsOneWidget);
    expect(find.text('માલિક (બધી છૂટ)'), findsOneWidget);
    expect(find.text('નંબર ઉમેર્યો નથી'), findsOneWidget);

    await tapIt(t, find.text('પ્રોફાઇલ બદલો'));
    await t.enterText(find.byType(TextFormField).at(1), '12ab');
    await t.enterText(find.byType(TextFormField).at(1), '12345');
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('10 આંકડાનો નંબર લખો'), findsOneWidget);

    await t.enterText(find.byType(TextFormField).at(0), 'Jaydip P');
    await t.enterText(find.byType(TextFormField).at(1), '98250 12345');
    await tapIt(t, find.text('સેવ કરો'));
    await t.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('9825012345'), findsOneWidget);
    expect(find.text('Jaydip P'), findsOneWidget);
    expect(auth.user.phone, '9825012345');
  });

  testWidgets('change password checks both new fields and the old password', (t) async {
    await openProfile(t);
    await tapIt(t, find.text('પાસવર્ડ બદલો'));
    final f = find.byType(TextFormField);
    await t.enterText(f.at(0), 'wrong-1');
    await t.enterText(f.at(1), 'new-pass-1');
    await t.enterText(f.at(2), 'new-pass-2');
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('બંને પાસવર્ડ સરખા નથી'), findsOneWidget);

    await t.enterText(f.at(2), 'new-pass-1');
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('હાલનો પાસવર્ડ ખોટો છે'), findsOneWidget);
    expect(auth.changedPasswords, isEmpty);

    await t.enterText(f.at(0), 'secret-1');
    await tapIt(t, find.text('સેવ કરો'));
    expect(auth.changedPasswords, ['new-pass-1']);
    expect(find.text('પાસવર્ડ બદલાઈ ગયો. બીજા ફોનમાંથી લોગઆઉટ થયું.'), findsOneWidget);
    expect(find.text('પ્રોફાઇલ'), findsOneWidget); // back on the profile
  });
}
