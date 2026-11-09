import '../../core/money.dart';

enum OutboxKind {
  trip('trip', '/api/v1/trips'),
  expense('expense', '/api/v1/expenses'),
  payment('payment', '/api/v1/payments');

  const OutboxKind(this.key, this.path);
  final String key;
  final String path;

  static OutboxKind fromKey(String key) =>
      OutboxKind.values.firstWhere((k) => k.key == key);
}

/// One entry saved on the phone that has not reached the server yet.
/// [body] is exactly what will be posted; its `id` is made on the phone, so
/// sending it twice can never create two rows.
class OutboxItem {
  const OutboxItem({
    required this.kind,
    required this.body,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    this.failed = false,
    this.error,
  });

  final OutboxKind kind;
  final Map<String, dynamic> body;
  final String title; // what the list shows, fixed at save time
  final String subtitle;
  final double amount;
  final DateTime date;
  final bool failed; // the server refused it: needs a look from the user
  final String? error;

  String get id => body['id'] as String;

  OutboxItem copyWith({bool? failed, String? error}) => OutboxItem(
    kind: kind,
    body: body,
    title: title,
    subtitle: subtitle,
    amount: amount,
    date: date,
    failed: failed ?? this.failed,
    error: error ?? this.error,
  );

  Map<String, dynamic> toJson() => {
    'kind': kind.key,
    'body': body,
    'title': title,
    'subtitle': subtitle,
    'amount': amount,
    'date': dateKey(date),
    'failed': failed,
    'error': error,
  };

  factory OutboxItem.fromJson(Map<String, dynamic> j) => OutboxItem(
    kind: OutboxKind.fromKey(j['kind'] as String),
    body: Map<String, dynamic>.from(j['body'] as Map),
    title: j['title'] as String,
    subtitle: j['subtitle'] as String,
    amount: (j['amount'] as num).toDouble(),
    date: DateTime.parse(j['date'] as String),
    failed: j['failed'] as bool? ?? false,
    error: j['error'] as String?,
  );
}
