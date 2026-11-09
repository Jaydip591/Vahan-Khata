import '../../reports/data/report_repository.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/defaults_store.dart';
import '../../../core/money.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_chip.dart';
import '../../../core/ui/date_chips.dart';
import '../../../core/ui/keypad.dart';
import '../../../core/ui/master_list.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/data/account_repository.dart';
import '../../pickers/account_chips.dart';
import '../../pickers/vehicle_chips.dart';
import '../../vehicles/data/vehicle_repository.dart';
import '../data/expense.dart';
import '../data/expense_repository.dart';

enum _Field { amount, liters, odometer }

/// Opens the quick expense sheet. Returns true if something was saved or deleted.
Future<bool?> showExpenseSheet(
  BuildContext context,
  ExpenseCategory category, {
  Expense? existing,
}) {
  return showAppSheet<bool>(
    context,
    (_) => ExpenseSheet(category: category, existing: existing),
  );
}

class ExpenseSheet extends ConsumerStatefulWidget {
  const ExpenseSheet({super.key, required this.category, this.existing});
  final ExpenseCategory category;
  final Expense? existing;

  @override
  ConsumerState<ExpenseSheet> createState() => _ExpenseSheetState();
}

class _ExpenseSheetState extends ConsumerState<ExpenseSheet> {
  String? _vehicleId;
  String? _accountId;
  RepairKind? _repairKind;
  DateTime _date = today();
  _Field _active = _Field.amount;
  String _amount = '';
  String _liters = '';
  String _odometer = '';
  bool _saving = false;
  String? _error;

  bool get _editing => widget.existing != null;
  bool get _isDiesel => widget.category == ExpenseCategory.diesel;
  bool get _isRepair => widget.category == ExpenseCategory.repair;

  String _trimNumber(num n) =>
      n == n.roundToDouble() ? n.round().toString() : n.toString();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final d = ref.read(defaultsProvider);
    if (e != null) {
      _vehicleId = e.vehicle.id;
      _accountId = e.accountId;
      _repairKind = e.repairKind;
      _date = DateTime(e.date.year, e.date.month, e.date.day);
      _amount = _trimNumber(e.amount);
      _liters = e.liters == null ? '' : _trimNumber(e.liters!);
      _odometer = e.odometer?.toString() ?? '';
    } else {
      _vehicleId = d.vehicleId;
      _accountId = d.accountId;
    }
  }

  void _press(String key) {
    final next = switch (_active) {
      _Field.amount => applyKey(_amount, key),
      _Field.liters => applyKey(_liters, key, decimal: true, maxDigits: 5),
      _Field.odometer => applyKey(_odometer, key, maxDigits: 7),
    };
    setState(() {
      switch (_active) {
        case _Field.amount:
          _amount = next;
        case _Field.liters:
          _liters = next;
        case _Field.odometer:
          _odometer = next;
      }
      _error = null;
    });
  }

  String _clean(String s) => s.endsWith('.') ? s.substring(0, s.length - 1) : s;

  Future<void> _save(String? vehicleId) async {
    final t = AppL10n.of(context);
    final amount = double.tryParse(_clean(_amount)) ?? 0;
    if (vehicleId == null) {
      setState(() => _error = t.chooseVehicle);
      return;
    }
    if (amount <= 0) {
      setState(() => _error = t.enterAmount);
      return;
    }
    final liters = double.tryParse(_clean(_liters)) ?? 0;
    setState(() {
      _saving = true;
      _error = null;
    });
    final input = ExpenseInput(
      vehicleId: vehicleId,
      category: widget.category,
      amount: _clean(_amount),
      date: _date,
      accountId: _accountId,
      liters: _isDiesel && liters > 0 ? _clean(_liters) : null,
      rate: _isDiesel && liters > 0
          ? (amount / liters).toStringAsFixed(2)
          : null,
      odometer: _isDiesel && _odometer.isNotEmpty
          ? int.tryParse(_odometer)
          : null,
      repairKind: _isRepair ? _repairKind : null,
    );
    try {
      final repo = ref.read(expenseRepositoryProvider);
      if (_editing) {
        await repo.update(widget.existing!.id, input);
      } else {
        await repo.create(input);
      }
      final defaults = ref.read(defaultsProvider);
      await defaults.setVehicle(vehicleId);
      if (_accountId != null) await defaults.setAccount(_accountId!);
      ref.invalidate(expensesProvider);
      invalidateReports(ref);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(SnackBar(content: Text(t.expenseSaved)));
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
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
      await ref.read(expenseRepositoryProvider).delete(widget.existing!.id);
      ref.invalidate(expensesProvider);
      invalidateReports(ref);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(t, e));
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 14, color: AppColors.muted),
    ),
  );

  Widget _fieldBox(
    _Field field,
    String label,
    String text, {
    String? suffix,
    bool big = false,
  }) {
    final selected = _active == field;
    return Expanded(
      child: Material(
        color: selected ? AppColors.goldSoft : AppColors.ivory,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: selected ? AppColors.gold : AppColors.line,
            width: 1.5,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _active = field),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                Text(
                  text.isEmpty
                      ? '0'
                      : '${field == _Field.amount ? '₹' : ''}${field == _Field.amount ? formatRupees(double.tryParse(_clean(text)) ?? 0, symbol: false) : text}${suffix ?? ''}',
                  style: TextStyle(
                    fontSize: big ? 28 : 20,
                    fontWeight: FontWeight.w500,
                    color: text.isEmpty
                        ? AppColors.muted
                        : (field == _Field.amount
                              ? AppColors.expense
                              : AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final vehicles = ref.watch(vehiclesProvider).asData?.value;
    final accounts = ref.watch(accountsProvider).asData?.value;
    final vehicleId = vehicles == null
        ? _vehicleId
        : (vehicles.any((v) => v.id == _vehicleId)
              ? _vehicleId
              : (vehicles.length == 1 ? vehicles.first.id : null));
    final accountId =
        (accounts == null || accounts.any((a) => a.id == _accountId))
        ? _accountId
        : null;
    if (accountId != _accountId) _accountId = accountId;

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
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.ink,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.category.icon, color: AppColors.gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.category.label(t),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (_editing)
                  IconButton(
                    tooltip: t.delete,
                    color: AppColors.expense,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: _delete,
                  ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label(t.vehicle),
                    VehicleChips(
                      selectedId: vehicleId,
                      onChanged: (v) => setState(() => _vehicleId = v.id),
                    ),
                    if (_isRepair) ...[
                      _label(t.repairKind),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final k in RepairKind.values)
                            AppChip(
                              label: k.label(t),
                              selected: _repairKind == k,
                              onTap: () => setState(
                                () => _repairKind = _repairKind == k ? null : k,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _fieldBox(
                          _Field.amount,
                          t.amountLabel,
                          _amount,
                          big: true,
                        ),
                        if (_isDiesel) ...[
                          const SizedBox(width: 8),
                          _fieldBox(_Field.liters, t.liters, _liters),
                          const SizedBox(width: 8),
                          _fieldBox(_Field.odometer, t.odometer, _odometer),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    KeypadPad(onKey: _press, decimal: _active == _Field.liters),
                    _label(t.dateLabel),
                    DateChips(
                      date: _date,
                      onChanged: (d) => setState(() => _date = d),
                    ),
                    _label(t.paidFrom),
                    AccountChips(
                      selectedId: accountId,
                      allowNone: true,
                      onChanged: (id) => setState(() => _accountId = id),
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
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontSize: 15,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            AppButton(
              label: t.save,
              loading: _saving,
              onPressed: () => _save(vehicleId),
            ),
          ],
        ),
      ),
    );
  }
}
