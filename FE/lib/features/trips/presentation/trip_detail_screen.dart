import '../../reports/data/report_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/ink_header.dart';
import '../../../core/ui/master_list.dart';
import '../../../core/ui/status_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/data/expense.dart';
import '../../expenses/data/expense_repository.dart';
import '../../expenses/presentation/expense_sheet.dart';
import '../../ledger/data/ledger_repository.dart';
import '../data/trip.dart';
import '../data/trip_repository.dart';
import 'trips_screen.dart' show payTag;

class TripDetailScreen extends ConsumerStatefulWidget {
  const TripDetailScreen({super.key, required this.trip});
  final Trip trip;

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  late Trip _trip = widget.trip;
  bool _busy = false;
  String? _error;

  void _refreshLists() {
    ref.invalidate(tripsProvider);
    invalidateReports(ref);
    ref.invalidate(partyBalancesProvider);
    ref.invalidate(partyLedgerProvider);
  }

  /// The edit form works on its own copy, so reload the trip when we come back.
  Future<void> _edit() async {
    await context.push('/trip/edit', extra: _trip);
    if (!mounted) return;
    try {
      final fresh = await ref.read(tripRepositoryProvider).get(_trip.id);
      if (mounted) setState(() => _trip = fresh);
    } catch (_) {
      // Keep showing what we had.
    }
  }

  Future<void> _toggleClosed() async {
    final t = AppL10n.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final updated = await ref
          .read(tripRepositoryProvider)
          .setClosed(_trip.id, !_trip.closed);
      _refreshLists();
      if (mounted) {
        setState(() {
          _trip = updated;
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = errorMessage(t, e);
        });
      }
    }
  }

  Future<void> _delete() async {
    final t = AppL10n.of(context);
    final ok = await confirmDialog(
      context,
      title: t.deleteConfirmTitle,
      body: t.deleteConfirmBody,
      confirmLabel: t.delete,
    );
    if (!ok) return;
    try {
      await ref.read(tripRepositoryProvider).delete(_trip.id);
      _refreshLists();
      ref.invalidate(recentRoutesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(t, e));
    }
  }

  Widget _row(String label, String value, {Color? color, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 16, color: AppColors.muted),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: bold ? 22 : 18,
                fontWeight: bold ? FontWeight.w500 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      );

  /// Fuel, toll, food... spent on this trip, with the profit left after them.
  Widget _expensesCard(AppL10n t, Trip trip) {
    final expenses = ref.watch(tripExpensesProvider(trip.id));
    final list = expenses.asData?.value ?? const <Expense>[];
    final total = list.fold<double>(0, (s, e) => s + e.amount);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.tripExpenses,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ),
              Text(formatRupees(total),
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.expense)),
            ],
          ),
          const SizedBox(height: 10),
          if (expenses.hasError)
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => ref.invalidate(tripExpensesProvider(trip.id)),
                child: Text(t.retry),
              ),
            )
          else if (list.isEmpty && expenses.hasValue)
            Text(t.noTripExpenses, style: const TextStyle(fontSize: 15, color: AppColors.muted)),
          for (final e in list)
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => showExpenseSheet(context, e.category, existing: e, trip: trip),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(e.category.icon, size: 22, color: AppColors.ink),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(e.category.label(t), style: const TextStyle(fontSize: 17)),
                    ),
                    Text(formatRupees(e.amount),
                        style: const TextStyle(fontSize: 17, color: AppColors.expense)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(t.addTripExpense, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in ExpenseCategory.tiles)
                ActionChip(
                  avatar: Icon(c.icon, size: 18, color: AppColors.gold),
                  backgroundColor: AppColors.ink,
                  side: BorderSide.none,
                  label: Text(c.tileLabel(t),
                      style: const TextStyle(color: Colors.white, fontSize: 15)),
                  onPressed: () => showExpenseSheet(context, c, trip: trip),
                ),
            ],
          ),
          if (list.isNotEmpty) ...[
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(t.tripNet,
                      style: const TextStyle(fontSize: 16, color: AppColors.muted)),
                ),
                Text(
                  formatRupees(trip.bhada - total),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    color: trip.bhada - total >= 0 ? AppColors.income : AppColors.expense,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final trip = _trip;
    return Scaffold(
      body: Column(
        children: [
          InkHeader(
            title: t.tripDetail,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              color: AppColors.gold,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            trailing: IconButton(
              tooltip: t.delete,
              color: AppColors.expenseOnInk,
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: _delete,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.ink2,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trip.from.nameFor(lang)} → ${trip.to.nameFor(lang)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${trip.party.name} · ${trip.vehicle.name} (${trip.vehicle.number ?? ''})',
                        style: const TextStyle(
                          color: AppColors.mutedOnInk,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        formatDay(trip.tripDate),
                        style: const TextStyle(
                          color: AppColors.mutedOnInk,
                          fontSize: 15,
                        ),
                      ),
                      if (trip.driver != null)
                        Text(
                          '${t.driver}: ${trip.driver!.name}',
                          style: const TextStyle(
                            color: AppColors.mutedOnInk,
                            fontSize: 15,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          payTag(t, trip),
                          StatusTag(
                            trip.closed ? t.statusClosed : t.statusRunning,
                            trip.closed ? TagKind.neutral : TagKind.good,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: AppColors.line),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _row(t.bhada, formatRupees(trip.bhada), bold: true),
                      const Divider(height: 1),
                      _row(
                        t.advanceLabel,
                        formatRupees(trip.advance),
                        color: AppColors.income,
                      ),
                      _row(
                        t.receivedLabel,
                        formatRupees(trip.paid),
                        color: AppColors.income,
                      ),
                      const Divider(height: 1),
                      _row(
                        t.balanceLeft,
                        formatRupees(trip.due),
                        color: trip.due > 0
                            ? AppColors.expense
                            : AppColors.income,
                        bold: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _expensesCard(t, trip),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.expense,
                        fontSize: 15,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Material(
            color: AppColors.ivory,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _edit,
                        child: Text(
                          t.editTrip,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AppButton(
                        label: trip.closed ? t.reopenTrip : t.closeTrip,
                        loading: _busy,
                        onPressed: _toggleClosed,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
