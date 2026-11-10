import '../../reports/data/report_repository.dart';

import 'package:flutter/material.dart';
import '../../../core/haptics.dart';
import '../../../core/ui/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/defaults_store.dart';
import '../../../core/money.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_chip.dart';
import '../../../core/ui/date_chips.dart';
import '../../../core/ui/keypad.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/data/account_repository.dart';
import '../../pickers/account_chips.dart';
import '../../trips/data/trip_repository.dart';
import '../../parties/data/party_repository.dart';
import '../../outbox/outbox_controller.dart';
import '../../outbox/outbox_item.dart';
import '../../../core/ids.dart';
import '../data/ledger.dart';
import '../data/ledger_repository.dart';

/// "Payment received" sheet. Pass [partyId] to start with that party chosen.
/// Returns true if a payment was saved.
Future<bool?> showPaymentSheet(BuildContext context, {String? partyId}) {
  return showAppSheet<bool>(context, (_) => PaymentSheet(partyId: partyId));
}

enum _Amt { all, half, custom }

class PaymentSheet extends ConsumerStatefulWidget {
  const PaymentSheet({super.key, this.partyId});
  final String? partyId;

  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  String? _partyId;
  _Amt _amt = _Amt.all;
  int _custom = 0;
  String _mode = 'cash';
  String? _accountId;
  DateTime _date = today();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = ref.read(defaultsProvider);
    _partyId = widget.partyId;
    _mode = d.payMode;
    _accountId = d.accountId;
  }

  int _amountFor(double balance) {
    final owed = balance > 0 ? balance.round() : 0;
    return switch (_amt) {
      _Amt.all => owed,
      _Amt.half => (owed / 2).round(),
      _Amt.custom => _custom,
    };
  }

  Future<void> _pickAmount(_Amt choice, double balance) async {
    final t = AppL10n.of(context);
    if (choice == _Amt.custom) {
      final v = await showAmountSheet(
        context,
        title: t.howMuch,
        initial: _custom,
      );
      if (v == null || !mounted) return;
      setState(() {
        _custom = v;
        _amt = _Amt.custom;
      });
    } else {
      setState(() => _amt = choice);
    }
  }

  Future<void> _save(String? partyId, String? accountId, double balance) async {
    final t = AppL10n.of(context);
    final amount = _amountFor(balance);
    String? problem;
    if (partyId == null) {
      problem = t.chooseParty;
    } else if (amount <= 0) {
      problem = t.enterAmount;
    } else if (accountId == null) {
      final noAccounts =
          ref.read(accountsProvider).asData?.value.isEmpty ?? false;
      problem = noAccounts ? t.needAccountFirst : t.chooseAccount;
    }
    if (problem != null) {
      Haptics.error();
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final party = ref.read(partiesProvider).asData?.value.where((p) => p.id == partyId).firstOrNull;
      final out = await ref.read(outboxProvider.notifier).save(OutboxItem(
            kind: OutboxKind.payment,
            body: {
              'id': newId(),
              'party_id': partyId,
              'amount': amount.toString(),
              'mode': _mode,
              'account_id': accountId,
              'paid_on': dateKey(_date),
            },
            title: party?.name ?? '',
            subtitle: t.receivePayment,
            amount: amount.toDouble(),
            date: _date,
          ));
      final queued = out == SaveOutcome.queued;
      final defaults = ref.read(defaultsProvider);
      await defaults.setAccount(accountId!);
      await defaults.setPayMode(_mode);
      await defaults.setParty(partyId!);
      ref.invalidate(partyBalancesProvider);
      ref.invalidate(partyLedgerProvider);
      ref.invalidate(tripsProvider);
      invalidateReports(ref);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Haptics.success();
      showSavedTick(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(SnackBar(content: Text(queued ? t.savedOffline : t.paymentSaved)));
    } catch (e) {
      if (mounted) {
        Haptics.error();
        setState(() {
          _saving = false;
          _error = errorMessage(t, e);
        });
      }
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Text(
      text,
      style: TextStyle(fontSize: 14, color: AppColors.muted),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final balances = ref.watch(partyBalancesProvider);
    final accounts = ref.watch(accountsProvider).asData?.value;
    final parties = balances.asData?.value.parties ?? const <PartyBalance>[];

    final partyId = parties.any((p) => p.partyId == _partyId)
        ? _partyId
        : (parties.length == 1 ? parties.first.partyId : null);
    final selected = parties.where((p) => p.partyId == partyId).firstOrNull;
    final balance = selected?.balance ?? 0;
    final accountId =
        (accounts == null || accounts.any((a) => a.id == _accountId))
        ? _accountId
        : (accounts.length == 1 ? accounts.first.id : null);
    final amount = _amountFor(balance);
    final left = balance - amount;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.94,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SheetHandle(),
            const SizedBox(height: 10),
            Text(
              t.receivePayment,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(t.whoPaid),
                    if (balances.isLoading)
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        ),
                      )
                    else if (balances.hasError)
                      OutlinedButton(
                        onPressed: () => ref.invalidate(partyBalancesProvider),
                        child: Text(t.retry),
                      )
                    else if (parties.isEmpty)
                      Text(
                        t.noPartyYet,
                        style: TextStyle(
                          color: AppColors.expense,
                          fontSize: 15,
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final p in parties) ...[
                            _PartyRow(
                              party: p,
                              selected: p.partyId == partyId,
                              onTap: () => setState(() => _partyId = p.partyId),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ],
                      ),
                    _label(t.howMuch),
                    Row(
                      children: [
                        for (final (choice, label) in [
                          (_Amt.all, t.payAll),
                          (_Amt.half, t.payHalf),
                          (_Amt.custom, t.payCustom),
                        ]) ...[
                          Expanded(
                            child: AppChip(
                              label: label,
                              selected: _amt == choice,
                              expand: true,
                              onTap: () => _pickAmount(choice, balance),
                            ),
                          ),
                          if (choice != _Amt.custom) const SizedBox(width: 6),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.ink,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.willCredit,
                                  style: const TextStyle(
                                    color: AppColors.mutedOnInk,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  formatRupees(amount),
                                  style: const TextStyle(
                                    color: AppColors.gold,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  left < 0 ? t.creditLabel : t.remaining,
                                  style: const TextStyle(
                                    color: AppColors.mutedOnInk,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  formatRupees(left.abs()),
                                  style: TextStyle(
                                    color: left > 0
                                        ? AppColors.expenseOnInk
                                        : AppColors.incomeOnInk,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    _label(t.howReceived),
                    Row(
                      children: [
                        Expanded(
                          child: AppChip(
                            label: t.modeCash,
                            icon: Icons.payments_outlined,
                            selected: _mode == 'cash',
                            expand: true,
                            onTap: () => setState(() => _mode = 'cash'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppChip(
                            label: t.modeOnline,
                            icon: Icons.phone_android_rounded,
                            selected: _mode == 'online',
                            expand: true,
                            onTap: () => setState(() => _mode = 'online'),
                          ),
                        ),
                      ],
                    ),
                    _label(t.whichAccount),
                    AccountChips(
                      selectedId: accountId,
                      onChanged: (id) => setState(() => _accountId = id),
                    ),
                    _label(t.dateLabel),
                    DateChips(
                      date: _date,
                      onChanged: (d) => setState(() => _date = d),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _error!,
                  style: TextStyle(
                    color: AppColors.expense,
                    fontSize: 15,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            AppButton(
              label: t.save,
              loading: _saving,
              onPressed: () => _save(partyId, accountId, balance),
            ),
          ],
        ),
      ),
    );
  }
}

class _PartyRow extends StatelessWidget {
  const _PartyRow({
    required this.party,
    required this.selected,
    required this.onTap,
  });
  final PartyBalance party;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selected : AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: selected ? AppColors.selected : AppColors.fieldLine,
          width: 1.5,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  party.name,
                  style: TextStyle(
                    fontSize: 17,
                    color: selected ? AppColors.onSelected : AppColors.text,
                    fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ),
              if (party.balance > 0)
                Text(
                  formatRupees(party.balance),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? AppColors.expenseOnInk
                        : AppColors.expense,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
