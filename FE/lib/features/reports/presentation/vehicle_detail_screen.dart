import 'package:flutter/material.dart';
import '../../../core/ui/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_chip.dart';
import '../../../core/ui/ink_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/data/expense.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/presentation/expense_sheet.dart';
import '../../trips/data/trip_repository.dart';
import '../../trips/presentation/trips_screen.dart';
import '../data/report.dart';
import '../data/report_repository.dart';
import 'expense_row.dart';
import 'month_switcher.dart';

enum _Part { trips, diesel, other }

/// One vehicle for one month: profit, mileage, its trips, a diesel log and other expenses.
class VehicleDetailScreen extends ConsumerStatefulWidget {
  const VehicleDetailScreen({
    super.key,
    required this.vehicleId,
    required this.name,
  });
  final String vehicleId;
  final String name;

  @override
  ConsumerState<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  _Part _part = _Part.diesel;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final month = monthKey(ref.watch(selectedMonthProvider));
    final report = ref
        .watch(vehicleReportProvider(month))
        .asData
        ?.value
        .where((v) => v.id == widget.vehicleId)
        .firstOrNull;
    final expenses = ref.watch(
      monthExpensesProvider((month: month, vehicleId: widget.vehicleId)),
    );
    final trips = ref.watch(
      vehicleTripsProvider((month: month, vehicleId: widget.vehicleId)),
    );
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          InkHeader(
            title: widget.name,
            leading: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Container(
            color: AppColors.card,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: const MonthSwitcher(),
          ),
          Expanded(
            child: AppRefresh(
              onRefresh: () async {
                invalidateReports(ref);
                await ref.read(vehicleReportProvider(month).future);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (report != null) _Summary(report: report),
                  const SizedBox(height: 14),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final p in _Part.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AppChip(
                              label: switch (p) {
                                _Part.trips => t.tabTrips,
                                _Part.diesel => t.fuelLabel,
                                _Part.other => t.otherExpenses,
                              },
                              selected: _part == p,
                              onTap: () => setState(() => _part = p),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...switch (_part) {
                    _Part.trips => _tripsList(t, lang, trips),
                    _Part.diesel => _expenseList(t, expenses, diesel: true),
                    _Part.other => _expenseList(t, expenses, diesel: false),
                  },
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _tripsList(AppL10n t, String lang, AsyncValue<dynamic> trips) {
    return trips.when(
      loading: _loading,
      error: (e, _) => [_error(t, e, () => invalidateReports(ref))],
      data: (list) => list.isEmpty
          ? [_empty(t.emptyTrips)]
          : [
              for (final trip in list) ...[
                TripCard(trip: trip, lang: lang),
                const SizedBox(height: 10),
              ],
            ],
    );
  }

  List<Widget> _expenseList(
    AppL10n t,
    AsyncValue<List<Expense>> all, {
    required bool diesel,
  }) {
    return all.when(
      loading: _loading,
      error: (e, _) => [_error(t, e, () => invalidateReports(ref))],
      data: (list) {
        final rows = list
            .where((e) => e.category.isFuel == diesel)
            .toList();
        if (rows.isEmpty) return [_empty(t.emptyReport)];
        final total = rows.fold<double>(0, (s, e) => s + e.amount);
        final liters = rows.fold<double>(0, (s, e) => s + (e.liters ?? 0));
        final kinds = rows.map((e) => e.category).toSet();
        return [
          ReportCard(
            child: Row(
              children: [
                MiniStat(
                  label: t.totalExpense,
                  value: formatRupees(total),
                  color: AppColors.expense,
                ),
                if (diesel && kinds.length == 1) ...[
                  // one fuel only: quantity and average rate make sense
                  MiniStat(
                    label: kinds.first == ExpenseCategory.cng ? t.kgLabel : t.litersLabel,
                    value: liters == 0 ? '—' : liters.toStringAsFixed(1),
                  ),
                  MiniStat(
                    label: t.avgRate,
                    value: liters == 0 ? '—' : formatRupees(total / liters),
                  ),
                ] else
                  MiniStat(label: t.entriesLabel, value: '${rows.length}'),
              ],
            ),
          ),
          const SizedBox(height: 10),
          for (final e in rows) ...[
            ExpenseRow(
              expense: e,
              onTap: () => showExpenseSheet(context, e.category, existing: e),
            ),
            const SizedBox(height: 8),
          ],
        ];
      },
    );
  }

  List<Widget> _loading() => const [
    Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
    ),
  ];

  Widget _error(AppL10n t, Object e, VoidCallback retry) => ErrorRetry(
    message: errorMessage(t, e),
    retryLabel: t.retry,
    onRetry: retry,
  );

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.all(32),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 18, color: AppColors.muted),
    ),
  );
}

class _Summary extends StatelessWidget {
  const _Summary({required this.report});
  final VehicleReport report;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final r = report;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            t.profitLabel,
            style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 15),
          ),
          Text(
            formatRupees(r.profit),
            style: TextStyle(
              color: r.profit < 0
                  ? AppColors.expenseOnInk
                  : AppColors.incomeOnInk,
              fontSize: 34,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat(
                t.incomeLabel,
                formatRupees(r.income),
                AppColors.incomeOnInk,
              ),
              _stat(
                t.expenseLabel,
                formatRupees(r.expense),
                AppColors.expenseOnInk,
              ),
              _stat(t.tabTrips, '${r.trips}', Colors.white),
            ],
          ),
          if (r.mileage != null) ...[
            const SizedBox(height: 10),
            Text(
              '${r.mileageIsKg ? t.mileageKg(r.mileage!.toStringAsFixed(1)) : t.mileageValue(r.mileage!.toStringAsFixed(1))}${r.km != null ? '  ·  ${t.kmValue(r.km!)}' : ''}',
              style: const TextStyle(color: AppColors.gold, fontSize: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 14),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
