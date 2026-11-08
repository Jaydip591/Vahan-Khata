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
    api.addVehicle('Bolero', 'GJ05 CD 5678', type: 'bolero');
    api.addAccount('Cash - Jaydip');
  });

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: api));
    await t.pumpAndSettle();
    await t.tap(find.text('ખર્ચ').first);
    await t.pumpAndSettle();
  }

  Future<void> press(WidgetTester t, String digits) async {
    for (final k in digits.split('')) {
      await t.tap(find.text(k).last);
    }
    await t.pump();
  }

  Future<void> openCategory(WidgetTester t, String label) async {
    await t.tap(find.text(label).first);
    await t.pumpAndSettle();
  }

  Map<String, dynamic> vehicle(String name) =>
      api.db['vehicles']!.firstWhere((v) => v['name'] == name);

  Map<String, dynamic> sent() => api.where('POST', '/api/v1/expenses').single.data as Map<String, dynamic>;

  testWidgets('the tab shows the six categories and an invitation when empty', (t) async {
    await boot(t);
    for (final c in ['ડીઝલ', 'ટોલ', 'રિપેર', 'ભથ્થું', 'ચલણ', 'બીજું']) {
      expect(find.text(c), findsOneWidget);
    }
    expect(find.text('આ મહિને કોઈ ખર્ચ નથી'), findsOneWidget);
  });

  testWidgets('toll: tap the tile, choose the vehicle, type the amount, save', (t) async {
    await boot(t);
    await openCategory(t, 'ટોલ');
    await tapIt(t, find.text('Eicher 1'));
    await press(t, '340');
    expect(find.text('₹340'), findsOneWidget);
    await tapIt(t, find.text('સેવ કરો'));

    expect(sent(), {
      'vehicle_id': vehicle('Eicher 1')['id'],
      'category': 'toll',
      'amount': '340',
      'expense_date': today,
      'account_id': null,
      'liters': null,
      'rate': null,
      'odometer': null,
      'repair_kind': null,
    });
    // back on the tab: the new expense is listed and totalled
    expect(find.text('₹340'), findsNWidgets(2)); // total card and the row
    expect(find.text('ખર્ચ સેવ થયો'), findsOneWidget);
  });

  testWidgets('diesel keeps liters, computed rate and odometer', (t) async {
    await boot(t);
    await openCategory(t, 'ડીઝલ');
    await tapIt(t, find.text('Bolero'));
    await press(t, '5520');
    await t.tap(find.text('લિટર'));
    await t.pump();
    await press(t, '60');
    await t.tap(find.text('ઓડોમીટર (કિમી)'));
    await t.pump();
    await press(t, '124350');
    await tapIt(t, find.text('સેવ કરો'));
    final body = sent();
    expect(body['category'], 'diesel');
    expect(body['vehicle_id'], vehicle('Bolero')['id']);
    expect(body['amount'], '5520');
    expect(body['liters'], '60');
    expect(body['rate'], '92.00');
    expect(body['odometer'], 124350);
  });

  testWidgets('liters accept a decimal point', (t) async {
    await boot(t);
    await openCategory(t, 'ડીઝલ');
    await tapIt(t, find.text('Eicher 1'));
    await press(t, '1000');
    await t.tap(find.text('લિટર'));
    await t.pump();
    await press(t, '45');
    await t.tap(find.text('.').last);
    await press(t, '5');
    await tapIt(t, find.text('સેવ કરો'));
    final body = sent();
    expect(body['liters'], '45.5');
    expect(body['rate'], '21.98');
  });

  testWidgets('repair: the kind can be chosen and un-chosen', (t) async {
    await boot(t);
    await openCategory(t, 'રિપેર');
    await tapIt(t, find.text('Eicher 1'));
    await tapIt(t, find.text('ટાયર'));
    await tapIt(t, find.text('ટાયર')); // tapping again clears it
    await tapIt(t, find.text('બેટરી'));
    await press(t, '4000');
    await tapIt(t, find.text('સેવ કરો'));
    expect(sent()['repair_kind'], 'battery');
    expect(sent()['category'], 'repair');
  });

  testWidgets('non-diesel categories do not show liters or odometer', (t) async {
    await boot(t);
    await openCategory(t, 'ભથ્થું');
    expect(find.text('લિટર'), findsNothing);
    expect(find.text('ઓડોમીટર (કિમી)'), findsNothing);
    expect(find.text('શું રિપેર કર્યું?'), findsNothing);
  });

  testWidgets('saving asks for the vehicle first, then the amount', (t) async {
    await boot(t);
    await openCategory(t, 'ચલણ');
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('ગાડી પસંદ કરો'), findsOneWidget);
    await tapIt(t, find.text('Eicher 1'));
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('રકમ લખો'), findsOneWidget);
    expect(api.where('POST', '/api/v1/expenses'), isEmpty);
  });

  testWidgets('an account can be chosen, and yesterday as the date', (t) async {
    await boot(t);
    await openCategory(t, 'બીજું');
    await tapIt(t, find.text('Eicher 1'));
    await press(t, '250');
    await tapIt(t, find.text('Cash - Jaydip'));
    await tapIt(t, find.text('ગઈકાલે'));
    await tapIt(t, find.text('સેવ કરો'));
    final yesterday = dateKey(DateTime.now().subtract(const Duration(days: 1)));
    expect(sent()['account_id'], api.db['accounts']!.first['id']);
    expect(sent()['expense_date'], yesterday);
  });

  testWidgets('the vehicle used last is pre-selected next time', (t) async {
    await boot(t);
    await openCategory(t, 'ટોલ');
    await tapIt(t, find.text('Bolero'));
    await press(t, '100');
    await tapIt(t, find.text('સેવ કરો'));
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    await openCategory(t, 'ટોલ');
    await press(t, '200'); // no vehicle tap this time
    await tapIt(t, find.text('સેવ કરો'));
    final second = api.where('POST', '/api/v1/expenses').last.data as Map;
    expect(second['vehicle_id'], vehicle('Bolero')['id']);
  });

  testWidgets('tap an expense to edit it', (t) async {
    api.db['expenses']!.add({
      'id': 'e-1',
      'vehicle_id': vehicle('Eicher 1')['id'],
      'trip_id': null,
      'account_id': null,
      'category': 'toll',
      'amount': '340',
      'expense_date': today,
      'liters': null,
      'rate': null,
      'odometer': null,
      'repair_kind': null,
    });
    await boot(t);
    await t.tap(find.text('Eicher 1 · ${formatDay(DateTime.now())}'));
    await t.pumpAndSettle();
    expect(find.text('₹340'), findsWidgets);
    await t.tap(find.byIcon(Icons.backspace_outlined));
    await t.pump();
    await press(t, '5');
    await tapIt(t, find.text('સેવ કરો'));
    final body = api.where('PATCH', '/api/v1/expenses/e-1').single.data as Map;
    expect(body['amount'], '345');
    expect(find.text('₹345'), findsWidgets);
  });

  testWidgets('delete asks first', (t) async {
    api.db['expenses']!.add({
      'id': 'e-1',
      'vehicle_id': vehicle('Eicher 1')['id'],
      'trip_id': null,
      'account_id': null,
      'category': 'toll',
      'amount': '340',
      'expense_date': today,
      'liters': null,
      'rate': null,
      'odometer': null,
      'repair_kind': null,
    });
    await boot(t);
    await t.tap(find.text('Eicher 1 · ${formatDay(DateTime.now())}'));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('કાઢી નાખો'));
    await t.pumpAndSettle();
    await t.tap(find.text('રદ કરો'));
    await t.pumpAndSettle();
    expect(api.where('DELETE', '/api/v1/expenses/e-1'), isEmpty);
    await t.tap(find.byTooltip('કાઢી નાખો'));
    await t.pumpAndSettle();
    await t.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('કાઢી નાખો')));
    await t.pumpAndSettle();
    expect(api.where('DELETE', '/api/v1/expenses/e-1'), hasLength(1));
    expect(find.text('આ મહિને કોઈ ખર્ચ નથી'), findsOneWidget);
  });

  testWidgets('server error is shown inside the sheet and nothing is lost', (t) async {
    await boot(t);
    await openCategory(t, 'ટોલ');
    await tapIt(t, find.text('Eicher 1'));
    await press(t, '100');
    api.failNext['POST /api/v1/expenses'] = 500;
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('કંઈક ખોટું થયું. ફરી પ્રયત્ન કરો'), findsOneWidget);
    expect(find.text('₹100'), findsOneWidget); // still typed
    await tapIt(t, find.text('સેવ કરો'));
    expect(api.where('POST', '/api/v1/expenses'), hasLength(2));
  });
}
