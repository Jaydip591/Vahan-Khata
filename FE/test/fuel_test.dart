import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
    api.addVehicle('Eicher', 'GJ18AZ1266'); // diesel
    api.addVehicle('Super Carry', 'GJ05CN3310', type: 'other', fuel: 'cng_petrol');
    api.addVehicle('Activa Van', 'GJ05PP1111', type: 'tempo', fuel: 'petrol');
    api.addAccount('Cash - Jaydip');
  });

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: api));
    await t.pumpAndSettle();
  }

  Future<void> openFuel(WidgetTester t) async {
    await t.tap(find.text('ખર્ચ').first);
    await t.pumpAndSettle();
    await t.tap(find.text('ઇંધણ').first);
    await t.pumpAndSettle();
  }

  Future<void> press(WidgetTester t, String digits) async {
    for (final k in digits.split('')) {
      await t.tap(find.text(k).last);
    }
    await t.pump();
  }

  bool selected(WidgetTester t, String label) {
    final chip = find.ancestor(of: find.text(label).last, matching: find.byType(Material)).first;
    return t.widget<Material>(chip).color == const Color(0xFF12161C);
  }

  Map<String, dynamic> sent() => api.where('POST', '/api/v1/expenses').single.data as Map<String, dynamic>;

  testWidgets('a diesel vehicle offers only diesel, already chosen', (t) async {
    await boot(t);
    await openFuel(t);
    await tapIt(t, find.text('Eicher'));
    expect(find.text('કયું ઇંધણ?'), findsOneWidget);
    expect(selected(t, 'ડીઝલ'), isTrue);
    expect(find.text('પેટ્રોલ'), findsNothing);
    expect(find.text('CNG'), findsNothing);
    await press(t, '3000');
    await tapIt(t, find.text('સેવ કરો'));
    expect(sent()['category'], 'diesel');
  });

  testWidgets('a CNG + petrol vehicle starts on CNG and petrol is one tap away', (t) async {
    await boot(t);
    await openFuel(t);
    await tapIt(t, find.text('Super Carry'));
    expect(selected(t, 'CNG'), isTrue);
    expect(find.text('પેટ્રોલ'), findsOneWidget);
    expect(find.text('ડીઝલ'), findsNothing);
    expect(find.text('કિગ્રા'), findsOneWidget); // CNG is counted in kg, not liters

    await tapIt(t, find.text('પેટ્રોલ'));
    expect(selected(t, 'પેટ્રોલ'), isTrue);
    expect(find.text('લિટર'), findsOneWidget);
    await press(t, '500');
    await tapIt(t, find.text('સેવ કરો'));
    expect(sent()['category'], 'petrol');
    expect(sent()['expense_date'], today);
  });

  testWidgets('switching vehicle resets the fuel to that vehicle\'s default', (t) async {
    await boot(t);
    await openFuel(t);
    await tapIt(t, find.text('Super Carry'));
    await tapIt(t, find.text('પેટ્રોલ'));
    await tapIt(t, find.text('Eicher'));
    expect(selected(t, 'ડીઝલ'), isTrue);
    await tapIt(t, find.text('Super Carry'));
    expect(selected(t, 'CNG'), isTrue);
  });

  testWidgets('a petrol-only vehicle starts on petrol', (t) async {
    await boot(t);
    await openFuel(t);
    await tapIt(t, find.text('Activa Van'));
    expect(selected(t, 'પેટ્રોલ'), isTrue);
    expect(find.text('CNG'), findsNothing);
  });

  testWidgets('add vehicle: fuel type chips, default diesel, saved as chosen', (t) async {
    await boot(t);
    await t.tap(find.byIcon(Icons.menu_rounded).first);
    await t.pumpAndSettle();
    await t.tap(find.text('ગાડીઓ'));
    await t.pumpAndSettle();
    await t.tap(find.text('નવી ગાડી ઉમેરો'));
    await t.pumpAndSettle();
    expect(find.text('ઇંધણનો પ્રકાર'), findsOneWidget);
    expect(selected(t, 'ડીઝલ'), isTrue);
    await tapIt(t, find.text('CNG + પેટ્રોલ'));
    await t.enterText(find.byType(TextField).last, 'GJ05 XY 4321');
    await tapIt(t, find.text('સેવ કરો'));
    final body = api.where('POST', '/api/v1/vehicles').single.data as Map;
    expect(body['fuel_type'], 'cng_petrol');
    expect(find.textContaining('CNG + પેટ્રોલ'), findsWidgets); // list shows the fuel next to the number
  });

  testWidgets('editing a petrol entry on a CNG + petrol vehicle keeps petrol', (t) async {
    final v = api.db['vehicles']![1]['id'] as String;
    api.addExpense(vehicleId: v, category: 'petrol', amount: '700', date: today, liters: '7', rate: '100');
    await boot(t);
    await t.tap(find.text('ખર્ચ').first);
    await t.pumpAndSettle();
    await t.tap(find.text('પેટ્રોલ').first); // the list row
    await t.pumpAndSettle();
    expect(selected(t, 'પેટ્રોલ'), isTrue);
    expect(find.text('લિટર'), findsOneWidget);
  });
}
