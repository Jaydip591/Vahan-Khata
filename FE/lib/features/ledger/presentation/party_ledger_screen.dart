import '../../reports/data/report_repository.dart';

import 'package:flutter/material.dart';
import '../../../core/ui/motion.dart';
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
import '../../trips/data/trip.dart';
import '../../trips/data/trip_repository.dart';
import '../../export/export_sheet.dart';
import '../../export/statement_doc.dart';
import '../data/ledger.dart';
import '../data/ledger_repository.dart';
import 'payment_sheet.dart';

class PartyLedgerScreen extends ConsumerWidget {
  const PartyLedgerScreen({super.key, required this.partyId});
  final String partyId;

  Future<void> _openTrip(
    BuildContext context,
    WidgetRef ref,
    String tripId,
  ) async {
    try {
      final trip = await ref.read(tripRepositoryProvider).get(tripId);
      if (context.mounted) context.push('/trip/detail', extra: trip);
    } catch (_) {
      // Stay on the khata if the trip can't be loaded.
    }
  }

  Future<void> _deletePayment(
    BuildContext context,
    WidgetRef ref,
    LedgerPayment p,
  ) async {
    final t = AppL10n.of(context);
    final ok = await confirmDialog(
      context,
      title: t.deletePaymentTitle,
      body: t.deleteConfirmBody,
      confirmLabel: t.delete,
    );
    if (!ok) return;
    try {
      await ref.read(ledgerRepositoryProvider).deletePayment(p.id);
      ref.invalidate(partyLedgerProvider);
      ref.invalidate(partyBalancesProvider);
      ref.invalidate(tripsProvider);
      invalidateReports(ref);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(errorMessage(t, e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final ledger = ref.watch(partyLedgerProvider(partyId));
    return Scaffold(
      body: Column(
        children: [
          InkHeader(
            title: ledger.asData?.value.name ?? t.khataTitle,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              color: AppColors.gold,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            trailing: ledger.asData?.value == null
                ? null
                : IconButton(
                    tooltip: t.exportTitle,
                    color: AppColors.gold,
                    iconSize: 26,
                    icon: const Icon(Icons.ios_share_rounded),
                    onPressed: () {
                      final lang = Localizations.localeOf(context).languageCode;
                      final data = ledger.asData!.value;
                      showExportSheet(
                        context,
                        () async =>
                            partyStatementDoc(t, lang, data, DateTime.now()),
                      );
                    },
                  ),
          ),
          Expanded(
            child: ledger.when(
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
                      onPressed: () =>
                          ref.invalidate(partyLedgerProvider(partyId)),
                      child: Text(t.retry),
                    ),
                  ],
                ),
              ),
              data: (l) => AppRefresh(
                onRefresh: () async =>
                    ref.refresh(partyLedgerProvider(partyId).future),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.balance < 0 ? t.creditLabel : t.balanceLeft,
                            style: const TextStyle(
                              color: AppColors.mutedOnInk,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            formatRupees(l.balance.abs()),
                            style: TextStyle(
                              color: l.balance > 0
                                  ? AppColors.gold
                                  : AppColors.incomeOnInk,
                              fontSize: 34,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${t.totalBhada} ${formatRupees(l.totalBhada)}  ·  ${t.totalReceived} ${formatRupees(l.totalPaid)}',
                            style: const TextStyle(
                              color: AppColors.mutedOnInk,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    AppButton(
                      label: t.receivePayment,
                      icon: Icons.payments_outlined,
                      onPressed: () =>
                          showPaymentSheet(context, partyId: partyId),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      t.tripsHeading,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final trip in l.trips) ...[
                      MasterTile(
                        icon: Icons.local_shipping_outlined,
                        title:
                            '${trip.from.nameFor(lang)} → ${trip.to.nameFor(lang)}',
                        subtitle:
                            '${formatDay(trip.date)} · ${trip.vehicleName}',
                        trailing: Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatRupees(trip.bhada),
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              switch (trip.status) {
                                PayStatus.paid => StatusTag(
                                  t.payPaid,
                                  TagKind.good,
                                ),
                                PayStatus.partial => StatusTag(
                                  '${t.balanceLeft} ${formatRupees(trip.due)}',
                                  TagKind.warn,
                                ),
                                PayStatus.unpaid => StatusTag(
                                  '${t.payUnpaid} ${formatRupees(trip.due)}',
                                  TagKind.bad,
                                ),
                              },
                            ],
                          ),
                        ),
                        onTap: () => _openTrip(context, ref, trip.id),
                      ),
                      const SizedBox(height: 8),
                    ],
                    if (l.payments.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        t.paymentsHeading,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final p in l.payments) ...[
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AppColors.line),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '+${formatRupees(p.amount)}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.income,
                                      ),
                                    ),
                                    Text(
                                      '${formatDay(p.date)} · ${p.accountName}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (p.isAdvance)
                                StatusTag(t.advanceTag, TagKind.neutral),
                              IconButton(
                                tooltip: t.delete,
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: AppColors.muted,
                                ),
                                onPressed: () =>
                                    _deletePayment(context, ref, p),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
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
