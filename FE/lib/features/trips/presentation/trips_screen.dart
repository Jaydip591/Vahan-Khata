import 'package:flutter/material.dart';
import '../../../core/ui/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/month_names.dart';
import '../../../core/network/api_error.dart';
import '../../../core/haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/swipe_delete.dart';
import '../../expenses/data/expense_repository.dart';
import '../../ledger/data/ledger_repository.dart';
import '../../reports/data/report_repository.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/ink_header.dart';
import '../../../core/ui/status_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../../outbox/outbox_controller.dart';
import '../../outbox/outbox_item.dart';
import '../../outbox/pending_widgets.dart';
import '../data/trip.dart';
import '../data/trip_repository.dart';

/// Tag for how much of a trip is still to be received.
Widget payTag(AppL10n t, Trip trip) => switch (trip.payStatus) {
  PayStatus.paid => StatusTag(t.payPaid, TagKind.good),
  PayStatus.partial => StatusTag(
    '${t.payPartial} · ${t.balanceLeft} ${formatRupees(trip.due)}',
    TagKind.warn,
  ),
  PayStatus.unpaid => StatusTag(
    '${t.payUnpaid} ${formatRupees(trip.due)}',
    TagKind.bad,
  ),
};

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  final _gone = <String>{}; // trips swiped away, hidden until the list reloads

  void _shift(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  List<Trip> shown(List<Trip> all) => all.where((t) => !_gone.contains(t.id)).toList();

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final key = monthKey(_month);
    final trips = ref.watch(tripsProvider(key));
    final waiting = ref
        .watch(outboxProvider)
        .where((i) => i.kind == OutboxKind.trip && monthKey(i.date) == key)
        .toList();
    return Column(
      children: [
        InkHeader(title: t.tabTrips),
        Container(
          color: AppColors.card,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: t.monthPrev,
                icon: const Icon(Icons.chevron_left_rounded, size: 30),
                onPressed: () => _shift(-1),
              ),
              Expanded(
                child: Text(
                  monthLabel(lang, _month),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              IconButton(
                tooltip: t.monthNext,
                icon: const Icon(Icons.chevron_right_rounded, size: 30),
                onPressed: () => _shift(1),
              ),
            ],
          ),
        ),
        Expanded(
          child: trips.when(
            loading: () => const SkeletonList(),
            error: (e, _) => ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final w in waiting) ...[
                  PendingTile(item: w),
                  const SizedBox(height: 10),
                ],
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        errorMessage(t, e),
                        style: const TextStyle(fontSize: 17),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(tripsProvider(key)),
                        child: Text(t.retry),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            data: (list) => AppRefresh(
              onRefresh: () async => ref.refresh(tripsProvider(key).future),
              child: (shown(list).isEmpty && waiting.isEmpty)
                  ? ListView(
                      children: [
                        const SizedBox(height: 80),
                        const Icon(
                          Icons.local_shipping_rounded,
                          size: 56,
                          color: AppColors.gold,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.emptyTrips,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: waiting.length + shown(list).length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (c, i) {
                        if (i < waiting.length) return PendingTile(item: waiting[i]);
                        final trip = shown(list)[i - waiting.length];
                        return EntryFade(
                          index: i,
                          child: SwipeDelete(
                            key: ValueKey(trip.id),
                            onDelete: () => ref.read(tripRepositoryProvider).delete(trip.id),
                            onGone: () {
                              setState(() => _gone.add(trip.id));
                              ref.invalidate(tripsProvider);
                              invalidateReports(ref);
                              ref.invalidate(partyBalancesProvider);
                              ref.invalidate(partyLedgerProvider);
                              ref.invalidate(recentRoutesProvider);
                              ref.invalidate(expensesProvider);
                            },
                            child: TripCard(trip: trip, lang: lang),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
        Container(
          color: AppColors.ivory,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: AppButton(
            label: t.newTrip,
            icon: Icons.add_rounded,
            onPressed: () => context.push('/trip/new'),
          ),
        ),
      ],
    );
  }
}

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, required this.lang});
  final Trip trip;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return PressScale(child: Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Haptics.tap();
          context.push('/trip/detail', extra: trip);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '${trip.from.nameFor(lang)} → ${trip.to.nameFor(lang)}',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatRupees(trip.bhada),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${trip.party.name} · ${trip.vehicle.name}',
                style: TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    formatDay(trip.tripDate),
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (trip.closed) StatusTag(t.statusClosed, TagKind.neutral),
                  const Spacer(),
                  payTag(t, trip),
                ],
              ),
            ],
          ),
        ),
      ),
    ));
  }
}
