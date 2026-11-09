import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/month_names.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/ink_header.dart';
import '../../../core/ui/status_tag.dart';
import '../../../l10n/app_localizations.dart';
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

  void _shift(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final key = monthKey(_month);
    final trips = ref.watch(tripsProvider(key));
    return Column(
      children: [
        InkHeader(title: t.tabTrips),
        Container(
          color: Colors.white,
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
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
            error: (e, _) => Center(
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
            data: (list) => RefreshIndicator(
              onRefresh: () async => ref.refresh(tripsProvider(key).future),
              child: list.isEmpty
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
                      itemCount: list.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (c, i) =>
                          TripCard(trip: list[i], lang: lang),
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
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/trip/detail', extra: trip),
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
                style: const TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    formatDay(trip.tripDate),
                    style: const TextStyle(
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
    );
  }
}
