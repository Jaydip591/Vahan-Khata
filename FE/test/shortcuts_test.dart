import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:vahan_khata/features/home/presentation/launcher_shortcuts.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

class FakeQuickActions implements QuickActions {
  QuickActionHandler? handler;
  List<ShortcutItem> items = [];

  @override
  Future<void> initialize(QuickActionHandler handler) async => this.handler = handler;

  @override
  Future<void> setShortcutItems(List<ShortcutItem> items) async => this.items = items;

  @override
  Future<void> clearShortcutItems() async => items = [];
}

void main() {
  setUpAll(loadAppFonts);

  late FakeQuickActions qa;

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    qa = FakeQuickActions();
    final api = FakeApi()..addVehicle('Eicher 1', 'GJ05 AB 1234');
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true),
        api: api, overrides: [quickActionsProvider.overrideWithValue(qa)]));
    await t.pumpAndSettle();
  }

  testWidgets('shortcuts are set in the app language', (t) async {
    await boot(t);
    expect(qa.items.map((i) => i.localizedTitle), ['નવી ટ્રીપ', 'ખર્ચ ઉમેરો', 'પેમેન્ટ મળ્યું']);
    expect(qa.items.map((i) => i.icon), ['ic_shortcut_trip', 'ic_shortcut_expense', 'ic_shortcut_payment']);
  });

  testWidgets('the trip shortcut opens the trip form', (t) async {
    await boot(t);
    qa.handler!(kShortcutTrip);
    await t.pumpAndSettle();
    expect(find.text('Eicher 1'), findsWidgets); // vehicle chips of the form
    expect(find.byType(BackButtonIcon).evaluate().isNotEmpty || find.byIcon(Icons.arrow_back_rounded).evaluate().isNotEmpty, isTrue);
  });

  testWidgets('the expense shortcut opens the Kharcha tab and payment opens the sheet', (t) async {
    await boot(t);
    qa.handler!(kShortcutExpense);
    await t.pumpAndSettle();
    expect(find.text('શેનો ખર્ચ?'), findsOneWidget);
    qa.handler!(kShortcutPayment);
    await t.pumpAndSettle();
    expect(find.textContaining('કેટલા મળ્યા'), findsWidgets);
  });
}
