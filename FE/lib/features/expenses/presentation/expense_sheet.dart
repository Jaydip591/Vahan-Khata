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
import '../../../core/ui/master_list.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/data/account.dart';
import '../../accounts/data/account_repository.dart';
import '../../upi/data/payee.dart';
import '../../upi/data/upi_service.dart';
import '../../upi/presentation/payee_picker.dart';
import '../../pickers/account_chips.dart';
import '../../pickers/vehicle_chips.dart';
import '../../vehicles/data/vehicle_repository.dart';
import '../../outbox/outbox_controller.dart';
import '../../outbox/outbox_item.dart';
import '../../../core/ids.dart';
import '../../trips/data/trip.dart';
import '../data/expense.dart';
import '../data/expense_repository.dart';

enum _Field { amount, liters, odometer }

/// Opens the quick expense sheet. Returns true if something was saved or deleted.
Future<bool?> showExpenseSheet(
  BuildContext context,
  ExpenseCategory category, {
  Expense? existing,
  Trip? trip,
}) {
  return showAppSheet<bool>(
    context,
    (_) => ExpenseSheet(category: category, existing: existing, trip: trip),
  );
}

class ExpenseSheet extends ConsumerStatefulWidget {
  const ExpenseSheet({super.key, required this.category, this.existing, this.trip});
  final ExpenseCategory category;
  final Expense? existing;

  /// When set, the expense belongs to this trip: its vehicle and date are used.
  final Trip? trip;

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
  late ExpenseCategory _category = widget.existing?.category ?? widget.category;
  bool _fuelPicked = false; // the user chose a fuel chip, so stop following the vehicle's default
  bool get _isFuel => _category.isFuel;
  bool get _isFuelSheet => widget.category.isFuel;
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
      _vehicleId = widget.trip?.vehicle.id ?? d.vehicleId;
      _accountId = d.accountId;
      if (widget.trip != null) _date = widget.trip!.tripDate.isAfter(today()) ? today() : widget.trip!.tripDate;
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

  /// Checks vehicle and amount; shows the problem and returns false when something is missing.
  bool _ready(String? vehicleId) {
    final t = AppL10n.of(context);
    final amount = double.tryParse(_clean(_amount)) ?? 0;
    if (vehicleId == null) {
      Haptics.error();
      setState(() => _error = t.chooseVehicle);
      return false;
    }
    if (amount <= 0) {
      Haptics.error();
      setState(() => _error = t.enterAmount);
      return false;
    }
    return true;
  }

  /// Pay by UPI: choose who, open Google Pay with the amount, and save the expense only when
  /// the payment went through (or the person confirms it did).
  Future<void> _payByUpi(String? vehicleId) async {
    if (!_ready(vehicleId)) return;
    final t = AppL10n.of(context);
    final payee = await showPayeePicker(context);
    if (payee == null || !mounted) return;
    final id = newId();
    setState(() {
      _saving = true;
      _error = null;
    });
    final result = await ref.read(upiServiceProvider).pay(upiPayUri(
          upiId: payee.upiId,
          name: payee.name,
          amount: _clean(_amount),
          note: 'Vahan Khata - ${_category.label(t)}',
          txnRef: id.replaceAll('-', ''),
        ));
    if (!mounted) return;
    var paid = result.status == UpiStatus.success;
    if (result.status == UpiStatus.pending || result.status == UpiStatus.unknown) {
      paid = await confirmDialog(context, title: t.upiAskTitle, body: t.upiAskBody, confirmLabel: t.yes);
      if (!mounted) return;
    }
    if (!paid) {
      Haptics.error();
      setState(() {
        _saving = false;
        _error = result.status == UpiStatus.noApp ? t.upiNoApp : t.upiFailed;
      });
      return;
    }
    final accounts = ref.read(accountsProvider).asData?.value ?? const [];
    final current = accounts.where((a) => a.id == _accountId).firstOrNull;
    if (current?.kind != AccountKind.upi) {
      final upi = accounts.where((a) => a.kind == AccountKind.upi && a.isActive).firstOrNull;
      if (upi != null) _accountId = upi.id;
    }
    await _save(vehicleId, upi: (id: id, payee: payee, ref: result.ref));
  }

