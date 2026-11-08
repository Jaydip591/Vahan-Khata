import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vahan_khata/core/network/api_client.dart';
import 'package:vahan_khata/core/provider_retry.dart';
import 'package:vahan_khata/core/providers.dart';
import 'package:vahan_khata/core/storage/token_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vahan_khata/features/pickers/party_chips.dart';
import 'package:vahan_khata/features/pickers/vehicle_chips.dart';
import 'package:vahan_khata/features/places/data/place.dart';
import 'package:vahan_khata/features/places/presentation/place_picker.dart';
import 'package:vahan_khata/features/parties/data/party.dart';
import 'package:vahan_khata/features/vehicles/data/vehicle.dart';
import 'package:vahan_khata/l10n/app_localizations.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

void main() {
  setUpAll(loadAppFonts);

  late FakeApi api;
  Place? picked;

  Future<void> host(WidgetTester t, Widget Function(BuildContext) body, {String lang = 'gu'}) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    await t.pumpWidget(ProviderScope(
      retry: noAutoRetry,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sp),
        apiClientProvider.overrideWithValue(ApiClient(
          baseUrl: 'http://test',
          storage: TokenStorage(),
          onSessionExpired: () {},
          adapter: api,
        )),
      ],
      child: MaterialApp(
        theme: ThemeData(fontFamily: 'NotoSansGujarati'),
        locale: Locale(lang),
        localizationsDelegates: AppL10n.localizationsDelegates,
        supportedLocales: AppL10n.supportedLocales,
        home: Scaffold(body: Builder(builder: body)),
      ),
    ));
    await t.pumpAndSettle();
  }

  Future<void> openPicker(WidgetTester t, {String lang = 'gu'}) async {
    picked = null;
    await host(
      t,
      (c) => Center(
        child: ElevatedButton(
          onPressed: () async => picked = await showPlacePicker(c, title: 'ક્યાંથી'),
          child: const Text('open'),
        ),
      ),
      lang: lang,
    );
    await t.tap(find.text('open'));
    await t.pumpAndSettle();
  }

  Future<void> type(WidgetTester t, String text) async {
    await t.enterText(find.byType(TextField).first, text);
    await t.pump(const Duration(milliseconds: 700));
    await t.pumpAndSettle();
  }

  setUp(() => api = FakeApi());

  group('place picker', () {
    testWidgets('shows popular places in Gujarati with the English name underneath', (t) async {
      await openPicker(t);
      expect(find.text('વધુ વપરાતા'), findsOneWidget);
      expect(find.text('સુરત'), findsOneWidget);
      expect(find.text('Surat'), findsOneWidget);
    });

    testWidgets('typing English finds the Gujarati place and tapping returns it', (t) async {
      await openPicker(t);
      await type(t, 'sur');
      expect(find.text('સુરત'), findsOneWidget);
      expect(find.text('સુરેન્દ્રનગર'), findsOneWidget);
      expect(find.text('રાજકોટ'), findsNothing);
      await t.tap(find.text('સુરત'));
      await t.pumpAndSettle();
      expect(picked?.nameEn, 'Surat');
      expect(picked?.nameGu, 'સુરત');
    });

    testWidgets('typing Gujarati works too', (t) async {
      await openPicker(t);
      await type(t, 'રાજ');
      expect(find.text('રાજકોટ'), findsOneWidget);
    });

    testWidgets('no add card when the typed name already exists', (t) async {
      await openPicker(t);
      await type(t, 'surat');
      expect(find.textContaining('ઉમેરો'), findsNothing);
    });

    testWidgets('unknown English name offers Gujarati spellings and saves the chosen one', (t) async {
      await openPicker(t);
      await type(t, 'mundra');
      expect(find.text('“Mundra” ઉમેરો'), findsOneWidget);
      expect(find.text('મુન્દ્રા'), findsOneWidget);
      await t.tap(find.text('મુન્દ્રા'));
      await t.pumpAndSettle();
      expect(api.where('POST', '/api/v1/places').single.data,
          {'name_en': 'Mundra', 'name_gu': 'મુન્દ્રા'});
      expect(picked?.nameGu, 'મુન્દ્રા');
    });

    testWidgets('if no spelling can be found the user types the Gujarati name', (t) async {
      await openPicker(t);
      await type(t, 'zzzq');
      expect(find.text('ગુજરાતીમાં નામ લખો'), findsOneWidget);
      await t.enterText(find.byType(TextField).last, 'ઝઝક');
      await t.pump();
      await t.tap(find.byIcon(Icons.check_rounded));
      await t.pumpAndSettle();
      expect(api.where('POST', '/api/v1/places').single.data, {'name_en': 'Zzzq', 'name_gu': 'ઝઝક'});
      expect(picked?.nameEn, 'Zzzq');
    });

    testWidgets('a name typed in Gujarati is added as is', (t) async {
      await openPicker(t);
      await type(t, 'ઉંમરા');
      await t.tap(find.text('ઉંમરા').last);
      await t.pumpAndSettle();
      expect(api.where('POST', '/api/v1/places').single.data, {'name_en': 'ઉંમરા', 'name_gu': 'ઉંમરા'});
    });

    testWidgets('works offline for transliteration: server error gives the manual fallback', (t) async {
      await openPicker(t);
      api.failNext['GET /api/v1/places/transliterate'] = 500;
      await type(t, 'mundra');
      expect(find.text('ગુજરાતીમાં નામ લખો'), findsOneWidget);
    });

    testWidgets('English app language shows English names first', (t) async {
      await openPicker(t, lang: 'en');
      expect(find.text('Surat'), findsOneWidget);
      expect(find.text('સુરત'), findsOneWidget);
    });
  });

  group('chip pickers', () {
    testWidgets('vehicle chips show names and report the tapped vehicle', (t) async {
      api.addVehicle('Eicher 1', 'GJ05 AB 1234');
      api.addVehicle('Bolero', 'GJ05 CD 5678', type: 'bolero');
      Vehicle? chosen;
      String? selected = 'id-5';
      await host(
        t,
        (c) => StatefulBuilder(
          builder: (c, set) => VehicleChips(
            selectedId: selected,
            onChanged: (v) => set(() {
              chosen = v;
              selected = v.id;
            }),
          ),
        ),
      );
      expect(find.text('Eicher 1'), findsOneWidget);
      await t.tap(find.text('Bolero'));
      await t.pumpAndSettle();
      expect(chosen?.number, 'GJ05 CD 5678');
    });

    testWidgets('party chips can show an add chip', (t) async {
      api.addParty('ખોડિયાર');
      Party? chosen;
      var added = false;
      await host(
        t,
        (c) => PartyChips(selectedId: null, onChanged: (p) => chosen = p, onAdd: () => added = true),
      );
      await t.tap(find.text('ખોડિયાર'));
      await t.tap(find.text('+'));
      expect(chosen?.name, 'ખોડિયાર');
      expect(added, isTrue);
    });

    testWidgets('a failed load shows a retry button', (t) async {
      api.failNext['GET /api/v1/vehicles'] = 500;
      await host(t, (c) => VehicleChips(selectedId: null, onChanged: (_) {}));
      expect(find.text('ફરી પ્રયત્ન'), findsOneWidget);
      api.addVehicle('Eicher 1', 'GJ05 AB 1234');
      await t.tap(find.text('ફરી પ્રયત્ન'));
      await t.pumpAndSettle();
      expect(find.text('Eicher 1'), findsOneWidget);
    });
  });
}
