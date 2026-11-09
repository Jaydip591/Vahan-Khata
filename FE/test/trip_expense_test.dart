import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vahan_khata/core/money.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

void main() {
  setUpAll(loadAppFonts);

  late FakeApi api;
  late String today;
  late Map<String, dynamic> trip;

  setUp(() {
    api = FakeApi();
    today = dateKey(DateTime.now());
    api.addVehicle('Eicher', 'GJ18AZ1266');
    api.addParty('ખોડિયાર');
    api.addAccount('Cash - Jaydip');
    trip = api.addTrip(
      vehicleId: api.db['vehicles']!.first['id'] as String,
      partyId: api.db['parties']!.first['id'] as String,
      from: 'Rajkot',
      to: 'Surat',
      date: today,
      bhada: '12000',
    );
  });

  Future<void> openTrip(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: api));
    await t.pumpAndSettle();
    await t.tap(find.text('ટ્રીપ').first);
    await t.pumpAndSettle();
    await t.tap(find.textContaining('→').first);
    await t.pumpAndSettle();
  }

  Future<void> press(WidgetTester t, String digits) async {
    for (final k in digits.split('')) {
      await t.tap(find.text(k).last);
    }
    await t.pump();
  }

  testWidgets('an expense added from the trip is linked to it and shown with the profit', (t) async {
    await openTrip(t);
    expect(find.text('આ ટ્રીપમાં હજી ખર્ચ નથી'), findsOneWidget);

    await tapIt(t, find.widgetWithText(ActionChip, 'ટોલ'));
    await press(t, '600');
    await tapIt(t, find.text('સેવ કરો'));
    final sent = api.where('POST', '/api/v1/expenses').single.data as Map;
    expect(sent['trip_id'], trip['id']);
    expect(sent['vehicle_id'], trip['vehicle_id']);
    expect(sent['amount'], '600');

    expect(find.text('આ ટ્રીપમાં હજી ખર્ચ નથી'), findsNothing);
    expect(find.text('₹600'), findsNWidgets(2)); // the row and the total
    expect(find.text('આ ટ્રીપનો નફો'), findsOneWidget);
    expect(find.text('₹11,400'), findsOneWidget); // 12000 - 600
  });

  testWidgets('only expenses of this trip are listed', (t) async {
    final vid = trip['vehicle_id'] as String;
    api.addExpense(vehicleId: vid, category: 'toll', amount: '700', date: today); // no trip
    final own = api.addExpense(vehicleId: vid, category: 'toll', amount: '450', date: today);
    own['trip_id'] = trip['id'];
    await openTrip(t);
    expect(find.text('₹450'), findsNWidgets(2));
    expect(find.text('₹700'), findsNothing);
    expect(find.text('₹11,550'), findsOneWidget);
  });
}
