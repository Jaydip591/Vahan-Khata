import 'dart:convert';
import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vahan_khata/core/money.dart';
import 'package:vahan_khata/features/export/doc_pages.dart';
import 'package:vahan_khata/features/export/export_service.dart';
import 'package:vahan_khata/features/export/exporters.dart';
import 'package:vahan_khata/features/export/statement_doc.dart';
import 'package:vahan_khata/features/ledger/data/ledger.dart';
import 'package:vahan_khata/features/places/data/place.dart';
import 'package:vahan_khata/features/trips/data/trip.dart';
import 'package:vahan_khata/l10n/app_localizations_en.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

final t = AppL10nEn();
const surat = Place(id: 's', nameEn: 'Surat', nameGu: 'સુરત', isSeed: true);
const vapi = Place(id: 'v', nameEn: 'Vapi', nameGu: 'વાપી', isSeed: true);

/// A number cell read back from Excel (whole numbers come back as integers).
num numOf(Data? cell) {
  final v = cell!.value;
  return v is IntCellValue ? v.value : (v as DoubleCellValue).value;
}

PartyLedger ledger({int trips = 2}) => PartyLedger(
      partyId: 'p',
      name: 'Khodiyar Roadlines',
      phone: '9876543210',
      totalBhada: 12000.0 * trips,
      totalPaid: 15000,
      balance: 12000.0 * trips - 15000,
      trips: [
        for (var i = 0; i < trips; i++)
          LedgerTrip(
            id: 't$i',
            date: DateTime(2026, 11, 1 + i % 28),
            from: surat,
            to: vapi,
            vehicleName: 'Eicher',
            bhada: 12000,
            paid: i == 0 ? 12000 : 3000,
            due: i == 0 ? 0 : 9000,
            status: i == 0 ? PayStatus.paid : PayStatus.partial,
          ),
      ],
      payments: [
        LedgerPayment(id: 'a', amount: 3000, mode: 'cash', date: DateTime(2026, 11, 1), accountName: 'Cash - Jaydip', isAdvance: true),
        LedgerPayment(id: 'b', amount: 12000, mode: 'online', date: DateTime(2026, 11, 9), accountName: 'UPI - Bhai', isAdvance: false),
      ],
    );

