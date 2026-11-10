import '../../core/money.dart';
import '../../l10n/app_localizations.dart';
import '../expenses/data/expense.dart';
import '../ledger/data/ledger.dart';
import '../reports/data/report.dart';
import '../trips/data/trip.dart';

/// What kind of value a column holds. Money and numbers are real numbers in Excel
/// and right-aligned in the PDF; dates are written as dd/mm/yyyy.
enum CellKind { text, money, number, date }

class DocColumn {
  const DocColumn(this.title, this.kind, {this.flex = 1});
  final String title;
  final CellKind kind;
  final double flex;
  bool get right => kind == CellKind.money || kind == CellKind.number;
}

class DocTable {
  const DocTable({
    required this.title,
    required this.columns,
    required this.rows,
    this.totals,
  });
  final String title;
  final List<DocColumn> columns;

  /// Each cell is a String, a number, a DateTime or null.
  final List<List<Object?>> rows;

  /// Optional last row (same length as columns) shown in bold.
  final List<Object?>? totals;
}

enum Tone { neutral, income, expense }

class SummaryItem {
  const SummaryItem(this.label, this.value, {this.tone = Tone.neutral});
  final String label;
  final Object value; // double = money, String = text
  final Tone tone;
}

/// One printable document: a title, a few headline numbers and some tables.
/// Both the PDF and the Excel file are made from this, so they always agree.
class StatementDoc {
  const StatementDoc({
    required this.title,
    required this.subtitle,
    required this.fileName,
    required this.summary,
    required this.tables,
  });
  final String title;
  final String subtitle;
  final String fileName; // without extension
  final List<SummaryItem> summary;
  final List<DocTable> tables;
}

String _safe(String s) => s
    .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
    .replaceAll(RegExp(r'^_+|_+$'), '');

String _payMode(AppL10n t, String mode) =>
    mode == 'cash' ? t.modeCash : t.modeOnline;

/// The khata of one party: totals, every trip with what is paid, every payment.
StatementDoc partyStatementDoc(
  AppL10n t,
  String lang,
  PartyLedger l,
  DateTime now,
) {
  return StatementDoc(
    title: t.docParty,
    subtitle: l.phone == null || l.phone!.isEmpty
        ? l.name
        : '${l.name}  ·  ${l.phone}',
    fileName:
        'statement_${_safe(l.name).isEmpty ? 'party' : _safe(l.name)}_${dateKey(now)}',
    summary: [
      SummaryItem(t.totalBhada, l.totalBhada),
      SummaryItem(t.receivedLabel, l.totalPaid, tone: Tone.income),
      SummaryItem(
        t.homeDueCard,
        l.balance,
        tone: l.balance > 0 ? Tone.expense : Tone.income,
      ),
    ],
    tables: [
      DocTable(
        title: t.tabTrips,
        columns: [
          DocColumn(t.colDate, CellKind.date, flex: 1.8),
          DocColumn(t.colRoute, CellKind.text, flex: 2.6),
          DocColumn(t.vehicle, CellKind.text, flex: 1.6),
          DocColumn(t.bhadaLabel, CellKind.money, flex: 1.4),
          DocColumn(t.receivedLabel, CellKind.money, flex: 1.4),
          DocColumn(t.colDue, CellKind.money, flex: 1.4),
        ],
        rows: [
          for (final x in l.trips)
            [
              x.date,
              '${x.from.nameFor(lang)} → ${x.to.nameFor(lang)}',
              x.vehicleName,
              x.bhada,
              x.paid,
              x.due,
            ],
        ],
        totals: [null, null, null, l.totalBhada, l.totalPaid, l.balance],
      ),
      DocTable(
        title: t.paymentsHeading,
        columns: [
          DocColumn(t.colDate, CellKind.date, flex: 1.8),
          DocColumn(t.colAmount, CellKind.money, flex: 1.4),
          DocColumn(t.colMode, CellKind.text, flex: 1.4),
          DocColumn(t.colAccount, CellKind.text, flex: 2.4),
        ],
        rows: [
          for (final p in l.payments)
            [
              p.date,
              p.amount,
              p.isAdvance
                  ? '${_payMode(t, p.mode)} (${t.advanceTag})'
                  : _payMode(t, p.mode),
              p.accountName,
            ],
        ],
        totals: [null, l.totalPaid, null, null],
      ),
    ],
  );
}

