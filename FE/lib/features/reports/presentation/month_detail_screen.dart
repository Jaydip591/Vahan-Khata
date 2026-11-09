import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_chip.dart';
import '../../../core/ui/ink_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/presentation/expense_sheet.dart';
import '../../trips/data/trip_repository.dart';
import '../../trips/presentation/trips_screen.dart';
import '../data/report_repository.dart';
import 'expense_row.dart';
import 'month_switcher.dart';

enum _Part { vehicles, trips, expenses }

/// Everything about one month: totals, each vehicle, every trip and every expense.
class MonthDetailScreen extends ConsumerStatefulWidget {
  const MonthDetailScreen({super.key});

  @override
  ConsumerState<MonthDetailScreen> createState() => _MonthDetailScreenState();
}

class _MonthDetailScreenState extends ConsumerState<MonthDetailScreen> {
  _Part _part = _Part.vehicles;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final month = monthKey(ref.watch(selectedMonthProvider));
    final summary = ref.watch(summaryProvider(month)).asData?.value;
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          InkHeader(
            title: t.monthDetails,
            leading: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: const MonthSwitcher(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                invalidateReports(ref);
                await ref.read(summaryProvider(month).future);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (summary != null)
                    ReportCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  t.profitLabel,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ),
                              Text(
                                formatRupees(summary.profit),
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: profitColor(summary.profit),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              MiniStat(
                                label: t.incomeLabel,
                                value: formatRupees(summary.income),
                                color: AppColors.income,
                              ),
                              MiniStat(
                                label: t.expenseLabel,
                                value: formatRupees(summary.expense),
                                color: AppColors.expense,
                              ),
                              MiniStat(
                                label: t.collectedLabel,
                                value: formatRupees(summary.collected),
                              ),
                              MiniStat(
                                label: t.tabTrips,
                                value: '${summary.trips}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
                                _Part.vehicles => t.reportVehicle,
                                _Part.trips => t.tabTrips,
                                _Part.expenses => t.tabKharcha,
                              },
                              selected: _part == p,
                              onTap: () => setState(() => _part = p),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._body(t, lang, month),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _body(AppL10n t, String lang, String month) {
    switch (_part) {
      case _Part.vehicles:
        return ref
            .watch(vehicleReportProvider(month))
            .when(
              loading: _loading,
              error: (e, _) => [_error(t, e)],
              data: (rows) => rows.isEmpty
                  ? [_empty(t.emptyVehicles)]
                  : [
                      for (final v in rows) ...[
                        ReportCard(
                          child: InkWell(
                            onTap: () => context.push(
                              '/report/vehicle',
                              extra: [v.id, v.name],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        v.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        '${t.tripsCount(v.trips)}  ·  ${t.expenseLabel} ${formatRupees(v.expense)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  formatRupees(v.profit),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: profitColor(v.profit),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
            );
      case _Part.trips:
        return ref
            .watch(tripsProvider(month))
            .when(
              loading: _loading,
              error: (e, _) => [_error(t, e)],
              data: (list) => list.isEmpty
                  ? [_empty(t.emptyTrips)]
                  : [
                      for (final trip in list) ...[
                        TripCard(trip: trip, lang: lang),
                        const SizedBox(height: 10),
                      ],
                    ],
            );
      case _Part.expenses:
        return ref
            .watch(monthExpensesProvider((month: month, vehicleId: null)))
            .when(
              loading: _loading,
              error: (e, _) => [_error(t, e)],
              data: (list) => list.isEmpty
                  ? [_empty(t.emptyReport)]
                  : [
                      for (final e in list) ...[
                        ExpenseRow(
                          expense: e,
                          showVehicle: true,
                          onTap: () => showExpenseSheet(
                            context,
                            e.category,
                            existing: e,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
            );
    }
  }

  List<Widget> _loading() => const [
    Padding(
      padding: EdgeInsets.all(32),
      child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
    ),
  ];

  Widget _error(AppL10n t, Object e) => ErrorRetry(
    message: errorMessage(t, e),
    retryLabel: t.retry,
    onRetry: () => invalidateReports(ref),
  );

  Widget _empty(String text) => Padding(
    padding: const EdgeInsets.all(32),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 18, color: AppColors.muted),
    ),
  );
}