void main() {
  setUpAll(loadAppFonts);

  group('statement document', () {
    test('party statement has the totals, every trip and every payment', () {
      final doc = partyStatementDoc(t, 'gu', ledger(), DateTime(2026, 11, 9));
      expect(doc.title, 'Party statement');
      expect(doc.subtitle, 'Khodiyar Roadlines  ·  9876543210');
      expect(doc.fileName, 'statement_Khodiyar_Roadlines_2026-11-09');
      expect(doc.summary.map((s) => s.value), [24000.0, 15000.0, 9000.0]);
      final trips = doc.tables[0];
      expect(trips.rows.length, 2);
      expect(trips.rows[0][1], 'સુરત → વાપી'); // route in the chosen language
      expect(trips.totals, [null, null, null, 24000.0, 15000.0, 9000.0]);
      final pays = doc.tables[1];
      expect(pays.rows[0][2], 'Cash (Advance)');
      expect(pays.rows[1][2], 'Online');
    });

    test('cells are formatted the way the app shows them', () {
      expect(formatCell(135000.0, CellKind.money), '₹1,35,000');
      expect(formatCell(DateTime(2026, 11, 9), CellKind.date), '09/11/2026');
      expect(formatCell(null, CellKind.money), '');
      expect(formatCell(61000, CellKind.number), '61000');
    });
  });

  group('pages', () {
    test('a short statement fits on one page', () {
      final doc = partyStatementDoc(t, 'en', ledger(), DateTime(2026, 11, 9));
      expect(paginate(doc).length, 1);
    });

    test('a long statement continues on more pages and nothing is lost', () {
      final doc = partyStatementDoc(t, 'en', ledger(trips: 90), DateTime(2026, 11, 9));
      final pages = paginate(doc);
      expect(pages.length, greaterThan(2));
      expect(pages.length, lessThan(8));
      // 90 trip rows + 2 payment rows + 2 totals + 2 titles + 2 headers + head + summary,
      // plus one repeated header per extra page
      final widgets = pages.fold<int>(0, (s, p) => s + p.length);
      expect(widgets, 90 + 2 + 2 + 2 + 2 + 2 + (pages.length - 1));
      // a page never starts with a lone title
      for (final p in pages.skip(1)) {
        expect(p.length, greaterThan(2));
      }
    });
  });

  group('files', () {
    test('Excel: a summary sheet and one sheet per table, amounts are numbers', () {
      final doc = partyStatementDoc(t, 'en', ledger(), DateTime(2026, 11, 9));
      final bytes = buildXlsx(doc, 'Summary');
      final book = Excel.decodeBytes(bytes);
      expect(book.tables.keys.toList(), ['Summary', 'Trips', 'Payments']);
      final trips = book.tables['Trips']!;
      expect(trips.rows.first.map((c) => c?.value.toString()), ['Date', 'Route', 'Vehicle', 'Bhada', 'Received', 'Due']);
      final first = trips.rows[1];
      expect(first[0]?.value.toString(), '01/11/2026');
      expect(first[1]?.value.toString(), 'Surat → Vapi');
      expect(numOf(first[3]), 12000);
      expect(trips.rows.length, 1 + 2 + 1); // header + trips + totals
      final summary = book.tables['Summary']!;
      expect(summary.rows[3][0]?.value.toString(), 'Total bhada');
      expect(numOf(summary.rows[3][1]), 24000);
    });

    test('Excel keeps Gujarati text', () {
      final doc = partyStatementDoc(t, 'gu', ledger(), DateTime(2026, 11, 9));
      final book = Excel.decodeBytes(buildXlsx(doc, 'Summary'));
      expect(book.tables['Trips']!.rows[1][1]?.value.toString(), 'સુરત → વાપી');
    });

    test('PDF has one page per picture', () async {
      // a 1x1 PNG
      final png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==');
      final pdf = await buildPdf([png, png, png]);
      expect(String.fromCharCodes(pdf.sublist(0, 5)), '%PDF-');
      final text = latin1.decode(pdf);
      expect(RegExp('/Type/Page(?!s)').allMatches(text).length, 3);
    });

    testWidgets('pages are really drawn: Flutter renders each page to a PNG', (t0) async {
      final doc = partyStatementDoc(t, 'gu', ledger(trips: 40), DateTime(2026, 11, 9));
      late List<Uint8List> pics;
      await t0.pumpWidget(Builder(builder: (c) {
        return MaterialApp(home: Scaffold(body: TextButton(onPressed: () {}, child: const Text('x'))));
      }));
      final ctx = t0.element(find.text('x'));
      await t0.runAsync(() async {
        pics = await renderPages(ctx, doc, t, 'Made on today');
      });
      expect(pics.length, paginate(doc).length);
      for (final p in pics) {
        // PNG signature, and a real picture (not an empty one)
        expect(p.sublist(0, 4), [0x89, 0x50, 0x4E, 0x47]);
        expect(p.length, greaterThan(5000));
      }
    });
  });

  group('screens', () {
    late FakeApi api;
    late FakeExportService shared;

    setUp(() {
      api = FakeApi();
      shared = FakeExportService();
      api.addVehicle('Eicher', 'GJ18AZ1266');
      api.addParty('ખોડિયાર');
      api.addAccount('Cash - Jaydip');
    });

    Future<void> boot(WidgetTester t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(await appWith(
        FakeAuthRepository(session: true),
        api: api,
        overrides: [exportServiceProvider.overrideWithValue(shared)],
      ));
      await t.pumpAndSettle();
    }

    testWidgets('party khata: share icon, choose Excel, the file goes to the share sheet', (t0) async {
      final pid = api.db['parties']!.first['id'] as String;
      final vid = api.db['vehicles']!.first['id'] as String;
      api.addTrip(vehicleId: vid, partyId: pid, from: 'Surat', to: 'Vapi', date: dateKey(DateTime.now()), bhada: '12000');
      await boot(t0);
      await tapIt(t0, find.text('ખાતા').last);
      await tapIt(t0, find.text('ખોડિયાર'));
      await tapIt(t0, find.byIcon(Icons.ios_share_rounded));
      expect(find.text('શેર / એક્સપોર્ટ'), findsOneWidget);
      await tapIt(t0, find.text('Excel'));
      expect(shared.shared.length, 1);
      final s = shared.shared.single;
      expect(s.fileName, startsWith('statement_'));
      expect(s.fileName, endsWith('.xlsx'));
      expect(s.mimeType, contains('spreadsheetml'));
      final book = Excel.decodeBytes(s.bytes);
      expect(book.tables.containsKey('ટ્રીપ'), isTrue);
    });

    testWidgets('month details: share icon makes a month Excel with all trips and expenses', (t0) async {
      final vid = api.db['vehicles']!.first['id'] as String;
      final pid = api.db['parties']!.first['id'] as String;
      final today = dateKey(DateTime.now());
      api.addTrip(vehicleId: vid, partyId: pid, from: 'Surat', to: 'Vapi', date: today, bhada: '12000');
      api.addExpense(vehicleId: vid, category: 'diesel', amount: '5000', date: today, liters: '50', odometer: 1000);
      (api.reportData['vehicles']['vehicles'] as List)[0]['vehicle_id'] = vid;
      await boot(t0);
      await tapIt(t0, find.text('રિપોર્ટ').last);
      await tapIt(t0, find.text('મહિના'));
      await t0.tap(find.text('નવેમ્બર 2026').last);
      await t0.pumpAndSettle();
      await tapIt(t0, find.byIcon(Icons.ios_share_rounded));
      await tapIt(t0, find.text('Excel'));
      final s = shared.shared.single;
      expect(s.fileName, startsWith('report_'));
      final book = Excel.decodeBytes(s.bytes);
      expect(book.tables.length, 4); // summary, vehicles, trips, expenses
      final exp = book.tables['ખર્ચ']!;
      expect(exp.rows[1][1]?.value.toString(), 'ડીઝલ');
      expect(numOf(exp.rows[1][5]), 5000);
    });

    testWidgets('PDF: pages are drawn and a real PDF is shared', (t0) async {
      final pid = api.db['parties']!.first['id'] as String;
      final vid = api.db['vehicles']!.first['id'] as String;
      api.addTrip(vehicleId: vid, partyId: pid, from: 'Surat', to: 'Vapi', date: dateKey(DateTime.now()), bhada: '12000');
      await boot(t0);
      await tapIt(t0, find.text('ખાતા').last);
      await tapIt(t0, find.text('ખોડિયાર'));
      await tapIt(t0, find.byIcon(Icons.ios_share_rounded));
      await t0.runAsync(() async {
        await t0.tap(find.text('PDF'));
        await Future<void>.delayed(const Duration(seconds: 3));
      });
      await t0.pumpAndSettle();
      expect(shared.shared.length, 1);
      expect(shared.shared.single.fileName, endsWith('.pdf'));
      expect(shared.shared.single.mimeType, 'application/pdf');
      expect(String.fromCharCodes(shared.shared.single.bytes.sublist(0, 5)), '%PDF-');
    });
  });
}
