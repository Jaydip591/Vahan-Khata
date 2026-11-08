import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/money.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/ink_header.dart';
import '../../../core/ui/status_tag.dart';
import '../../../l10n/app_localizations.dart';
import '../data/ledger.dart';
import '../data/ledger_repository.dart';
import 'payment_sheet.dart';

int daysSince(DateTime d) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day).difference(DateTime(d.year, d.month, d.day)).inDays;
}

class KhataScreen extends ConsumerWidget {
  const KhataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final balances = ref.watch(partyBalancesProvider);
    return Column(
      children: [
        InkHeader(title: t.khataTitle),
        Expanded(
          child: balances.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
            error: (e, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(errorMessage(t, e), style: const TextStyle(fontSize: 17)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(partyBalancesProvider),
                    child: Text(t.retry),
                  ),
                ],
              ),
            ),
            data: (data) => RefreshIndicator(
              onRefresh: () async => ref.refresh(partyBalancesProvider.future),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.totalDue, style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text(
                          formatRupees(data.totalDue),
                          style: const TextStyle(
                            color: AppColors.expenseOnInk,
                            fontSize: 34,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (data.parties.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Column(
                        children: [
                          const Icon(Icons.groups_rounded, size: 56, color: AppColors.gold),
                          const SizedBox(height: 12),
                          Text(t.emptyParties,
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  for (final p in data.parties) ...[
                    _PartyTile(party: p),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ),
        Container(
          color: AppColors.ivory,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: AppButton(
                  label: t.receivePayment,
                  icon: Icons.payments_outlined,
                  onPressed: () => showPaymentSheet(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: () => context.push('/parties/new'),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(t.newPartyShort),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PartyTile extends StatelessWidget {
  const _PartyTile({required this.party});
  final PartyBalance party;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final owes = party.balance > 0;
    Widget tag;
    if (owes && party.oldestUnpaid != null) {
      final days = daysSince(party.oldestUnpaid!);
      tag = StatusTag(t.daysOld(days), days >= 10 ? TagKind.bad : (days >= 4 ? TagKind.warn : TagKind.neutral));
    } else if (party.balance < 0) {
      tag = StatusTag('${t.creditLabel} ${formatRupees(-party.balance)}', TagKind.good);
    } else {
      tag = StatusTag(t.settled, TagKind.good);
    }
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/party/${party.partyId}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFEFEBE2),
                child: Text(party.name.characters.first.toUpperCase(),
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500, color: AppColors.ink)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(party.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Align(alignment: Alignment.centerLeft, child: tag),
                  ],
                ),
              ),
              if (owes)
                Text(formatRupees(party.balance),
                    style: const TextStyle(
                        fontSize: 19, fontWeight: FontWeight.w500, color: AppColors.expense)),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}