  Future<void> _save(String? vehicleId, {({String id, Payee payee, String? ref})? upi}) async {
    final t = AppL10n.of(context);
    if (!_ready(vehicleId)) return;
    if (vehicleId == null) return;
    final amount = double.tryParse(_clean(_amount)) ?? 0;
    final liters = double.tryParse(_clean(_liters)) ?? 0;
    setState(() {
      _saving = true;
      _error = null;
    });
    final input = ExpenseInput(
      vehicleId: vehicleId,
      category: _category,
      amount: _clean(_amount),
      date: _date,
      tripId: widget.trip?.id ?? widget.existing?.tripId,
      accountId: _accountId,
      liters: _isFuel && liters > 0 ? _clean(_liters) : null,
      rate: _isFuel && liters > 0
          ? (amount / liters).toStringAsFixed(2)
          : null,
      odometer: _isFuel && _odometer.isNotEmpty
          ? int.tryParse(_odometer)
          : null,
      repairKind: _isRepair ? _repairKind : null,
      payeeId: upi?.payee.id,
      upiRef: upi?.ref,
    );
    var queued = false;
    try {
      final repo = ref.read(expenseRepositoryProvider);
      if (_editing) {
        await repo.update(widget.existing!.id, input);
      } else {
        final vehicle = ref.read(vehiclesProvider).asData?.value.where((v) => v.id == vehicleId).firstOrNull;
        final out = await ref.read(outboxProvider.notifier).save(OutboxItem(
              kind: OutboxKind.expense,
              body: {...input.toJson(), 'id': upi?.id ?? newId()},
              title: _category.label(t),
              subtitle: upi == null ? vehicle?.name ?? '' : '${vehicle?.name ?? ''} · ${t.upiPaidTo(upi.payee.name)}',
              amount: amount,
              date: _date,
            ));
        queued = out == SaveOutcome.queued;
      }
      final defaults = ref.read(defaultsProvider);
      await defaults.setVehicle(vehicleId);
      if (_accountId != null) await defaults.setAccount(_accountId!);
      ref.invalidate(expensesProvider);
      ref.invalidate(tripExpensesProvider);
      invalidateReports(ref);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Haptics.success();
      showSavedTick(context);
      Navigator.pop(context, true);
      messenger.showSnackBar(SnackBar(content: Text(queued ? t.savedOffline : t.expenseSaved)));
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
      ref.invalidate(tripExpensesProvider);
      invalidateReports(ref);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) Haptics.error();
      setState(() => _error = errorMessage(t, e));
    }
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 8),
    child: Text(
      text,
      style: TextStyle(fontSize: 14, color: AppColors.muted),
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
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
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
                              : AppColors.text),
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
    final lang = Localizations.localeOf(context).languageCode;
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

    // Fuel: one choice if the vehicle takes one fuel, CNG first when it takes CNG and petrol.
    final vehicle = vehicles?.where((v) => v.id == vehicleId).firstOrNull;
    final fuelChoices = <ExpenseCategory>[
      ...(vehicle?.fuelType.categories ?? const [ExpenseCategory.diesel, ExpenseCategory.petrol, ExpenseCategory.cng]),
      if (_editing && !(vehicle?.fuelType.categories.contains(widget.existing!.category) ?? true))
        widget.existing!.category,
    ];
    if (_isFuelSheet && !_editing && !_fuelPicked && vehicle != null) {
      _category = vehicle.fuelType.defaultCategory;
    }

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
                  child: Icon(_category.icon, color: AppColors.gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isFuelSheet ? t.fuelLabel : _category.label(t),
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
                    if (widget.trip != null) ...[
                      _label(t.forTrip),
                      Text(
                        '${widget.trip!.from.nameFor(lang)} → ${widget.trip!.to.nameFor(lang)} · ${widget.trip!.vehicle.name}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                      ),
                    ] else ...[
                      _label(t.vehicle),
                      VehicleChips(
                        selectedId: vehicleId,
                        onChanged: (v) => setState(() {
                          _vehicleId = v.id;
                          _fuelPicked = false; // fuel follows the new vehicle's default
                        }),
                      ),
                    ],
                    if (_isFuelSheet) ...[
                      _label(t.whichFuel),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final c in fuelChoices)
                            AppChip(
                              label: c.label(t),
                              selected: _category == c,
                              onTap: () => setState(() {
                                _category = c;
                                _fuelPicked = true;
                              }),
                            ),
                        ],
                      ),
                    ],
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
                        if (_isFuel) ...[
                          const SizedBox(width: 8),
                          _fieldBox(_Field.liters, _category == ExpenseCategory.cng ? t.kgLabel : t.liters, _liters),
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
              onPressed: () => _save(vehicleId),
            ),
            if (!_editing) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : () => _payByUpi(vehicleId),
                  icon: const Icon(Icons.qr_code_2_rounded),
                  label: Text(t.payByUpi),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
