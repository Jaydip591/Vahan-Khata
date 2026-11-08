import 'package:flutter_test/flutter_test.dart';
import 'package:vahan_khata/core/money.dart';

void main() {
  group('formatRupees (Indian grouping)', () {
    test('small and large amounts', () {
      expect(formatRupees(0), '₹0');
      expect(formatRupees(999), '₹999');
      expect(formatRupees(1000), '₹1,000');
      expect(formatRupees(12000), '₹12,000');
      expect(formatRupees(135000), '₹1,35,000');
      expect(formatRupees(12345678), '₹1,23,45,678');
    });
    test('paise only when present', () {
      expect(formatRupees(1500.5), '₹1,500.50');
      expect(formatRupees(1500.0), '₹1,500');
      expect(formatRupees(0.1 + 0.2), '₹0.30');
    });
    test('negative and without symbol', () {
      expect(formatRupees(-5000), '-₹5,000');
      expect(formatRupees(5000, symbol: false), '5,000');
    });
  });

  group('parseMoney', () {
    test('reads server decimals', () {
      expect(parseMoney('12000.00'), 12000);
      expect(parseMoney('0.10'), 0.1);
      expect(parseMoney(null), 0);
      expect(parseMoney('abc'), 0);
      expect(parseMoney(5), 5);
    });
  });

  group('applyKey', () {
    test('typing digits and backspace', () {
      var s = '';
      for (final k in ['1', '2', '0', '0', '0']) {
        s = applyKey(s, k);
      }
      expect(s, '12000');
      expect(applyKey(s, '⌫'), '1200');
      expect(applyKey('', '⌫'), '');
    });
    test('no leading zeros, and 00 needs a number first', () {
      expect(applyKey('', '0'), '0');
      expect(applyKey('0', '0'), '0');
      expect(applyKey('0', '5'), '5');
      expect(applyKey('', '00'), '');
      expect(applyKey('5', '00'), '500');
      expect(applyKey('0', '00'), '0');
    });
    test('whole numbers ignore the decimal point', () {
      expect(applyKey('12', '.'), '12');
    });
    test('decimal mode: one point, two decimals', () {
      expect(applyKey('', '.', decimal: true), '0.');
      expect(applyKey('45', '.', decimal: true), '45.');
      expect(applyKey('45.5', '.', decimal: true), '45.5');
      expect(applyKey('45.5', '2', decimal: true), '45.52');
      expect(applyKey('45.52', '9', decimal: true), '45.52');
    });
    test('length is limited', () {
      expect(applyKey('123456789', '1'), '123456789');
      expect(applyKey('12345', '6', maxDigits: 5), '12345');
    });
  });

  test('date helpers', () {
    expect(monthKey(DateTime(2026, 3, 9)), '2026-03');
    expect(dateKey(DateTime(2026, 3, 9)), '2026-03-09');
    expect(formatDay(DateTime(2026, 3, 9)), '09/03/2026');
  });
}
