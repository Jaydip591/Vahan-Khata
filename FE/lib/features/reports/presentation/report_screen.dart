import 'package:flutter/material.dart';
import '../../../core/ui/empty_state.dart';
import '../../../core/ui/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/month_names.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_chip.dart';
import '../../../core/ui/ink_header.dart';
import '../../../core/ui/status_tag.dart';
import '../../export/export_sheet.dart';
import '../../export/statement_doc.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/data/expense.dart';
import '../data/report.dart';
import '../data/report_repository.dart';
import 'month_switcher.dart';
import 'report_widgets.dart';

enum _Tab { vehicle, party, trend, year, expense, balance }

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
      _Tab.year: t.reportYear,
      _Tab.expense: t.reportExpense,
      _Tab.balance: t.reportBalance,
    };
    return Column(
      children: [
        InkHeader(title: t.tabReport),
        if (_tab != _Tab.balance && _tab != _Tab.year)
          Container(
            color: AppColors.card,
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
            _Tab.year => const _YearTab(),
            _Tab.expense => _ExpenseTab(month: key),
            _Tab.balance => const _BalanceTab(),
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
      EmptyState(icon: icon, title: text, hint: AppL10n.of(context).emptyReportHint),
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
      return AppRefresh(
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
                    Text(row.number, style: TextStyle(fontSize: 14, color: AppColors.muted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatRupees(row.profit),
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600, color: profitColor(row.profit))),
                  Text(t.profitLabel, style: TextStyle(fontSize: 13, color: AppColors.muted)),
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
              Text(t.tripsCount(row.trips), style: TextStyle(fontSize: 15, color: AppColors.muted)),
              if (row.mileage != null)
                Text(row.mileageIsKg ? t.mileageKg(row.mileage!.toStringAsFixed(1)) : t.mileageValue(row.mileage!.toStringAsFixed(1)),
                    style: TextStyle(fontSize: 15, color: AppColors.muted)),
              if (row.km != null)
                Text(t.kmValue(row.km!), style: TextStyle(fontSize: 15, color: AppColors.muted)),
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
          SizedBox(width: 64, child: Text(label, style: TextStyle(fontSize: 14, color: AppColors.muted))),
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
      return AppRefresh(
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
                                style: TextStyle(fontSize: 14, color: AppColors.muted)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _BarRow(label: t.bhadaLabel, value: r.bhada, top: top, color: AppColors.text),
                        const SizedBox(height: 6),
                        _BarRow(label: t.receivedLabel, value: r.received, top: top, color: AppColors.income),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Text(t.homeDueCard,
                                  style: TextStyle(fontSize: 15, color: AppColors.muted)),
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
      return AppRefresh(
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
      return AppRefresh(
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
                              style: TextStyle(fontSize: 17, color: AppColors.muted)),
                        ),
                        Text(formatRupees(r.total),
                            style: TextStyle(
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
                                  style: TextStyle(fontSize: 14, color: AppColors.muted)),
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

// ───────────────────────── Balance ─────────────────────────
/// Money in each account, all time: opening + received - spent.
class _BalanceTab extends ConsumerWidget {
  const _BalanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final p = accountBalancesProvider;
    return _async<AccountBalances>(context, ref.watch(p), () => ref.invalidate(p), (r) {
      return AppRefresh(
        onRefresh: () async => ref.refresh(p.future),
        child: r.accounts.isEmpty
            ? _empty(context, Icons.account_balance_wallet_rounded, t.emptyAccounts)
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ReportCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.balanceTotal, style: TextStyle(fontSize: 17, color: AppColors.muted)),
                              Text(t.balanceAllTime, style: TextStyle(fontSize: 13, color: AppColors.muted)),
                            ],
                          ),
                        ),
                        Text(formatRupees(r.total),
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: profitColor(r.total))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (final a in r.accounts) ...[
                    _AccountCard(row: a),
                    const SizedBox(height: 10),
                  ],
                  if (r.unassignedSpent > 0)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                      child: Text(t.balanceNoAccount(formatRupees(r.unassignedSpent)),
                          style: TextStyle(fontSize: 14, color: AppColors.muted)),
                    ),
                ],
              ),
      );
    });
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.row});
  final AccountBalance row;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final icon = switch (row.kind) {
      'bank' => Icons.account_balance_rounded,
      'upi' => Icons.qr_code_2_rounded,
      _ => Icons.payments_rounded,
    };
    Widget part(String label, double value, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 13, color: AppColors.muted)),
              Text(formatRupees(value), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: color)),
            ],
          ),
        );
    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.gold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(row.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              if (!row.isActive) ...[StatusTag(t.inactiveTag, TagKind.neutral), const SizedBox(width: 8)],
              Text(formatRupees(row.balance),
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: profitColor(row.balance))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              part(t.balanceOpening, row.opening, AppColors.text),
              part(t.balanceIn, row.received, AppColors.income),
              part(t.balanceOut, row.spent, AppColors.expense),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Varsh (financial year) ─────────────────────────
class _YearTab extends ConsumerWidget {
  const _YearTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final fy = ref.watch(selectedFyProvider);
    final p = yearReportProvider(fy);
    final switcher = Container(
      color: AppColors.card,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: t.fyPrev,
            color: AppColors.text,
            icon: const Icon(Icons.chevron_left_rounded, size: 30),
            onPressed: () => ref.read(selectedFyProvider.notifier).shift(-1),
          ),
          Expanded(
            child: Column(
              children: [
                Text(t.fyLabel('$fy-${((fy + 1) % 100).toString().padLeft(2, '0')}'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                Text(t.fyRange('$fy', '${fy + 1}'),
                    style: TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ),
          ),
          IconButton(
            tooltip: t.fyNext,
            color: AppColors.text,
            icon: const Icon(Icons.chevron_right_rounded, size: 30),
            onPressed: fy >= fyOf(DateTime.now()) ? null : () => ref.read(selectedFyProvider.notifier).shift(1),
          ),
        ],
      ),
    );
    return Column(
      children: [
        switcher,
        Expanded(
          child: _async<YearReport>(context, ref.watch(p), () => ref.invalidate(p), (y) {
            final top = y.months.fold<double>(0, (m, r) => [m, r.income, r.expense].reduce((a, b) => a > b ? a : b));
            return AppRefresh(
              onRefresh: () async => ref.refresh(p.future),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _YearHero(y: y),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => showExportSheet(
                      context,
                      () async => yearDoc(t, lang, y, (d) => monthLabel(lang, d)),
                    ),
                    icon: const Icon(Icons.ios_share_rounded),
                    label: Text(t.shareYear),
                  ),
                  const SizedBox(height: 18),
                  Text(t.byMonth, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  for (final m in y.months.reversed.where((m) => m.trips > 0 || m.expense > 0 || m.collected > 0)) ...[
                    ReportCard(
                      onTap: () {
                        ref.read(selectedMonthProvider.notifier).set(m.month);
                        context.push('/report/month');
                      },
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(monthLabel(lang, m.month),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                              ),
                              Text(formatRupees(m.profit),
                                  style: TextStyle(
                                      fontSize: 20, fontWeight: FontWeight.w600, color: profitColor(m.profit))),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _BarRow(label: t.incomeLabel, value: m.income, top: top, color: AppColors.income),
                          const SizedBox(height: 6),
                          _BarRow(label: t.expenseLabel, value: m.expense, top: top, color: AppColors.expense),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (y.trips == 0 && y.expense == 0)
                    EmptyState(icon: Icons.calendar_month_rounded, title: t.emptyReport, topGap: 8),
                  if (y.vehicles.any((v) => v.trips > 0 || v.expense > 0)) ...[
                    const SizedBox(height: 8),
                    Text(t.byVehicle, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    for (final v in y.vehicles.where((v) => v.trips > 0 || v.expense > 0)) ...[
                      ReportCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(v.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                                  Text(t.tripsCount(v.trips), style: TextStyle(fontSize: 14, color: AppColors.muted)),
                                ],
                              ),
                            ),
                            Text(formatRupees(v.profit),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: profitColor(v.profit))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _YearHero extends StatelessWidget {
  const _YearHero({required this.y});
  final YearReport y;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    Widget stat(String label, double v, Color c) => Expanded(
          child: Column(
            children: [
              Text(label, style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 14)),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(formatRupees(v), style: TextStyle(color: c, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: [
          Text(t.yearProfit, style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 15)),
          CountUpRupees(
            y.profit,
            style: TextStyle(
              color: y.profit < 0 ? AppColors.expenseOnInk : AppColors.incomeOnInk,
              fontSize: 34,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(t.tripsCount(y.trips), style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 14)),
          const SizedBox(height: 12),
          Row(
            children: [
              stat(t.incomeLabel, y.income, AppColors.incomeOnInk),
              stat(t.expenseLabel, y.expense, AppColors.expenseOnInk),
              stat(t.collectedLabel, y.collected, Colors.white),
            ],
          ),
        ],
      ),
    );
  }
}
