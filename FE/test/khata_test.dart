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
    api.addVehicle('Eicher 1', 'GJ05 AB 1234');
    api.addParty('ખોડિયાર');
    api.addParty('રમેશભાઈ');
    api.addAccount('Cash - Jaydip');
    api.addAccount('UPI - ભાઈ', kind: 'upi');
  });

  String vehicleId() => api.db['vehicles']!.first['id'] as String;
  String partyId(String name) => api.db['parties']!.firstWhere((p) => p['name'] == name)['id'] as String;

  void trip(String party, String date, String bhada, {String from = 'Surat', String to = 'Vapi'}) {
    api.addTrip(
        vehicleId: vehicleId(), partyId: partyId(party), from: from, to: to, date: date, bhada: bhada);
  }

  String ago(int days) => dateKey(DateTime.now().subtract(Duration(days: days)));

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: api));
    await t.pumpAndSettle();
  }

  Future<void> openKhata(WidgetTester t) async {
    await t.tap(find.text('ખાતા').first);
    await t.pumpAndSettle();
  }

  /// The posted body without the id the phone makes for safe retries.
  Map<String, dynamic> sentPayment() {
    final body = Map<String, dynamic>.from(api.where('POST', '/api/v1/payments').single.data as Map);
    expect(body['id'], isA<String>());
    return body..remove('id');
  }

  testWidgets('shows the total owed and parties, oldest unpaid first, with age tags', (t) async {
    trip('રમેશભાઈ', ago(1), '12000');
    trip('ખોડિયાર', ago(12), '38000');
    await boot(t);
    await openKhata(t);
    expect(find.text('₹50,000'), findsOneWidget); // total
    final khodiyar = t.getTopLeft(find.text('ખોડિયાર')).dy;
    final ramesh = t.getTopLeft(find.text('રમેશભાઈ')).dy;
    expect(khodiyar, lessThan(ramesh)); // 12 days old comes before 1 day old
    expect(find.text('12 દિવસ જૂનું'), findsOneWidget);
    expect(find.text('1 દિવસ જૂનું'), findsOneWidget);
  });

  testWidgets('a settled party is marked and a party with nothing is not listed as owing', (t) async {
    trip('ખોડિયાર', ago(3), '1000');
    api.db['payments']!.add({
      'id': 'p-1',
      'party_id': partyId('ખોડિયાર'),
      'trip_id': null,
      'account_id': api.db['accounts']!.first['id'],
      'amount': '1000',
      'mode': 'cash',
      'paid_on': ago(1),
    });
    await boot(t);
    await openKhata(t);
    expect(find.text('ચૂકતે'), findsNWidgets(2)); // both parties owe nothing
    expect(find.text('₹0'), findsOneWidget); // total
  });

  testWidgets('party khata shows totals, trips and payments', (t) async {
    trip('ખોડિયાર', ago(5), '12000');
    trip('ખોડિયાર', ago(2), '14000', to: 'Valsad');
    api.db['payments']!.add({
      'id': 'p-1',
      'party_id': partyId('ખોડિયાર'),
      'trip_id': null,
      'account_id': api.db['accounts']!.first['id'],
      'amount': '20000',
      'mode': 'online',
      'paid_on': ago(1),
    });
    await boot(t);
    await openKhata(t);
    await t.tap(find.text('ખોડિયાર'));
    await t.pumpAndSettle();
    expect(find.text('₹6,000'), findsWidgets); // balance
    expect(find.textContaining('કુલ ભાડું ₹26,000'), findsOneWidget);
    expect(find.textContaining('કુલ મળ્યા ₹20,000'), findsOneWidget);
    expect(find.text('સુરત → વાપી'), findsOneWidget);
    expect(find.text('સુરત → વલસાડ'), findsOneWidget);
    expect(find.text('+₹20,000'), findsOneWidget);
    expect(find.text('મળી ગયા'), findsOneWidget); // oldest trip is settled by the 20,000
    // payment row says how it came and into which account
    final acc = api.db['accounts']!.first['name'];
    expect(find.text('${formatDay(DateTime.parse(ago(1)))} · ઓનલાઇન · $acc'), findsOneWidget);
  });

  testWidgets('record the full due amount from the party khata', (t) async {
    trip('ખોડિયાર', ago(5), '12000');
    await boot(t);
    await openKhata(t);
    await t.tap(find.text('ખોડિયાર'));
    await t.pumpAndSettle();
    await tapIt(t, find.text('પેમેન્ટ મળ્યું'));
    // the party is already chosen and "All" is the default
    expect(find.text('જમા થશે'), findsOneWidget);
    expect(find.text('₹12,000'), findsWidgets);
    await tapIt(t, find.text('UPI - ભાઈ'));
    await tapIt(t, find.text('ઓનલાઇન'));
    await tapIt(t, find.text('સેવ કરો'));
    expect(sentPayment(), {
      'party_id': partyId('ખોડિયાર'),
      'amount': '12000',
      'mode': 'online',
      'account_id': api.db['accounts']!.last['id'],
      'paid_on': today,
    });
    // khata refreshed: the balance is gone and the trip is paid
    expect(find.text('મળી ગયા'), findsOneWidget);
    expect(find.text('પેમેન્ટ સેવ થયું'), findsOneWidget);
  });

  testWidgets('half and a custom amount', (t) async {
    trip('ખોડિયાર', ago(5), '12000');
    await boot(t);
    await openKhata(t);
    await t.tap(find.text('પેમેન્ટ મળ્યું'));
    await t.pumpAndSettle();
    await tapIt(t, find.text('ખોડિયાર').last);
    await tapIt(t, find.text('અડધા'));
    expect(find.text('₹6,000'), findsWidgets);
    expect(find.text('બાકી રહેશે'), findsOneWidget);

    await tapIt(t, find.text('બીજી રકમ'));
    for (final k in ['2', '5', '0', '0']) {
      await t.tap(find.text(k).last);
    }
    await t.pump();
    await t.tap(find.text('બરાબર'));
    await t.pumpAndSettle();
    expect(find.text('₹2,500'), findsWidgets);
    await tapIt(t, find.text('Cash - Jaydip'));
    await tapIt(t, find.text('સેવ કરો'));
    expect(sentPayment()['amount'], '2500');
    expect(sentPayment()['mode'], 'cash');
  });

  testWidgets('paying more than is due shows the extra as credit', (t) async {
    trip('ખોડિયાર', ago(5), '1000');
    await boot(t);
    await openKhata(t);
    await t.tap(find.text('પેમેન્ટ મળ્યું'));
    await t.pumpAndSettle();
    await tapIt(t, find.text('ખોડિયાર').last);
    await tapIt(t, find.text('બીજી રકમ'));
    for (final k in ['1', '5', '0', '0']) {
      await t.tap(find.text(k).last);
    }
    await t.pump();
    await t.tap(find.text('બરાબર'));
    await t.pumpAndSettle();
    expect(find.text('એડવાન્સ જમા'), findsOneWidget);
    expect(find.text('₹500'), findsOneWidget);
  });

  testWidgets('the sheet asks for the party, the amount and an account', (t) async {
    trip('ખોડિયાર', ago(5), '12000');
    await boot(t);
    await openKhata(t);
    await t.tap(find.text('પેમેન્ટ મળ્યું'));
    await t.pumpAndSettle();
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('પાર્ટી પસંદ કરો'), findsOneWidget);
    await tapIt(t, find.text('ખોડિયાર').last);
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('ખાતું પસંદ કરો'), findsOneWidget); // accounts exist, none chosen
    expect(find.text('પહેલા ખાતું ઉમેરો (વધુ → ખાતા)'), findsNothing);
    await tapIt(t, find.text('Cash - Jaydip'));
    await tapIt(t, find.text('સેવ કરો'));
    expect(api.where('POST', '/api/v1/payments'), hasLength(1));
  });

  testWidgets('a party with nothing due cannot be paid with "All"', (t) async {
    await boot(t);
    await openKhata(t);
    await t.tap(find.text('પેમેન્ટ મળ્યું'));
    await t.pumpAndSettle();
    await tapIt(t, find.text('ખોડિયાર').last);
    await tapIt(t, find.text('Cash - Jaydip'));
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('રકમ લખો'), findsOneWidget);
    expect(api.where('POST', '/api/v1/payments'), isEmpty);
  });

  testWidgets('delete a payment from the khata', (t) async {
    trip('ખોડિયાર', ago(5), '12000');
    api.db['payments']!.add({
      'id': 'p-1',
      'party_id': partyId('ખોડિયાર'),
      'trip_id': null,
      'account_id': api.db['accounts']!.first['id'],
      'amount': '5000',
      'mode': 'cash',
      'paid_on': ago(1),
    });
    await boot(t);
    await openKhata(t);
    await t.tap(find.text('ખોડિયાર'));
    await t.pumpAndSettle();
    expect(find.text('+₹5,000'), findsOneWidget);
    await tapIt(t, find.byTooltip('કાઢી નાખો'));
    expect(find.text('આ પેમેન્ટ કાઢી નાખવું છે?'), findsOneWidget);
    await tapIt(t, find.descendant(of: find.byType(AlertDialog), matching: find.text('કાઢી નાખો')));
    expect(api.where('DELETE', '/api/v1/payments/p-1'), hasLength(1));
    expect(find.text('+₹5,000'), findsNothing);
  });

  testWidgets('tapping a trip in the khata opens its details', (t) async {
    trip('ખોડિયાર', ago(5), '12000');
    await boot(t);
    await openKhata(t);
    await t.tap(find.text('ખોડિયાર'));
    await t.pumpAndSettle();
    await t.tap(find.text('સુરત → વાપી'));
    await t.pumpAndSettle();
    expect(find.text('ટ્રીપની વિગત'), findsOneWidget);
  });

  testWidgets('Home quick tiles open the trip form, the expense tab and the payment sheet', (t) async {
    trip('ખોડિયાર', ago(5), '12000');
    await boot(t);
    expect(find.text('₹12,000'), findsOneWidget); // amount to receive on Home

    await t.tap(find.text('નવી ટ્રીપ'));
    await t.pumpAndSettle();
    expect(find.text('પાછલી ટ્રીપ જેવી'), findsOneWidget);
    await t.tap(find.byIcon(Icons.arrow_back_rounded));
    await t.pumpAndSettle();

    await t.tap(find.text('પેમેન્ટ મળ્યું'));
    await t.pumpAndSettle();
    expect(find.text('કોણે આપ્યા'), findsOneWidget);
    Navigator.of(t.element(find.text('કોણે આપ્યા'))).pop(); // close the sheet
    await t.pumpAndSettle();

    await t.tap(find.text('બાકી લેવાના'));
    await t.pumpAndSettle();
    expect(find.text('કુલ બાકી લેવાના'), findsOneWidget);
  });

  testWidgets('English khata screen', (t) async {
    trip('ખોડિયાર', ago(3), '12000');
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: api, prefs: {'locale': 'en'}));
    await t.pumpAndSettle();
    await t.tap(find.text('Khata').first);
    await t.pumpAndSettle();
    expect(find.text('Total to receive'), findsOneWidget);
    expect(find.text('3 days old'), findsOneWidget);
    expect(find.text('Payment received'), findsOneWidget);
  });
}
