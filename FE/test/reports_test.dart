import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vahan_khata/core/money.dart';

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
}
