import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vahan_khata/features/upi/data/payee.dart';
import 'package:vahan_khata/features/upi/data/upi_service.dart';

import 'support/fake_api.dart';
import 'support/fakes.dart';

class FakeUpi implements UpiService {
  FakeUpi(this.answer);
  UpiResult answer;
  final asked = <Uri>[];

  @override
  Future<UpiResult> pay(Uri uri) async {
    asked.add(uri);
    return answer;
  }
}

void main() {
  group('parsing', () {
    test('a UPI app answer', () {
      final r = UpiResult.parse(
          resultOk: true, response: 'txnId=AXI123&responseCode=00&Status=SUCCESS&txnRef=abc&ApprovalRefNo=631234567890');
      expect(r.status, UpiStatus.success);
      expect(r.ref, '631234567890');
      expect(UpiResult.parse(resultOk: true, response: 'status=FAILURE&txnId=1').status, UpiStatus.failure);
      expect(UpiResult.parse(resultOk: true, response: 'Status=SUBMITTED').status, UpiStatus.pending);
      expect(UpiResult.parse(resultOk: true, response: null).status, UpiStatus.unknown);
      expect(UpiResult.parse(resultOk: false, response: null).status, UpiStatus.failure);
    });

    test('a UPI QR code', () {
      final q = UpiQr.parse('upi://pay?pa=kamrejpump@okaxis&pn=Kamrej%20Petroleum&mc=5541')!;
      expect(q.upiId, 'kamrejpump@okaxis');
      expect(q.name, 'Kamrej Petroleum');
      expect(UpiQr.parse('9876543210@ybl')!.upiId, '9876543210@ybl');
      expect(UpiQr.parse('https://example.com'), isNull);
      expect(UpiQr.parse('upi://pay?pn=NoId'), isNull);
    });

    test('the pay link has the amount with paise and INR', () {
      final u = upiPayUri(upiId: 'p@ybl', name: 'Pump', amount: '3000', note: 'Vahan Khata - Diesel', txnRef: 'abc');
      expect(u.scheme, 'upi');
      expect(u.queryParameters['am'], '3000.00');
      expect(u.queryParameters['cu'], 'INR');
      expect(u.queryParameters['pa'], 'p@ybl');
      expect(u.queryParameters['tr'], 'abc');
    });
  });

  group('kharcha sheet', () {
    setUpAll(loadAppFonts);

    late FakeApi api;
    late FakeUpi upi;

    setUp(() {
      api = FakeApi();
      api.addVehicle('Eicher 1', 'GJ05 AB 1234');
      api.addAccount('Cash - Jaydip');
      api.addAccount('UPI - Bhai', kind: 'upi');
      api.db['payees']!.add({'id': 'py-1', 'name': 'Pump - Kamrej', 'upi_id': 'kamrejpump@okaxis', 'is_active': true});
      upi = FakeUpi(const UpiResult(UpiStatus.success, ref: '631234567890'));
    });

    Future<void> openToll(WidgetTester t) async {
      t.view.physicalSize = const Size(1080, 2400);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(await appWith(FakeAuthRepository(session: true),
          api: api, overrides: [upiServiceProvider.overrideWithValue(upi)]));
      await t.pumpAndSettle();
      await t.tap(find.text('ખર્ચ').first);
      await t.pumpAndSettle();
      await t.tap(find.text('ટોલ').first);
      await t.pumpAndSettle();
      await tapIt(t, find.text('Eicher 1'));
      for (final k in '500'.split('')) {
        await t.tap(find.text(k).last);
      }
      await t.pump();
    }

    Map<String, dynamic>? posted() {
      final calls = api.where('POST', '/api/v1/expenses');
      return calls.isEmpty ? null : Map<String, dynamic>.from(calls.single.data as Map);
    }

    testWidgets('paid by UPI to a saved pump: expense saved with payee, UPI ref and the UPI account', (t) async {
      await openToll(t);
      await tapIt(t, find.text('UPI થી ચૂકવો'));
      expect(find.text('કોને ચૂકવવા?'), findsOneWidget);
      await tapIt(t, find.text('Pump - Kamrej'));
      expect(upi.asked.single.queryParameters['pa'], 'kamrejpump@okaxis');
      expect(upi.asked.single.queryParameters['am'], '500.00');
      final body = posted()!;
      expect(body['payee_id'], 'py-1');
      expect(body['upi_ref'], '631234567890');
      final upiAcc = api.db['accounts']!.firstWhere((a) => a['kind'] == 'upi')['id'];
      expect(body['account_id'], upiAcc);
      expect(upi.asked.single.queryParameters['tr'], (body['id'] as String).replaceAll('-', ''));
    });

    testWidgets('a new payee typed once is saved and paid', (t) async {
      await openToll(t);
      await tapIt(t, find.text('UPI થી ચૂકવો'));
      await tapIt(t, find.text('UPI ID લખો'));
      final f = find.byType(TextFormField);
      await t.enterText(f.at(0), 'Toll Plaza');
      await t.enterText(f.at(1), 'bad id');
      await tapIt(t, find.text('સાચવીને આગળ'));
      expect(find.text('UPI ID આવું હોય: નામ@બેંક'), findsOneWidget);
      await t.enterText(f.at(1), 'tollplaza@sbi');
      await tapIt(t, find.text('સાચવીને આગળ'));
      expect(api.db['payees']!.any((p) => p['upi_id'] == 'tollplaza@sbi'), isTrue);
      expect(upi.asked.single.queryParameters['pa'], 'tollplaza@sbi');
      expect(posted(), isNotNull);
    });

    testWidgets('a failed payment saves nothing', (t) async {
      upi.answer = const UpiResult(UpiStatus.failure);
      await openToll(t);
      await tapIt(t, find.text('UPI થી ચૂકવો'));
      await tapIt(t, find.text('Pump - Kamrej'));
      expect(posted(), isNull);
      expect(find.text('પેમેન્ટ થયું નથી. ખર્ચ સાચવ્યો નથી.'), findsOneWidget);
    });

    testWidgets('an unclear answer asks first; No saves nothing, Yes saves', (t) async {
      upi.answer = const UpiResult(UpiStatus.unknown);
      // The Save button spins behind the question, so frames are pumped by hand here.
      Future<void> frames() async {
        for (var i = 0; i < 12; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
      }

      await openToll(t);
      await tapIt(t, find.text('UPI થી ચૂકવો'));
      await tapIt(t, find.text('Pump - Kamrej'), settle: false);
      await frames();
      expect(find.text('પેમેન્ટ થયું?'), findsOneWidget);
      await t.tap(find.text('રદ કરો'));
      await t.pumpAndSettle();
      expect(posted(), isNull);
      await tapIt(t, find.text('UPI થી ચૂકવો'));
      await tapIt(t, find.text('Pump - Kamrej'), settle: false);
      await frames();
      await t.tap(find.text('હા'));
      await t.pumpAndSettle();
      expect(posted(), isNotNull);
    });
  });
}
