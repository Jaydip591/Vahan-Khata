import '../../../l10n/app_localizations.dart';

enum PaymentCycle {
  daily('daily'),
  tenDays('ten_days'),
  monthly('monthly');

  const PaymentCycle(this.key);
  final String key;

  static PaymentCycle? fromKey(String? key) {
    for (final c in PaymentCycle.values) {
      if (c.key == key) return c;
    }
    return null;
  }

  String label(AppL10n t) => switch (this) {
        daily => t.cycleDaily,
        tenDays => t.cycleTenDays,
        monthly => t.cycleMonthly,
      };
}

class Party {
  const Party({
    required this.id,
    required this.name,
    this.phone,
    this.paymentCycle,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? phone;
  final PaymentCycle? paymentCycle;
  final bool isActive;

  factory Party.fromJson(Map<String, dynamic> j) => Party(
        id: j['id'] as String,
        name: j['name'] as String,
        phone: j['phone'] as String?,
        paymentCycle: PaymentCycle.fromKey(j['payment_cycle'] as String?),
        isActive: j['is_active'] as bool,
      );
}
