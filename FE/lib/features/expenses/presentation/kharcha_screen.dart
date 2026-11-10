import 'package:flutter/material.dart';
import '../../../core/ui/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ink_header.dart';
import '../../../core/ui/master_list.dart';
import '../../../core/ui/swipe_delete.dart';
import '../../reports/data/report_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../outbox/outbox_controller.dart';
import '../../outbox/outbox_item.dart';
import '../../outbox/pending_widgets.dart';
import '../data/expense.dart';
import '../data/expense_repository.dart';
import 'expense_sheet.dart';

class KharchaScreen extends ConsumerStatefulWidget {
  const KharchaScreen({super.key});

  @override
  ConsumerState<KharchaScreen> createState() => _KharchaScreenState();
}

class _KharchaScreenState extends ConsumerState<KharchaScreen> {
  final _gone = <String>{}; // swiped away, hidden until the list reloads

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final key = monthKey(DateTime.now());
    final expenses = ref.watch(expensesProvider(key));
    return Column(
      children: [
        InkHeader(title: t.tabKharcha),
        Expanded(
          child: AppRefresh(
            onRefresh: () async => ref.refresh(expensesProvider(key).future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(t.whatExpense, style: TextStyle(fontSize: 16, color: AppColors.muted)),
                const SizedBox(height: 10),
                GridView.count(
                  padding: EdgeInsets.zero,
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                  children: [
                    for (final c in ExpenseCategory.tiles)
                      Material(
                        color: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                          side: BorderSide(color: AppColors.line),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => showExpenseSheet(context, c),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                                child: Icon(c.icon, color: AppColors.gold, size: 28),
                              ),
                              const SizedBox(height: 8),
                              Text(c.tileLabel(t),
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                expenses.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
                  error: (e, _) => Column(
                    children: [
                      Text(errorMessage(t, e), style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(expensesProvider(key)),
                        child: Text(t.retry),
                      ),
                    ],
                  ),
                  data: (list) {
                    final waiting = ref
                        .watch(outboxProvider)
                        .where((i) => i.kind == OutboxKind.expense && monthKey(i.date) == key)
                        .toList();
                    if (list.isEmpty && waiting.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(t.emptyExpenses,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16, color: AppColors.muted)),
                      );
                    }
                    final total = list.fold<double>(0, (a, e) => a + e.amount);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(t.recentExpenses,
                                    style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 15)),
                              ),
                              Text(formatRupees(total),
                                  style: const TextStyle(
                                    color: AppColors.expenseOnInk,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w500,
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final w in waiting) ...[
                          PendingTile(item: w),
                          const SizedBox(height: 8),
                        ],
                        for (final (i, e) in list.where((x) => !_gone.contains(x.id)).indexed) ...[
                          EntryFade(index: i, child: SwipeDelete(
                            key: ValueKey(e.id),
                            onDelete: () => ref.read(expenseRepositoryProvider).delete(e.id),
                            onGone: () {
                              setState(() => _gone.add(e.id));
                              ref.invalidate(expensesProvider);
                              ref.invalidate(tripExpensesProvider);
                              invalidateReports(ref);
                            },
                            child: MasterTile(
                            icon: e.category.icon,
                            title: e.category.label(t),
                            subtitle: '${e.vehicle.name} · ${formatDay(e.date)}${e.tripId != null ? ' · ${t.forTrip}' : ''}',
                            trailing: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text(formatRupees(e.amount),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.expense,
                                  )),
                            ),
                            onTap: () => showExpenseSheet(context, e.category, existing: e),
                          ))),
                          const SizedBox(height: 8),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
