import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

void main() {
  setUpAll(loadAppFonts);

  late FakeApi api;

  Future<void> boot(WidgetTester t, {Map<String, Object> prefs = const {}}) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: api, prefs: prefs));
    await t.pumpAndSettle();
  }

  Future<void> openMore(WidgetTester t, String tile) async {
    await t.tap(find.byIcon(Icons.menu_rounded));
    await t.pumpAndSettle();
    await t.tap(find.text(tile));
    await t.pumpAndSettle();
  }

  Finder field(int i) => find.byType(TextFormField).at(i);
  String firstVehicleId() => api.db['vehicles']!.first['id'] as String;

  setUp(() => api = FakeApi());

  testWidgets('More menu lists all master screens', (t) async {
    await boot(t);
    await t.tap(find.byIcon(Icons.menu_rounded));
    await t.pumpAndSettle();
    for (final label in ['ગાડીઓ', 'ડ્રાઇવરો', 'પાર્ટીઓ', 'ખાતા (Cash / Bank)', 'યુઝર્સ']) {
      expect(find.text(label), findsOneWidget);
    }
  });

  group('vehicles', () {
    testWidgets('empty state invites the user to add one', (t) async {
      await boot(t);
      await openMore(t, 'ગાડીઓ');
      expect(find.text('હજી કોઈ ગાડી નથી'), findsOneWidget);
      expect(find.text('નવી ગાડી ઉમેરો'), findsOneWidget);
    });

    testWidgets('list shows name and number only', (t) async {
      api.addVehicle('Eicher 1', 'GJ05 AB 1234');
      await boot(t);
      await openMore(t, 'ગાડીઓ');
      expect(find.text('Eicher 1'), findsOneWidget);
      expect(find.text('GJ05 AB 1234'), findsOneWidget);
    });

    testWidgets('add: name is filled automatically from the chosen type, then saved', (t) async {
      await boot(t);
      await openMore(t, 'ગાડીઓ');
      await t.tap(find.text('નવી ગાડી ઉમેરો'));
      await t.pumpAndSettle();

      expect(find.widgetWithText(TextFormField, 'Eicher 1'), findsOneWidget);
      await t.tap(find.text('બોલેરો'));
      await t.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Bolero 1'), findsOneWidget);

      await t.enterText(field(1), 'gj05 cd 5678');
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();

      final sent = api.where('POST', '/api/v1/vehicles').single.data as Map;
      expect(sent['vehicle_type'], 'bolero');
      expect(sent['name'], 'Bolero 1');
      expect(sent['number'], 'GJ05 CD 5678');
      expect(sent['insurance_exp'], isNull);
      // back on the list, showing the new vehicle
      expect(find.text('Bolero 1'), findsOneWidget);
      expect(find.text('GJ05 CD 5678'), findsOneWidget);
    });

    testWidgets('a name the user typed is not overwritten when the type changes', (t) async {
      await boot(t);
      await openMore(t, 'ગાડીઓ');
      await t.tap(find.text('નવી ગાડી ઉમેરો'));
      await t.pumpAndSettle();
      await t.enterText(field(0), 'Lal Gaadi');
      await t.tap(find.text('ટ્રક'));
      await t.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, 'Lal Gaadi'), findsOneWidget);
    });

    testWidgets('invalid or empty number is rejected before calling the server', (t) async {
      await boot(t);
      await openMore(t, 'ગાડીઓ');
      await t.tap(find.text('નવી ગાડી ઉમેરો'));
      await t.pumpAndSettle();
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      expect(find.text('આ ખાનું ભરવું જરૂરી છે'), findsOneWidget);
      await t.enterText(field(1), '12');
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      expect(find.text('સાચો ગાડી નંબર લખો'), findsOneWidget);
      expect(api.where('POST', '/api/v1/vehicles'), isEmpty);
    });

    testWidgets('duplicate number from the server shows a friendly message', (t) async {
      await boot(t);
      await openMore(t, 'ગાડીઓ');
      await t.tap(find.text('નવી ગાડી ઉમેરો'));
      await t.pumpAndSettle();
      await t.enterText(field(1), 'GJ05 AB 1234');
      api.failNext['POST /api/v1/vehicles'] = 409;
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      expect(find.text('આ પહેલેથી લિસ્ટમાં છે'), findsOneWidget);
      expect(find.text('સેવ કરો'), findsOneWidget); // still on the form
    });

    testWidgets('edit sends the change, delete asks first', (t) async {
      api.addVehicle('Eicher 1', 'GJ05 AB 1234');
      final vehicleId = firstVehicleId();
      await boot(t);
      await openMore(t, 'ગાડીઓ');
      await t.tap(find.text('Eicher 1'));
      await t.pumpAndSettle();
      expect(find.text('ગાડી સુધારો'), findsOneWidget);
      await t.enterText(field(0), 'Eicher Red');
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      expect((api.where('PATCH', '/api/v1/vehicles/$vehicleId').single.data as Map)['name'], 'Eicher Red');
      expect(find.text('Eicher Red'), findsOneWidget);

      await t.tap(find.text('Eicher Red'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('કાઢી નાખો'));
      await t.pumpAndSettle();
      expect(find.text('કાઢી નાખવું છે?'), findsOneWidget);
      await t.tap(find.text('રદ કરો'));
      await t.pumpAndSettle();
      expect(api.where('DELETE', '/api/v1/vehicles/$vehicleId'), isEmpty);
      await t.tap(find.byTooltip('કાઢી નાખો'));
      await t.pumpAndSettle();
      await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('કાઢી નાખો')));
      await t.pumpAndSettle();
      expect(api.where('DELETE', '/api/v1/vehicles/$vehicleId'), hasLength(1));
      expect(find.text('હજી કોઈ ગાડી નથી'), findsOneWidget);
    });

    testWidgets('document dates section opens and clearing is sent as null', (t) async {
      api.addVehicle('Eicher 1', 'GJ05 AB 1234');
      api.db['vehicles']!.first['puc_exp'] = '2027-03-05';
      await boot(t);
      await openMore(t, 'ગાડીઓ');
      await t.tap(find.text('Eicher 1'));
      await t.pumpAndSettle();
      expect(find.text('05/03/2027'), findsOneWidget); // opens by itself when a date exists
      await t.tap(find.byIcon(Icons.close_rounded));
      await t.pumpAndSettle();
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      expect((api.where('PATCH', '/api/v1/vehicles/${firstVehicleId()}').single.data as Map)['puc_exp'], isNull);
    });
  });

  group('parties, drivers, accounts, users', () {
    testWidgets('add party with payment cycle', (t) async {
      await boot(t);
      await openMore(t, 'પાર્ટીઓ');
      await t.tap(find.text('નવી પાર્ટી'));
      await t.pumpAndSettle();
      await t.enterText(field(0), 'ખોડિયાર ટ્રેડર્સ');
      await t.enterText(field(1), '98765 43210');
      await t.tap(find.text('10 દિવસે'));
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      final sent = api.where('POST', '/api/v1/parties').single.data as Map;
      expect(sent, {'name': 'ખોડિયાર ટ્રેડર્સ', 'phone': '98765 43210', 'payment_cycle': 'ten_days'});
      expect(find.text('ખોડિયાર ટ્રેડર્સ'), findsOneWidget);
    });

    testWidgets('duplicate party shows message', (t) async {
      await boot(t);
      await openMore(t, 'પાર્ટીઓ');
      await t.tap(find.text('નવી પાર્ટી'));
      await t.pumpAndSettle();
      await t.enterText(field(0), 'ABC');
      api.failNext['POST /api/v1/parties'] = 409;
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      expect(find.text('આ પહેલેથી લિસ્ટમાં છે'), findsOneWidget);
    });

    testWidgets('bad phone number is rejected', (t) async {
      await boot(t);
      await openMore(t, 'ડ્રાઇવરો');
      await t.tap(find.text('નવો ડ્રાઇવર'));
      await t.pumpAndSettle();
      await t.enterText(field(0), 'Ramesh');
      await t.enterText(field(1), '123');
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      expect(find.text('સાચો ફોન નંબર લખો'), findsOneWidget);
      expect(api.where('POST', '/api/v1/drivers'), isEmpty);
    });

    testWidgets('driver can be given a usual vehicle by tapping a chip', (t) async {
      api.addVehicle('Eicher 1', 'GJ05 AB 1234');
      await boot(t);
      await openMore(t, 'ડ્રાઇવરો');
      await t.tap(find.text('નવો ડ્રાઇવર'));
      await t.pumpAndSettle();
      await t.enterText(field(0), 'Ramesh');
      await t.tap(find.text('Eicher 1'));
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      final sent = api.where('POST', '/api/v1/drivers').single.data as Map;
      expect(sent['default_vehicle_id'], firstVehicleId());
      expect(sent['phone'], isNull);
    });

    testWidgets('account keeps the opening balance as an exact string', (t) async {
      await boot(t);
      await openMore(t, 'ખાતા (Cash / Bank)');
      await t.tap(find.text('નવું ખાતું'));
      await t.pumpAndSettle();
      await t.tap(find.text('UPI'));
      await t.enterText(field(0), 'UPI - ભાઈ');
      await t.enterText(field(1), '1500.50');
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      final sent = api.where('POST', '/api/v1/accounts').single.data as Map;
      expect(sent, {'name': 'UPI - ભાઈ', 'kind': 'upi', 'opening_balance': '1500.50'});
    });

    testWidgets('account rejects a balance with three decimals', (t) async {
      await boot(t);
      await openMore(t, 'ખાતા (Cash / Bank)');
      await t.tap(find.text('નવું ખાતું'));
      await t.pumpAndSettle();
      await t.enterText(field(0), 'Cash');
      await t.enterText(field(1), '1.234');
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      expect(find.text('વિગત તપાસો'), findsOneWidget);
      expect(api.where('POST', '/api/v1/accounts'), isEmpty);
    });

    testWidgets('create user needs a valid username and a 6+ character password', (t) async {
      await boot(t);
      await openMore(t, 'યુઝર્સ');
      await t.tap(find.text('નવો યુઝર'));
      await t.pumpAndSettle();
      await t.enterText(field(0), 'Ramesh Patel');
      await t.enterText(field(1), 'ab');
      await t.enterText(field(2), '123');
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      expect(find.text('3-32 અક્ષર: નાના અંગ્રેજી અક્ષર, આંકડા, . - _'), findsWidgets);
      expect(find.text('પાસવર્ડ ઓછામાં ઓછા 6 અક્ષરનો રાખો'), findsOneWidget);
      expect(api.where('POST', '/api/v1/users'), isEmpty);

      await t.enterText(field(1), 'RAMESH');
      await t.enterText(field(2), 'secret12');
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      final sent = api.where('POST', '/api/v1/users').single.data as Map;
      expect(sent, {'username': 'ramesh', 'name': 'Ramesh Patel', 'password': 'secret12'});
    });

    testWidgets('editing a user does not require a password and does not send one', (t) async {
      api.db['users']!.add({'id': 'u-9', 'username': 'ramesh', 'name': 'Ramesh', 'is_active': true});
      await boot(t);
      await openMore(t, 'યુઝર્સ');
      await t.tap(find.text('Ramesh'));
      await t.pumpAndSettle();
      await t.enterText(field(0), 'Ramesh Patel');
      await t.tap(find.text('સેવ કરો'));
      await t.pumpAndSettle();
      expect(api.where('PATCH', '/api/v1/users/u-9').single.data, {'name': 'Ramesh Patel'});
    });
  });

  testWidgets('screens switch to English with the language setting', (t) async {
    await boot(t, prefs: {'locale': 'en'});
    await openMore(t, 'Vehicles');
    expect(find.text('No vehicles yet'), findsOneWidget);
    expect(find.text('Add vehicle'), findsOneWidget);
  });
}