/// A whole month: headline numbers, each vehicle, every trip and every expense.
StatementDoc monthDoc(
  AppL10n t,
  String lang, {
  required String monthLabelText,
  required String monthKeyText,
  required MonthSummary summary,
  required List<VehicleReport> vehicles,
  required List<Trip> trips,
  required List<Expense> expenses,
}) {
  final totalExpense = expenses.fold<double>(0, (s, e) => s + e.amount);
  return StatementDoc(
    title: t.docMonth,
    subtitle: monthLabelText,
    fileName: 'report_$monthKeyText',
    summary: [
      SummaryItem(
        t.profitLabel,
        summary.profit,
        tone: summary.profit < 0 ? Tone.expense : Tone.income,
      ),
      SummaryItem(t.incomeLabel, summary.income, tone: Tone.income),
      SummaryItem(t.expenseLabel, summary.expense, tone: Tone.expense),
      SummaryItem(t.collectedLabel, summary.collected),
    ],
    tables: [
      DocTable(
        title: t.reportVehicle,
        columns: [
          DocColumn(t.vehicle, CellKind.text, flex: 2.2),
          DocColumn(t.tabTrips, CellKind.number, flex: 0.9),
          DocColumn(t.incomeLabel, CellKind.money, flex: 1.5),
          DocColumn(t.expenseLabel, CellKind.money, flex: 1.5),
          DocColumn(t.profitLabel, CellKind.money, flex: 1.5),
        ],
        rows: [
          for (final v in vehicles)
            [v.name, v.trips, v.income, v.expense, v.profit],
        ],
        totals: [
          null,
          vehicles.fold<int>(0, (s, v) => s + v.trips),
          summary.income,
          summary.expense,
          summary.profit,
        ],
      ),
      DocTable(
        title: t.tabTrips,
        columns: [
          DocColumn(t.colDate, CellKind.date, flex: 1.8),
          DocColumn(t.colRoute, CellKind.text, flex: 2.4),
          DocColumn(t.colParty, CellKind.text, flex: 1.8),
          DocColumn(t.vehicle, CellKind.text, flex: 1.5),
          DocColumn(t.bhadaLabel, CellKind.money, flex: 1.3),
        ],
        rows: [
          for (final x in trips)
            [
              x.tripDate,
              '${x.from.nameFor(lang)} → ${x.to.nameFor(lang)}',
              x.party.name,
              x.vehicle.name,
              x.bhada,
            ],
        ],
        totals: [
          null,
          null,
          null,
          null,
          trips.fold<double>(0, (s, x) => s + x.bhada),
        ],
      ),
      DocTable(
        title: t.tabKharcha,
        columns: [
          DocColumn(t.colDate, CellKind.date, flex: 1.8),
          DocColumn(t.colCategory, CellKind.text, flex: 1.2),
          DocColumn(t.vehicle, CellKind.text, flex: 1.7),
          DocColumn(t.colQty, CellKind.text, flex: 1.2),
          DocColumn(t.colOdometer, CellKind.number, flex: 1.3),
          DocColumn(t.colAmount, CellKind.money, flex: 1.3),
        ],
        rows: [
          for (final e in expenses)
            [
              e.date,
              e.category.label(t),
              e.vehicle.name,
              e.liters == null
                  ? ''
                  : (e.category == ExpenseCategory.cng
                        ? t.kgValue(_trim(e.liters!))
                        : t.litersValue(_trim(e.liters!))),
              e.odometer,
              e.amount,
            ],
        ],
        totals: [null, null, null, null, null, totalExpense],
      ),
    ],
  );
}

/// A financial year: headline numbers, each month and each vehicle.
StatementDoc yearDoc(AppL10n t, String lang, YearReport y, String Function(DateTime) monthName) {
  return StatementDoc(
    title: t.docYear,
    subtitle: t.fyLabel(y.label),
    fileName: 'report_FY_${y.label}',
    summary: [
      SummaryItem(t.profitLabel, y.profit, tone: y.profit < 0 ? Tone.expense : Tone.income),
      SummaryItem(t.incomeLabel, y.income, tone: Tone.income),
      SummaryItem(t.expenseLabel, y.expense, tone: Tone.expense),
      SummaryItem(t.collectedLabel, y.collected),
    ],
    tables: [
      DocTable(
        title: t.byMonth,
        columns: [
          DocColumn(t.colMonth, CellKind.text, flex: 2),
          DocColumn(t.colTrips, CellKind.number, flex: 0.9),
          DocColumn(t.incomeLabel, CellKind.money, flex: 1.5),
          DocColumn(t.expenseLabel, CellKind.money, flex: 1.5),
          DocColumn(t.profitLabel, CellKind.money, flex: 1.5),
          DocColumn(t.collectedLabel, CellKind.money, flex: 1.5),
        ],
        rows: [
          for (final m in y.months) [monthName(m.month), m.trips, m.income, m.expense, m.profit, m.collected],
        ],
        totals: [null, y.trips, y.income, y.expense, y.profit, y.collected],
      ),
      DocTable(
        title: t.byVehicle,
        columns: [
          DocColumn(t.vehicle, CellKind.text, flex: 2.2),
          DocColumn(t.colTrips, CellKind.number, flex: 0.9),
          DocColumn(t.incomeLabel, CellKind.money, flex: 1.5),
          DocColumn(t.expenseLabel, CellKind.money, flex: 1.5),
          DocColumn(t.profitLabel, CellKind.money, flex: 1.5),
        ],
        rows: [for (final v in y.vehicles) [v.name, v.trips, v.income, v.expense, v.profit]],
        totals: [null, y.trips, y.income, y.expense, y.profit],
      ),
    ],
  );
}

String _trim(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

/// How a cell looks in the PDF (and as text in Excel for dates).
String formatCell(Object? v, CellKind kind) {
  if (v == null) return '';
  switch (kind) {
    case CellKind.money:
      return v is num ? formatRupees(v) : '$v';
    case CellKind.date:
      return v is DateTime ? formatDay(v) : '$v';
    case CellKind.number:
      return v is num ? '${v.round()}' : '$v';
    case CellKind.text:
      return '$v';
  }
}
