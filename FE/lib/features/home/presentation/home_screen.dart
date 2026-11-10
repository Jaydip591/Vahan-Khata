import 'package:flutter/material.dart';
import '../../../core/ui/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ink_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/money.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../ledger/data/ledger_repository.dart';
import '../../ledger/presentation/payment_sheet.dart';
import '../../reports/data/report.dart';
import '../../reports/data/report_repository.dart';
import '../../reports/presentation/month_switcher.dart';
import '../../reports/presentation/report_widgets.dart';
import 'week_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final auth = ref.watch(authControllerProvider);
    final name = auth is Authenticated ? auth.user.name : '';
    return Column(
      children: [
        InkHeader(
          title: t.appName,
          trailing: IconButton(
            tooltip: t.more,
            iconSize: 28,
            color: AppColors.gold,
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => context.push('/more'),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (name.isNotEmpty)
                Text(
                  t.hello(name),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              const SizedBox(height: 8),
              const _MonthHero(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.local_shipping_rounded,
                      label: t.newTrip,
                      onTap: () => context.push('/trip/new'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.local_gas_station_rounded,
                      label: t.tabKharcha,
                      onTap: () => context.go('/kharcha'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.payments_outlined,
                      label: t.receivePayment,
                      onTap: () => showPaymentSheet(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Material(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.go('/khata'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.homeDueCard,
                            style: const TextStyle(
                              color: AppColors.mutedOnInk,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          ref
                                      .watch(partyBalancesProvider)
                                      .asData
                                      ?.value
                                      .totalDue ==
                                  null
                              ? '—'
                              : formatRupees(
                                  ref
                                      .watch(partyBalancesProvider)
                                      .asData!
                                      .value
                                      .totalDue,
                                ),
                          style: const TextStyle(
                            color: AppColors.expenseOnInk,
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.mutedOnInk,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const WeekCard(),
              const SizedBox(height: 18),
              const _VehicleProfits(),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.ink,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.gold, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthHero extends ConsumerWidget {
  const _MonthHero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final key = monthKey(ref.watch(selectedMonthProvider));
    final p = summaryProvider(key);
    final s = ref.watch(p);
    return Material(
      color: AppColors.ink,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/report/month'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 4, 6, 16),
          child: Column(
            children: [
              const MonthSwitcher(onInk: true),
              s.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(8),
                  child: TextButton(
                    onPressed: () => ref.invalidate(p),
                    child: Text(
                      t.retry,
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ),
                data: (d) => Column(
                  children: [
                    Text(
                      t.homeProfit,
                      style: const TextStyle(
                        color: AppColors.mutedOnInk,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    CountUpRupees(
                      d.profit,
                      style: TextStyle(
                        color: d.profit < 0
                            ? AppColors.expenseOnInk
                            : AppColors.incomeOnInk,
                        fontSize: 38,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      t.vsLastMonth(formatRupees(d.prevProfit)),
                      style: const TextStyle(
                        color: AppColors.mutedOnInk,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        children: [
                          _HeroStat(
                            label: t.incomeLabel,
                            value: d.income,
                            color: AppColors.incomeOnInk,
                          ),
                          _HeroStat(
                            label: t.expenseLabel,
                            value: d.expense,
                            color: AppColors.expenseOnInk,
                          ),
                          _HeroStat(
                            label: t.collectedLabel,
                            value: d.collected,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 14),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: CountUpRupees(
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

class _VehicleProfits extends ConsumerWidget {
  const _VehicleProfits();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final key = monthKey(ref.watch(selectedMonthProvider));
    final rows =
        ref.watch(vehicleReportProvider(key)).asData?.value ??
        const <VehicleReport>[];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                t.vehicleProfitTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.go('/report'),
              child: Text(t.seeAll, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        for (final v in rows.take(5)) ...[
          ReportCard(
            onTap: () => context.push('/report/vehicle', extra: [v.id, v.name]),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        t.tripsCount(v.trips),
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
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
