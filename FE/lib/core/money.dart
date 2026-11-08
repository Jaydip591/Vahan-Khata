// Money helpers. The server sends exact decimal strings ("12000.00"); the app
// only displays them and works in whole rupees when the user enters amounts.

double parseMoney(Object? v) {
  if (v == null) return 0;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString()) ?? 0;
}

/// Indian digit grouping: 135000 -> ₹1,35,000. Paise are shown only when present.
String formatRupees(num value, {bool symbol = true}) {
  final negative = value < 0;
  final total = (value.abs() * 100).round();
  final whole = (total ~/ 100).toString();
  final paise = total % 100;
  var grouped = whole;
  if (whole.length > 3) {
    final last3 = whole.substring(whole.length - 3);
    final rest = whole.substring(0, whole.length - 3).replaceAllMapped(
          RegExp(r'(\d)(?=(\d\d)+$)'),
          (m) => '${m[1]},',
        );
    grouped = '$rest,$last3';
  }
  final text = paise == 0 ? grouped : '$grouped.${paise.toString().padLeft(2, '0')}';
  return '${negative ? '-' : ''}${symbol ? '₹' : ''}$text';
}

/// Applies one keypad press to the text being typed. [decimal] allows one '.' with
/// up to two decimals; otherwise only whole numbers. Never longer than [maxDigits].
String applyKey(String current, String key, {bool decimal = false, int maxDigits = 9}) {
  if (key == '⌫') {
    return current.isEmpty ? current : current.substring(0, current.length - 1);
  }
  if (key == '.') {
    if (!decimal || current.contains('.')) return current;
    return current.isEmpty ? '0.' : '$current.';
  }
  final isDigits = RegExp(r'^\d+$').hasMatch(key);
  if (!isDigits) return current;
  if (key == '00' && current.isEmpty) return current;
  var next = current == '0' ? key.replaceFirst(RegExp(r'^0+'), '') : current + key;
  if (key == '0' && current == '0') next = '0';
  if (key == '00' && current == '0') next = '0';
  if (next.isEmpty) next = '0';
  final parts = next.split('.');
  if (parts[0].length > maxDigits) return current;
  if (parts.length > 1 && parts[1].length > 2) return current;
  return next;
}

String monthKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String formatDay(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
