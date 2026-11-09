import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/month_names.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_chip.dart';
import '../../../core/ui/ink_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/data/expense.dart';
import '../data/report.dart';
import '../data/report_repository.dart';
import 'month_switcher.dart';
import 'report_widgets.dart';

enum _Tab { vehicle, party, trend, expense }

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  _Tab _tab = _Tab.vehicle;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final key = monthKey(ref.watch(selectedMonthProvider));
    final labels = {
      _Tab.vehicle: t.reportVehicle,
      _Tab.party: t.reportParty,
      _Tab.trend: t.reportMonths,
      _Tab.expense: t.reportExpense,
    };
    return Column(
      children: [
        InkHeader(title: t.tabReport),
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: const MonthSwitcher(),
        ),
        SizedBox(
          height: 64,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final tab in _Tab.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AppChip(
                    label: labels[tab]!,
                    selected: _tab == tab,
                    onTap: () => setState(() => _tab = tab),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: switch (_tab) {
            _Tab.vehicle => _VehicleTab(month: key),
            _Tab.party => _PartyTab(month: key),
            _Tab.trend => _TrendTab(month: key),
            _Tab.expense => _ExpenseTab(month: key),
          },
        ),
      ],
    );
  }
}

/// Shared loading / error / refresh wrapper.
Widget _async<T>(
  BuildContext context,
  AsyncValue<T> value,
  VoidCallback retry,
  Widget Function(T data) build,
) {
  final t = AppL10n.of(context);
  return value.when(
    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
    error: (e, _) => ErrorRetry(
      message: errorMessage(t, e),
      retryLabel: t.retry,
      onRetry: retry,
    ),
    data: build,
  );
}

Widget _empty(BuildContext context, IconData icon, String text) => ListView(children: [
      const SizedBox(height: 80),
      Icon(icon, size: 56, color: AppColors.gold),
      const SizedBox(height: 12),
      Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500)),
    ]);

// ───────────────────────── Gaadi ─────────────────────────
class _VehicleTab extends ConsumerWidget {
  const _VehicleTab({required this.month});
  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final p = vehicleReportProvider(month);
    return _async<List<VehicleReport>>(context, ref.watch(p), () => ref.invalidate(p), (rows) {
      final top = rows.fold<double>(0, (m, r) => [m, r.income, r.expense].reduce((a, b) => a > b ? a : b));
      return RefreshIndicator(
        onRefresh: () async => ref.refresh(p.future),
        child: rows.isEmpty
            ? _empty(context, Icons.local_shipping_rounded, t.emptyVehicles)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (c, i) => _VehicleCard(row: rows[i], top: top),
              ),
      );
    });
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.row, required this.top});
  final VehicleReport row;
  final double top;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return ReportCard(
      onTap: () => context.push('/report/vehicle', extra: [row.id, row.name]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.name, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                    Text(row.number, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatRupees(row.profit),
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600, color: profitColor(row.profit))),
                  Text(t.profitLabel, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _BarRow(label: t.incomeLabel, value: row.income, top: top, color: AppColors.income),
          const SizedBox(height: 6),
          _BarRow(label: t.expenseLabel, value: row.expense, top: top, color: AppColors.expense),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              Text(t.tripsCount(row.trips), style: const TextStyle(fontSize: 15, color: AppColors.muted)),
              if (row.mileage != null)
                Text(t.mileageValue(row.mileage!.toStringAsFixed(1)),
                    style: const TextStyle(fontSize: 15, color: AppColors.muted)),
              if (row.km != null)
                Text(t.kmValue(row.km!), style: const TextStyle(fontSize: 15, color: AppColors.muted)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.top, required this.color});
  final String label;
  final double value;
  final double top;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          SizedBox(width: 64, child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted))),
          Expanded(child: MeterBar(fraction: top == 0 ? 0 : value / top, color: color)),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            child: Text(formatRupees(value),
                textAlign: TextAlign.right, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
          ),
        ],
      );
}

// ───────────────────────── Party ─────────────────────────
class _PartyTab extends ConsumerWidget {
  const _PartyTab({required this.month});
  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final p = partyReportProvider(month);
    return _async<List<PartyReport>>(context, ref.watch(p), () => ref.invalidate(p), (rows) {
      final top = rows.fold<double>(0, (m, r) => r.bhada > m ? r.bhada : m);
      return RefreshIndicator(
        onRefresh: () async => ref.refresh(p.future),
        child: rows.isEmpty
            ? _empty(context, Icons.people_alt_rounded, t.emptyReport)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: rows.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (c, i) {
                  final r = rows[i];
                  return ReportCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(r.name,
                                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                            ),
                            Text(t.tripsCount(r.trips),
                                style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _BarRow(label: t.bhadaLabel, value: r.bhada, top: top, color: AppColors.ink),
                        const SizedBox(height: 6),
                        _BarRow(label: t.receivedLabel, value: r.received, top: top, color: AppColors.income),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(t.homeDueCard,
                                  style: const TextStyle(fontSize: 15, color: AppColors.muted)),
                            ),
                            Text(formatRupees(r.balance),
                                style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w600,
                                    color: r.balance > 0 ? AppColors.expense : AppColors.income)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
      );
    });
  }
}

// ───────────────────────── Mahino ─────────────────────────
class _TrendTab extends ConsumerWidget {
  const _TrendTab({required this.month});
  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final p = trendProvider(month);
    return _async<List<TrendPoint>>(context, ref.watch(p), () => ref.invalidate(p), (pts) {
      final top = pts.fold<double>(0, (m, r) => [m, r.income, r.expense].reduce((a, b) => a > b ? a : b));
      return RefreshIndicator(
        onRefresh: () async => ref.refresh(p.future),
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: pts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (c, i) {
            final r = pts[pts.length - 1 - i]; // newest first
            return ReportCard(
              onTap: () {
                ref.read(selectedMonthProvider.notifier).set(r.month);
                context.push('/report/month');
              },
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(monthLabel(lang, r.month),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      ),
                      Text(formatRupees(r.profit),
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w600, color: profitColor(r.profit))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _BarRow(label: t.incomeLabel, value: r.income, top: top, color: AppColors.income),
                  const SizedBox(height: 6),
                  _BarRow(label: t.expenseLabel, value: r.expense, top: top, color: AppColors.expense),
                ],
              ),
            );
          },
        ),
      );
    });
  }
}

// ───────────────────────── Kharcha ─────────────────────────
class _ExpenseTab extends ConsumerWidget {
  const _ExpenseTab({required this.month});
  final String month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final p = expenseReportProvider(month);
    return _async<ExpenseReport>(context, ref.watch(p), () => ref.invalidate(p), (r) {
      return RefreshIndicator(
        onRefresh: () async => ref.refresh(p.future),
        child: r.categories.isEmpty
            ? _empty(context, Icons.receipt_long_rounded, t.emptyReport)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ReportCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(t.totalExpense,
                              style: const TextStyle(fontSize: 17, color: AppColors.muted)),
                        ),
                        Text(formatRupees(r.total),
                            style: const TextStyle(
                                fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.expense)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final c in r.categories) ...[
                    ReportCard(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(ExpenseCategory.fromKey(c.category).icon, color: AppColors.gold),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(ExpenseCategory.fromKey(c.category).label(t),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                              ),
                              Text(formatRupees(c.amount),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: MeterBar(
                                    fraction: r.total == 0 ? 0 : c.amount / r.total, color: AppColors.expense),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                  '${(r.total == 0 ? 0 : c.amount / r.total * 100).round()}%',
                                  style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
      );
    });
  }
}
