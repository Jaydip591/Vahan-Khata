import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vahan_khata/core/haptics.dart';
import 'package:vahan_khata/core/money.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

void main() {
  setUpAll(loadAppFonts);

  late FakeApi api;
  late String today;

  setUp(() {
    api = FakeApi();
    today = dateKey(DateTime.now());
    Haptics.enabled = true;
  });

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: api));
    await t.pumpAndSettle();
  }

  testWidgets('swiping an expense left asks first, then deletes it', (t) async {
    api.addVehicle('Eicher', 'GJ18AZ1266');
    api.addExpense(
      vehicleId: api.db['vehicles']!.first['id'] as String,
      category: 'toll',
      amount: '450',
      date: today,
    );
    await boot(t);
    await t.tap(find.text('ખર્ચ').first);
    await t.pumpAndSettle();
    expect(find.text('₹450'), findsWidgets);

    await t.drag(find.text('ટોલ').last, const Offset(-700, 0));
    await t.pumpAndSettle();
    expect(find.text('કાઢી નાખવું છે?'), findsOneWidget);

    // Cancel: the row stays.
    await t.tap(find.text('રદ કરો'));
    await t.pumpAndSettle();
    expect(api.db['expenses'], hasLength(1));

    await t.drag(find.text('ટોલ').last, const Offset(-700, 0));
    await t.pumpAndSettle();
    await t.tap(find.text('કાઢી નાખો').last);
    await t.pumpAndSettle();
    await t.pump(const Duration(milliseconds: 600));
    await t.pumpAndSettle();
    expect(api.db['expenses'], isEmpty);
    expect(find.text('₹450'), findsNothing);
  });

  testWidgets('the vibration switch in More is on by default and can be turned off', (t) async {
    await boot(t);
    await t.tap(find.byIcon(Icons.menu_rounded));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('ટેપ પર વાઇબ્રેશન'), 200);
    expect(t.widget<Switch>(find.byType(Switch)).value, isTrue);
    await t.tap(find.byType(Switch));
    await t.pumpAndSettle();
    expect(Haptics.enabled, isFalse);
    expect(t.widget<Switch>(find.byType(Switch)).value, isFalse);
  });
}
