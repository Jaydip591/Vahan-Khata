import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vahan_khata/core/network/network_errors.dart';
import 'package:vahan_khata/core/network/response_cache.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

void main() {
  setUpAll(loadAppFonts);

  late FakeApi api;

  setUp(() {
    api = FakeApi();
    api.addVehicle('Eicher 1', 'GJ05 AB 1234');
    api.addParty('ખોડિયાર');
    api.addAccount('Cash - Jaydip');
  });

  Future<void> boot(WidgetTester t, {Map<String, Object> prefs = const {}}) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(await appWith(FakeAuthRepository(session: true), api: api, prefs: prefs));
    await t.pumpAndSettle();
  }

  Future<void> press(WidgetTester t, String digits) async {
    for (final k in digits.split('')) {
      await t.tap(find.text(k).last);
    }
    await t.pump();
  }

  /// Opens the Toll sheet while online (so vehicles load), goes offline, saves ₹340.
  Future<void> saveTollOffline(WidgetTester t) async {
    await t.tap(find.text('ખર્ચ').first);
    await t.pumpAndSettle();
    await t.tap(find.text('ટોલ').first);
    await t.pumpAndSettle();
    await tapIt(t, find.text('Eicher 1'));
    await press(t, '340');
    api.offline = true;
    await tapIt(t, find.text('સેવ કરો'));
    await t.pump(const Duration(seconds: 5)); // let the snackbar go
    await t.pumpAndSettle();
  }

  Future<void> endTest(WidgetTester t) async {
    await t.pumpWidget(const SizedBox()); // closes the app so the retry timer stops
  }

  test('a failed connection is told apart from a refusal', () {
    DioException e(DioExceptionType type, [int? code]) => DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: type,
          response: code == null ? null : Response(requestOptions: RequestOptions(path: '/x'), statusCode: code),
        );
    expect(isNetworkProblem(e(DioExceptionType.connectionError)), isTrue);
    expect(isNetworkProblem(e(DioExceptionType.connectionTimeout)), isTrue);
    expect(isNetworkProblem(e(DioExceptionType.badResponse, 503)), isTrue);
    expect(isNetworkProblem(e(DioExceptionType.badResponse, 422)), isFalse);
    expect(isNetworkProblem(e(DioExceptionType.badResponse, 409)), isFalse);
    expect(isNetworkProblem(StateError('x')), isFalse);
  });

  test('the cache answers a GET only when there is no connection', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final dio = Dio(BaseOptions(baseUrl: 'http://test'))
      ..httpClientAdapter = api
      ..interceptors.add(ResponseCache(prefs));
    final online = await dio.get('/api/v1/vehicles');
    expect((online.data as List).single['name'], 'Eicher 1');

    api.offline = true;
    final cached = await dio.get('/api/v1/vehicles');
    expect((cached.data as List).single['name'], 'Eicher 1');
    expect(cached.extra['fromCache'], isTrue);

    expect(() => dio.get('/api/v1/parties'), throwsA(isA<DioException>())); // never loaded
    await ResponseCache(prefs).clear();
    expect(() => dio.get('/api/v1/vehicles'), throwsA(isA<DioException>()));
  });

  testWidgets('offline: an expense is kept on the phone and shown as not sent', (t) async {
    await boot(t);
    await saveTollOffline(t);
    expect(api.db['expenses'], isEmpty);
    expect(find.text('1 એન્ટ્રી મોકલવાની બાકી'), findsOneWidget); // strip above the tab bar
    expect(find.text('મોકલવાની બાકી'), findsOneWidget); // tile in the Kharcha list
    expect(find.text('₹340'), findsWidgets);
    await endTest(t);
  });

  testWidgets('when the internet is back, Send now sends it once with the same id', (t) async {
    await boot(t);
    await saveTollOffline(t);
    final queuedId = (api.where('POST', '/api/v1/expenses').first.data as Map)['id'];

    api.offline = false;
    await tapIt(t, find.text('1 એન્ટ્રી મોકલવાની બાકી'));
    expect(find.text('Eicher 1'), findsOneWidget);
    await tapIt(t, find.text('હમણાં મોકલો'));

    expect(api.db['expenses']!.length, 1);
    expect(api.db['expenses']!.single['id'], queuedId);
    expect(find.text('બધું મોકલાઈ ગયું'), findsOneWidget);
    await tapIt(t, find.byIcon(Icons.arrow_back_rounded));
    expect(find.textContaining('એન્ટ્રી મોકલવાની બાકી'), findsNothing);

    // a second sync (e.g. a retry timer) has nothing left to send
    expect(api.where('POST', '/api/v1/expenses').length, 2); // one failed offline try + one real
    await endTest(t);
  });

  testWidgets('a trip saved offline keeps its advance and appears in the Trips tab', (t) async {
    await boot(t);
    await t.tap(find.text('નવી ટ્રીપ').first);
    await t.pumpAndSettle();
    expect(api.where('POST', '/api/v1/trips'), isEmpty);
    // Fill the form: vehicle/party/account are pre-selected (only one each).
    await tapIt(t, find.text('ક્યાંથી'));
    await t.enterText(find.byType(TextField).last, 'sur');
    await t.pumpAndSettle();
    await tapIt(t, find.text('સુરત').first);
    await tapIt(t, find.text('ક્યાં સુધી'));
    await t.enterText(find.byType(TextField).last, 'vap');
    await t.pumpAndSettle();
    await tapIt(t, find.text('વાપી').first);
    await tapIt(t, find.byIcon(Icons.add_rounded).first); // bhada stepper
    api.offline = true;
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.text('ઇન્ટરનેટ નથી. એન્ટ્રી ફોનમાં સાચવી, નેટ આવતાં મોકલાશે.'), findsOneWidget);
    expect(find.text('1 એન્ટ્રી મોકલવાની બાકી'), findsOneWidget);
    await tapIt(t, find.text('ટ્રીપ').first);
    expect(find.text('સુરત → વાપી'), findsOneWidget);
    expect(find.text('મોકલવાની બાકી'), findsOneWidget);
    await endTest(t);
  });

  testWidgets('entries survive closing the app and go out when it opens again', (t) async {
    await boot(t);
    await saveTollOffline(t);
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('outbox.items')!;
    await endTest(t);

    api.offline = false;
    await boot(t, prefs: {'outbox.items': saved});
    // the shell sends what was waiting as soon as it opens
    expect(api.db['expenses']!.length, 1);
    expect(find.textContaining('એન્ટ્રી મોકલવાની બાકી'), findsNothing);
    await endTest(t);
  });

  testWidgets('a refused entry is marked and can be deleted; nothing is lost silently', (t) async {
    await boot(t);
    await saveTollOffline(t);
    api.offline = false;
    api.failNext['POST /api/v1/expenses'] = 422;
    await tapIt(t, find.text('1 એન્ટ્રી મોકલવાની બાકી'));
    await tapIt(t, find.text('હમણાં મોકલો'));
    expect(api.db['expenses'], isEmpty);
    expect(find.text('સર્વરે ના પાડી'), findsOneWidget);
    expect(find.textContaining('સર્વરે આ એન્ટ્રી સ્વીકારી નથી'), findsOneWidget);

    await tapIt(t, find.text('કાઢી નાખો').last);
    await tapIt(t, find.text('કાઢી નાખો').last);
    expect(find.text('બધું મોકલાઈ ગયું'), findsOneWidget);
    await endTest(t);
  });

  testWidgets('a real server refusal while online is shown on the form, not queued', (t) async {
    await boot(t);
    await t.tap(find.text('ખર્ચ').first);
    await t.pumpAndSettle();
    await t.tap(find.text('ટોલ').first);
    await t.pumpAndSettle();
    await tapIt(t, find.text('Eicher 1'));
    await press(t, '340');
    api.failNext['POST /api/v1/expenses'] = 422;
    await tapIt(t, find.text('સેવ કરો'));
    expect(find.textContaining('એન્ટ્રી મોકલવાની બાકી'), findsNothing);
    expect(find.text('સેવ કરો'), findsOneWidget); // sheet still open
    await endTest(t);
  });

  testWidgets('logging out warns when entries are not sent yet', (t) async {
    await boot(t);
    await saveTollOffline(t);
    await tapIt(t, find.text('હોમ').last);
    await tapIt(t, find.byIcon(Icons.menu_rounded).first);
    await t.scrollUntilVisible(find.text('લોગઆઉટ'), 300, scrollable: find.byType(Scrollable).first);
    await tapIt(t, find.text('લોગઆઉટ'));
    expect(find.textContaining('1 એન્ટ્રી હજી મોકલાઈ નથી'), findsOneWidget);
    await endTest(t);
  });

  testWidgets('pickers still work offline from what was loaded earlier', (t) async {
    await boot(t);
    await t.tap(find.text('ખર્ચ').first);
    await t.pumpAndSettle();
    await t.tap(find.text('ટોલ').first); // loads vehicles online
    await t.pumpAndSettle();
    await t.tapAt(const Offset(10, 10)); // close the sheet
    await t.pumpAndSettle();
    api.offline = true;
    await t.tap(find.text('ટોલ').first);
    await t.pumpAndSettle();
    expect(find.text('Eicher 1'), findsOneWidget);
    await endTest(t);
  });
}
