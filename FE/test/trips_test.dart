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
  });

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: api));
    await t.pumpAndSettle();
  }

  Future<void> openTripsTab(WidgetTester t) async {
    await t.tap(find.text('ટ્રીપ').first);
    await t.pumpAndSettle();
  }

  Future<void> pickPlace(WidgetTester t, String label, String typed, String result) async {
    await tapIt(t, find.text(label).first);
    await t.enterText(find.byType(TextField).first, typed);
    await t.pump(const Duration(milliseconds: 700));
    await t.pumpAndSettle();
    await t.tap(find.text(result));
    await t.pumpAndSettle();
  }

  void seedBasics() {
    api.addVehicle('Eicher 1', 'GJ05 AB 1234');
    api.addVehicle('Bolero', 'GJ05 CD 5678', type: 'bolero');
    api.addParty('ખોડિયાર');
    api.addParty('રમેશભાઈ');
    api.addAccount('Cash - Jaydip');
    api.addAccount('UPI - ભાઈ', kind: 'upi');
  }

  Map<String, dynamic> vehicle(String name) =>
      api.db['vehicles']!.firstWhere((v) => v['name'] == name);
  Map<String, dynamic> party(String name) => api.db['parties']!.firstWhere((p) => p['name'] == name);
  Map<String, dynamic> account(String name) =>
      api.db['accounts']!.firstWhere((a) => a['name'] == name);

  testWidgets('empty trips tab shows the invitation and the New trip button', (t) async {
    await boot(t);
    await openTripsTab(t);
    expect(find.text('આ મહિને કોઈ ટ્રીપ નથી'), findsOneWidget);
    expect(find.text('નવી ટ્રીપ'), findsOneWidget);
  });

  testWidgets('create a trip with half advance, entirely by selection', (t) async {
    seedBasics();
    await boot(t);
    await openTripsTab(t);
    await t.tap(find.text('નવી ટ્રીપ'));
    await t.pumpAndSettle();

    await tapIt(t, find.text('Eicher 1'));
    await tapIt(t, find.text('ખોડિયાર'));
    await pickPlace(t, 'ક્યાંથી', 'sur', 'સુરત');
    await pickPlace(t, 'ક્યાં સુધી', 'vap', 'વાપી');

    // type the bhada on the keypad
    await tapIt(t, find.text('₹ 0'));
    for (final k in ['1', '2', '0', '0', '0']) {
      await t.tap(find.text(k).last);
    }
    await t.pump();
    await t.tap(find.text('બરાબર'));
    await t.pumpAndSettle();
    expect(find.text('₹12,000'), findsNWidgets(2)); // bhada, and the balance while no advance

    await tapIt(t, find.text('અડધું'));
    expect(find.text('₹6,000'), findsNWidgets(2)); // advance and balance
    await tapIt(t, find.text('UPI - ભાઈ'));
    await tapIt(t, find.text('ઓનલાઇન'));

    await tapIt(t, find.text('સેવ કરો'));

    final sent = api.where('POST', '/api/v1/trips').single.data as Map;
    expect(sent['vehicle_id'], vehicle('Eicher 1')['id']);
    expect(sent['party_id'], party('ખોડિયાર')['id']);
    expect(sent['from_place_id'], api.placeId('Surat'));
    expect(sent['to_place_id'], api.placeId('Vapi'));
    expect(sent['bhada'], '12000');
    expect(sent['trip_date'], today);
    expect(sent['advance'], {
      'amount': '6000',
      'mode': 'online',
      'account_id': account('UPI - ભાઈ')['id'],
    });
    // back on the list, the trip is there with a part-paid tag
    expect(find.text('સુરત → વાપી'), findsOneWidget);
    expect(find.text('₹12,000'), findsOneWidget);
    expect(find.textContaining('આંશિક'), findsOneWidget);
    expect(find.text('ટ્રીપ સેવ થઈ'), findsOneWidget);
  });

  testWidgets('advance chips and the steppers keep bhada, advance and balance in step', (t) async {
    seedBasics();
    await boot(t);
    await openTripsTab(t);
    await t.tap(find.text('નવી ટ્રીપ'));
    await t.pumpAndSettle();
    await tapIt(t, find.byTooltip('+500'));
    expect(find.text('₹500'), findsNWidgets(2)); // bhada and balance
    await tapIt(t, find.text('પૂરું'));
    expect(find.text('₹500'), findsNWidgets(2)); // bhada and advance
    expect(find.text('₹0'), findsOneWidget); // balance
    await tapIt(t, find.byTooltip('+500'));
    expect(find.text('₹1,000'), findsNWidgets(2)); // advance follows the bhada
    await tapIt(t, find.byTooltip('-500'));
    expect(find.text('₹500'), findsNWidgets(2));
    await tapIt(t, find.text('કંઈ નહીં'));
    expect(find.text('₹0'), findsOneWidget); // advance
    expect(find.text('કેવી રીતે મળ્યું'), findsNothing); // no account questions without advance
  });

  testWidgets('a quick route chip fills both places and the last bhada', (t) async {
    seedBasics();
    api.routes = [
      {
        'from_place': {'id': api.placeId('Surat'), 'name_en': 'Surat', 'name_gu': 'સુરત'},
        'to_place': {'id': api.placeId('Vapi'), 'name_en': 'Vapi', 'name_gu': 'વાપી'},
        'trips': 3,
        'last_bhada': '12500.00',
      }
    ];
    await boot(t);
    await openTripsTab(t);
    await t.tap(find.text('નવી ટ્રીપ'));
    await t.pumpAndSettle();
    await tapIt(t, find.text('સુરત → વાપી'));
    expect(find.text('₹12,500'), findsNWidgets(2)); // bhada, and the balance while no advance
    await tapIt(t, find.text('Eicher 1'));
    await tapIt(t, find.text('ખોડિયાર'));
    await tapIt(t, find.text('કંઈ નહીં'));
    await tapIt(t, find.text('સેવ કરો'));
    final sent = api.where('POST', '/api/v1/trips').single.data as Map;
    expect(sent['from_place_id'], api.placeId('Surat'));
    expect(sent['bhada'], '12500');
    expect(sent.containsKey('advance'), isFalse);
  });

  testWidgets('swap exchanges from and to', (t) async {
    seedBasics();
    api.routes = [
      {
        'from_place': {'id': api.placeId('Surat'), 'name_en': 'Surat', 'name_gu': 'સુરત'},
        'to_place': {'id': api.placeId('Vapi'), 'name_en': 'Vapi', 'name_gu': 'વાપી'},
        'trips': 1,
        'last_bhada': '9000',
      }
    ];
    await boot(t);
    await openTripsTab(t);
    await t.tap(find.text('નવી ટ્રીપ'));
    await t.pumpAndSettle();
    await tapIt(t, find.text('સુરત → વાપી'));
    await tapIt(t, find.byIcon(Icons.swap_horiz_rounded));
    await tapIt(t, find.text('Eicher 1'));
    await tapIt(t, find.text('ખોડિયાર'));
    await tapIt(t, find.text('કંઈ નહીં'));
    await tapIt(t, find.text('સેવ કરો'));
    final sent = api.where('POST', '/api/v1/trips').single.data as Map;
    expect(sent['from_place_id'], api.placeId('Vapi'));
    expect(sent['to_place_id'], api.placeId('Surat'));
  });

  testWidgets('saving explains what is missing, one thing at a time', (t) async {
    seedBasics();
    await boot(t);
    await openTripsTab(t);
    await t.tap(find.text('નવી ટ્રીપ'));
    await t.pumpAndSettle();

    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('ગાડી પસંદ કરો'), findsOneWidget);
    await tapIt(t, find.text('Eicher 1'));
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('પાર્ટી પસંદ કરો'), findsOneWidget);
    await tapIt(t, find.text('ખોડિયાર'));
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('ક્યાંથી અને ક્યાં સુધી પસંદ કરો'), findsOneWidget);
    await pickPlace(t, 'ક્યાંથી', 'sur', 'સુરત');
    await pickPlace(t, 'ક્યાં સુધી', 'vap', 'વાપી');
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('રકમ લખો'), findsOneWidget);
    expect(api.where('POST', '/api/v1/trips'), isEmpty);
  });

  testWidgets('an advance needs an account', (t) async {
    api.addVehicle('Eicher 1', 'GJ05 AB 1234');
    api.addParty('ખોડિયાર');
    await boot(t); // no accounts exist
    await openTripsTab(t);
    await t.tap(find.text('નવી ટ્રીપ'));
    await t.pumpAndSettle();
    await pickPlace(t, 'ક્યાંથી', 'sur', 'સુરત');
    await pickPlace(t, 'ક્યાં સુધી', 'vap', 'વાપી');
    await tapIt(t, find.byTooltip('+500'));
    await tapIt(t, find.text('પૂરું'));
    expect(find.text('પહેલા ખાતું ઉમેરો (વધુ → ખાતા)'), findsOneWidget);
    await tapIt(t, find.text('સેવ કરો'));
    expect(api.where('POST', '/api/v1/trips'), isEmpty);
  });

  testWidgets('the only vehicle, party and account are pre-selected', (t) async {
    api.addVehicle('Eicher 1', 'GJ05 AB 1234');
    api.addParty('ખોડિયાર');
    api.addAccount('Cash - Jaydip');
    await boot(t);
    await openTripsTab(t);
    await t.tap(find.text('નવી ટ્રીપ'));
    await t.pumpAndSettle();
    await pickPlace(t, 'ક્યાંથી', 'sur', 'સુરત');
    await pickPlace(t, 'ક્યાં સુધી', 'vap', 'વાપી');
    await tapIt(t, find.byTooltip('+500'));
    await tapIt(t, find.text('પૂરું'));
    await tapIt(t, find.text('સેવ કરો'));
    final sent = api.where('POST', '/api/v1/trips').single.data as Map;
    expect(sent['vehicle_id'], vehicle('Eicher 1')['id']);
    expect(sent['advance']['account_id'], account('Cash - Jaydip')['id']);
  });

  testWidgets('the next trip starts with the vehicle and party used last', (t) async {
    seedBasics();
    await boot(t);
    await openTripsTab(t);
    await t.tap(find.text('નવી ટ્રીપ'));
    await t.pumpAndSettle();
    await tapIt(t, find.text('Bolero'));
    await tapIt(t, find.text('રમેશભાઈ'));
    await pickPlace(t, 'ક્યાંથી', 'raj', 'રાજકોટ');
    await pickPlace(t, 'ક્યાં સુધી', 'sur', 'સુરત');
    await tapIt(t, find.byTooltip('+500'));
    await tapIt(t, find.text('સેવ કરો'));
    await t.pump(const Duration(seconds: 5)); // let the "saved" snackbar go away
    await t.pumpAndSettle();

    await t.tap(find.text('નવી ટ્રીપ'));
    await t.pumpAndSettle();
    await pickPlace(t, 'ક્યાંથી', 'vap', 'વાપી');
    await pickPlace(t, 'ક્યાં સુધી', 'sur', 'સુરત');
    await tapIt(t, find.byTooltip('+500'));
    await tapIt(t, find.text('સેવ કરો'));
    final second = api.where('POST', '/api/v1/trips').last.data as Map;
    expect(second['vehicle_id'], vehicle('Bolero')['id']);
    expect(second['party_id'], party('રમેશભાઈ')['id']);
  });

  testWidgets('same as last trip copies vehicle, party, route and bhada', (t) async {
    seedBasics();
    api.addTrip(
        vehicleId: vehicle('Bolero')['id'] as String,
        partyId: party('રમેશભાઈ')['id'] as String,
        from: 'Rajkot',
        to: 'Surat',
        date: today,
        bhada: '18000');
    await boot(t);
    await openTripsTab(t);
    await t.tap(find.text('નવી ટ્રીપ'));
    await t.pumpAndSettle();
    await tapIt(t, find.text('પાછલી ટ્રીપ જેવી'));
    expect(find.text('₹18,000'), findsNWidgets(2)); // bhada, and the balance while no advance
    await tapIt(t, find.text('કંઈ નહીં'));
    await tapIt(t, find.text('સેવ કરો'));
    final sent = api.where('POST', '/api/v1/trips').single.data as Map;
    expect(sent['vehicle_id'], vehicle('Bolero')['id']);
    expect(sent['party_id'], party('રમેશભાઈ')['id']);
    expect(sent['from_place_id'], api.placeId('Rajkot'));
    expect(sent['bhada'], '18000');
  });

  testWidgets('trip detail: amounts, close, reopen and delete', (t) async {
    seedBasics();
    api.addTrip(
        vehicleId: vehicle('Eicher 1')['id'] as String,
        partyId: party('ખોડિયાર')['id'] as String,
        from: 'Surat',
        to: 'Vapi',
        date: today);
    await boot(t);
    await openTripsTab(t);
    expect(find.textContaining('બાકી ₹12,000'), findsOneWidget);
    await t.tap(find.text('સુરત → વાપી'));
    await t.pumpAndSettle();
    expect(find.text('ટ્રીપની વિગત'), findsOneWidget);
    expect(find.text('ખોડિયાર · Eicher 1 (GJ05 AB 1234)'), findsOneWidget);

    await tapIt(t, find.text('ટ્રીપ પૂરી કરો'));
    expect(api.where('PATCH', '/api/v1/trips/${api.db['trips']!.first['id']}').single.data,
        {'status': 'closed'});
    expect(find.text('ફરી ચાલુ કરો'), findsOneWidget);
    await tapIt(t, find.text('ફરી ચાલુ કરો'));
    expect(find.text('ટ્રીપ પૂરી કરો'), findsOneWidget);

    await tapIt(t, find.byTooltip('કાઢી નાખો'));
    expect(find.text('કાઢી નાખવું છે?'), findsOneWidget);
    await tapIt(t, find.descendant(of: find.byType(AlertDialog), matching: find.text('કાઢી નાખો')));
    expect(find.text('આ મહિને કોઈ ટ્રીપ નથી'), findsOneWidget);
  });

  testWidgets('editing a trip changes the bhada and never touches the advance', (t) async {
    seedBasics();
    api.addTrip(
        vehicleId: vehicle('Eicher 1')['id'] as String,
        partyId: party('ખોડિયાર')['id'] as String,
        from: 'Surat',
        to: 'Vapi',
        date: today);
    await boot(t);
    await openTripsTab(t);
    await t.tap(find.text('સુરત → વાપી'));
    await t.pumpAndSettle();
    await tapIt(t, find.text('ટ્રીપ સુધારો'));
    expect(find.text('ટ્રીપ સુધારો'), findsWidgets);
    expect(find.textContaining('એડવાન્સ અહીં બદલાતું નથી'), findsOneWidget);
    expect(find.text('₹12,000'), findsOneWidget);
    await tapIt(t, find.byTooltip('+500'));
    await tapIt(t, find.text('સેવ કરો'));
    final id = api.db['trips']!.first['id'];
    final body = api.where('PATCH', '/api/v1/trips/$id').single.data as Map;
    expect(body['bhada'], '12500');
    expect(body.containsKey('advance'), isFalse);
    expect(find.text('₹12,500'), findsNWidgets(2)); // detail shows the new bhada and the balance
  });

  testWidgets('month arrows move between months', (t) async {
    seedBasics();
    api.addTrip(
        vehicleId: vehicle('Eicher 1')['id'] as String,
        partyId: party('ખોડિયાર')['id'] as String,
        from: 'Surat',
        to: 'Vapi',
        date: today);
    await boot(t);
    await openTripsTab(t);
    expect(find.text('સુરત → વાપી'), findsOneWidget);
    await t.tap(find.byTooltip('આવતો મહિનો'));
    await t.pumpAndSettle();
    expect(find.text('સુરત → વાપી'), findsNothing);
    expect(find.text('આ મહિને કોઈ ટ્રીપ નથી'), findsOneWidget);
    await t.tap(find.byTooltip('પાછલો મહિનો'));
    await t.pumpAndSettle();
    expect(find.text('સુરત → વાપી'), findsOneWidget);
  });

  testWidgets('English app shows English place names and labels', (t) async {
    seedBasics();
    api.addTrip(
        vehicleId: vehicle('Eicher 1')['id'] as String,
        partyId: party('ખોડિયાર')['id'] as String,
        from: 'Surat',
        to: 'Vapi',
        date: today);
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: api, prefs: {'locale': 'en'}));
    await t.pumpAndSettle();
    await t.tap(find.text('Trips').first);
    await t.pumpAndSettle();
    expect(find.text('Surat → Vapi'), findsOneWidget);
    expect(find.text('New trip'), findsOneWidget);
  });
}
