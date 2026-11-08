import '../../../l10n/app_localizations.dart';

enum AccountKind {
  cash('cash'),
  bank('bank'),
  upi('upi');

  const AccountKind(this.key);
  final String key;

  static AccountKind fromKey(String key) =>
      AccountKind.values.firstWhere((k) => k.key == key, orElse: () => AccountKind.cash);

  String label(AppL10n t) => switch (this) {
        cash => t.kindCash,
        bank => t.kindBank,
        upi => t.kindUpi,
      };
}

class Account {
  const Account({
    required this.id,
    required this.name,
    required this.kind,
    required this.openingBalance,
    required this.isActive,
  });

  final String id;
  final String name;
  final AccountKind kind;

  /// Exact decimal string from the server, e.g. "1500.50". Never converted to a double.
  final String openingBalance;
  final bool isActive;

  factory Account.fromJson(Map<String, dynamic> j) => Account(
        id: j['id'] as String,
        name: j['name'] as String,
        kind: AccountKind.fromKey(j['kind'] as String),
        openingBalance: j['opening_balance'].toString(),
        isActive: j['is_active'] as bool,
      );
}
