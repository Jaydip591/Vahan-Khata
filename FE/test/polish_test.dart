import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vahan_khata/core/ui/empty_state.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: FakeApi()));
    await t.pumpAndSettle();
  }

  testWidgets('empty trips show a picture and a button that opens the trip form', (t) async {
    await boot(t);
    await t.tap(find.text('ટ્રીપ').last);
    await t.pumpAndSettle();
    expect(find.byType(EmptyState), findsOneWidget);
    await tapIt(t, find.text('પહેલી ટ્રીપ ઉમેરો'));
    expect(find.text('નવી ટ્રીપ'), findsWidgets); // the form title
  });

  testWidgets('the gold tab line slides to the chosen tab', (t) async {
    await boot(t);
    Alignment where() =>
        t.widget<AnimatedAlign>(find.byKey(const ValueKey('tab-indicator'))).alignment as Alignment;
    expect(where().x, -1);
    await t.tap(find.text('રિપોર્ટ').last);
    await t.pumpAndSettle();
    expect(where().x, 1);
  });
}
