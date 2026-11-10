/// Someone paid by UPI from the app, e.g. "Pump - Kamrej" with kamrejpump@okaxis.
class Payee {
  const Payee({required this.id, required this.name, required this.upiId, this.isActive = true});

  final String id;
  final String name;
  final String upiId;
  final bool isActive;

  factory Payee.fromJson(Map<String, dynamic> j) => Payee(
        id: j['id'] as String,
        name: j['name'] as String,
        upiId: j['upi_id'] as String,
        isActive: j['is_active'] as bool? ?? true,
      );
}

/// What a UPI QR code says: `upi://pay?pa=ID&pn=NAME&...`.
class UpiQr {
  const UpiQr({required this.upiId, this.name});
  final String upiId;
  final String? name;

  static final _upiIdRe = RegExp(r'^[A-Za-z0-9._-]{1,256}@[A-Za-z][A-Za-z0-9.]{1,63}$');

  static bool isValidId(String v) => _upiIdRe.hasMatch(v.trim());

  /// Null when the text is not a UPI payment code.
  static UpiQr? parse(String raw) {
    final text = raw.trim();
    if (isValidId(text)) return UpiQr(upiId: text);
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme.toLowerCase() != 'upi') return null;
    final pa = uri.queryParameters['pa']?.trim();
    if (pa == null || !isValidId(pa)) return null;
    final pn = uri.queryParameters['pn']?.trim();
    return UpiQr(upiId: pa, name: pn == null || pn.isEmpty ? null : pn);
  }
}
