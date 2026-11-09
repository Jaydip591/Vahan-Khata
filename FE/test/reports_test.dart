import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vahan_khata/core/money.dart';
import 'package:vahan_khata/core/month_names.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

void main() {
  setUpAll(loadAppFonts);

  late FakeApi api;

  setUp(() => api = FakeApi());

  Future<void> boot(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: api));
    await t.pumpAndSettle();
  }

  testWidgets('home shows the month profit, income, expense and vehicle profit', (t) async {
    await boot(t);
    expect(find.text('₹18,500'), findsWidgets); // hero profit + vehicle card
    expect(find.text('₹20,000'), findsOneWidget);
    expect(find.text('₹1,500'), findsOneWidget);
    expect(find.text('₹9,000'), findsOneWidget);
    expect(find.text('ગયા મહિને ₹4,300'), findsOneWidget);
    expect(find.text('Eicher 1'), findsOneWidget);
    final month = api.where('GET', '/api/v1/reports/summary').first.queryParameters['month'];
    expect(month, monthKey(DateTime.now()));
  });

  testWidgets('home month arrows load the previous month; next is blocked on the current month', (t) async {
    await boot(t);
    final now = DateTime.now();
    final prev = monthKey(DateTime(now.year, now.month - 1));
    await tapIt(t, find.byTooltip('પાછલો મહિનો').first);
    expect(api.where('GET', '/api/v1/reports/summary').any((c) => c.queryParameters['month'] == prev), isTrue);
    await tapIt(t, find.byTooltip('આવતો મહિનો').first);
    final next = find.byTooltip('આવતો મહિનો').first;
    expect(t.widget<IconButton>(find.ancestor(of: next, matching: find.byType(IconButton)).first).onPressed, isNull);
  });

  testWidgets('report tab shows vehicle profit with mileage, then each other tab', (t) async {
    await boot(t);
    await tapIt(t, find.text('રિપોર્ટ').last);
    expect(find.text('Eicher 1'), findsOneWidget);
    expect(find.text('GJ05 AB 1234'), findsOneWidget);
    expect(find.text('7.5 કિમી/લિટર'), findsOneWidget);
    expect(find.text('2 ટ્રીપ'), findsOneWidget);

    await tapIt(t, find.text('પાર્ટી'));
    expect(find.text('ખોડિયાર'), findsOneWidget);
    expect(find.text('₹16,000'), findsOneWidget);

    await tapIt(t, find.text('મહિના'));
    expect(find.text('₹4,300'), findsOneWidget);
    expect(find.text('₹18,500'), findsOneWidget);

    await tapIt(t, find.text('ખર્ચ').first);
    expect(find.text('ડીઝલ'), findsOneWidget);
    expect(find.text('ટોલ'), findsOneWidget);
    expect(find.text('67%'), findsOneWidget);
  });

  testWidgets('a failed report shows Retry and recovers', (t) async {
    api.failNext['GET /api/v1/reports/summary'] = 500;
    await boot(t);
    expect(find.text('ફરી પ્રયત્ન'), findsOneWidget);
    await tapIt(t, find.text('ફરી પ્રયત્ન'));
    expect(find.text('₹20,000'), findsOneWidget);
  });

  group('details', () {
    late String vid;
    late String today;

    setUp(() {
      today = dateKey(DateTime.now());
      api.addVehicle('Eicher 1', 'GJ05 AB 1234');
      api.addVehicle('Tempo 2', 'GJ05 CD 5678');
      api.addParty('ખોડિયાર');
      vid = api.db['vehicles']!.first['id'] as String;
      final other = api.db['vehicles']!.last['id'] as String;
      (api.reportData['vehicles']['vehicles'] as List)[0]['vehicle_id'] = vid;
      final pid = api.db['parties']!.first['id'] as String;
      api.addTrip(vehicleId: vid, partyId: pid, from: 'Surat', to: 'Vapi', date: today, bhada: '12000');
      api.addTrip(vehicleId: other, partyId: pid, from: 'Surat', to: 'Valsad', date: today, bhada: '7000');
      api.addExpense(
          vehicleId: vid, category: 'diesel', amount: '5520', date: today, liters: '60', rate: '92', odometer: 124350);
      api.addExpense(vehicleId: vid, category: 'toll', amount: '340', date: today);
      api.addExpense(vehicleId: other, category: 'diesel', amount: '4000', date: today, liters: '40', rate: '100');
    });

    testWidgets('a vehicle card opens its diesel log with date, liters, rate and odometer', (t) async {
      await boot(t);
      await tapIt(t, find.text('રિપોર્ટ').last);
      await tapIt(t, find.text('Eicher 1'));
      // opens on the diesel list
      expect(find.text('60 લિટર  ·  ₹92/લિટર  ·  124350 કિમી'), findsOneWidget);
      expect(find.text(formatDay(DateTime.now())), findsWidgets);
      expect(find.text('₹5,520'), findsWidgets);
      expect(find.text('₹340'), findsNothing); // toll is under "other expenses"
      expect(find.text('₹4,000'), findsNothing); // the other vehicle's diesel is not shown
      final sent = api.where('GET', '/api/v1/expenses').last.queryParameters;
      expect(sent['vehicle_id'], vid);
      expect(sent['month'], monthKey(DateTime.now()));

      await tapIt(t, find.text('બીજા ખર્ચ'));
      expect(find.text('₹340'), findsWidgets);
      expect(find.text('ટોલ'), findsOneWidget);

      await tapIt(t, find.text('ટ્રીપ').last);
      expect(find.textContaining('વાપી'), findsOneWidget);
      expect(find.textContaining('વલસાડ'), findsNothing);
    });

    testWidgets('a month in the Months tab opens month details with trips and all expenses', (t) async {
      await boot(t);
      await tapIt(t, find.text('રિપોર્ટ').last);
      await tapIt(t, find.text('મહિના'));
      await t.tap(find.text(monthLabel('gu', DateTime(2026, 11))).last); // card, not the switcher
      await t.pumpAndSettle();
      expect(find.text('મહિનાની વિગત'), findsOneWidget);
      await tapIt(t, find.text('ટ્રીપ').last);
      expect(find.textContaining('વાપી'), findsOneWidget);
      expect(find.textContaining('વલસાડ'), findsOneWidget);
      await tapIt(t, find.text('ખર્ચ').last);
      expect(find.text('ડીઝલ · Eicher 1'), findsOneWidget);
      expect(find.text('ડીઝલ · Tempo 2'), findsOneWidget);
      expect(find.text('ટોલ · Eicher 1'), findsOneWidget);
    });
  });
}
