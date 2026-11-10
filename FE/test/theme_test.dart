import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vahan_khata/core/theme/app_colors.dart';
import 'package:vahan_khata/core/ui/master_list.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

void main() {
  setUpAll(loadAppFonts);
  tearDown(() => AppColors.dark = false);

  Future<void> openMore(WidgetTester t, {Map<String, Object> prefs = const {}}) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: FakeApi(), prefs: prefs));
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.menu_rounded));
    await t.pumpAndSettle();
  }

  Color tileColor(WidgetTester t) => t
      .widget<Material>(find.descendant(of: find.byType(MasterTile).first, matching: find.byType(Material)).first)
      .color!;

  testWidgets('a saved dark choice opens the app dark', (t) async {
    await openMore(t, prefs: {'theme_mode': 'dark'});
    expect(AppColors.dark, isTrue);
    expect(tileColor(t), AppColors.card);
    expect(tileColor(t), isNot(Colors.white));
  });

  testWidgets('switching light and dark repaints screens that are already open', (t) async {
    await openMore(t, prefs: {'theme_mode': 'light'});
    expect(tileColor(t), Colors.white);
    await t.scrollUntilVisible(find.text('ડાર્ક'), 300, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('ડાર્ક'));
    await t.pumpAndSettle();
    await t.tap(find.text('ડાર્ક'), warnIfMissed: true);
    await t.pumpAndSettle();
    expect(AppColors.dark, isTrue);
    await t.scrollUntilVisible(find.byType(MasterTile).first, -300, scrollable: find.byType(Scrollable).first);
    expect(tileColor(t), const Color(0xFF181D24));
    await t.scrollUntilVisible(find.text('લાઇટ'), 300, scrollable: find.byType(Scrollable).first);
    await t.ensureVisible(find.text('લાઇટ'));
    await t.pumpAndSettle();
    await t.tap(find.text('લાઇટ'));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.byType(MasterTile).first, -300, scrollable: find.byType(Scrollable).first);
    expect(tileColor(t), Colors.white);
  });
}
