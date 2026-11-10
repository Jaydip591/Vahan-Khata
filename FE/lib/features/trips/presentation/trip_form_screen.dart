import '../../reports/data/report_repository.dart';

import 'package:flutter/material.dart';
import '../../../core/haptics.dart';
import '../../../core/ui/motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/defaults_store.dart';
import '../../../core/money.dart';
import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_chip.dart';
import '../../../core/ui/date_chips.dart';
import '../../../core/ui/form_shell.dart';
import '../../../core/ui/keypad.dart';
import '../../../l10n/app_localizations.dart';
import '../../accounts/data/account_repository.dart';
import '../../drivers/data/driver_repository.dart';
import '../../ledger/data/ledger_repository.dart';
import '../../parties/data/party_repository.dart';
import '../../pickers/account_chips.dart';
import '../../pickers/party_chips.dart';
import '../../pickers/vehicle_chips.dart';
import '../../places/data/place.dart';
import '../../places/presentation/place_picker.dart';
import '../../vehicles/data/vehicle_repository.dart';
import '../../outbox/outbox_controller.dart';
import '../../outbox/outbox_item.dart';
import '../../../core/ids.dart';
import '../data/trip.dart';
import '../data/trip_repository.dart';

enum _Adv { full, half, none, custom }

class TripFormScreen extends ConsumerStatefulWidget {
  const TripFormScreen({super.key, this.trip});

  /// null = new trip.
  final Trip? trip;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  String? _vehicleId;
  String? _driverId;
  String? _partyId;
  Place? _from;
  Place? _to;
  DateTime _date = today();
  int _bhada = 0;
  _Adv _adv = _Adv.none;
  int _customAdvance = 0;
  String _mode = 'cash';
  String? _accountId;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.trip != null;

  @override
  void initState() {
    super.initState();
    final d = ref.read(defaultsProvider);
    final trip = widget.trip;
    if (trip != null) {
      _vehicleId = trip.vehicle.id;
      _driverId = trip.driver?.id;
      _partyId = trip.party.id;
      _from = trip.from;
      _to = trip.to;
      _date = DateTime(
        trip.tripDate.year,
        trip.tripDate.month,
        trip.tripDate.day,
      );
      _bhada = trip.bhada.round();
    } else {
      _vehicleId = d.vehicleId;
      _partyId = d.partyId;
    }
    _accountId = d.accountId;
    _mode = d.payMode;
  }

  int get _advanceAmount => switch (_adv) {
    _Adv.full => _bhada,
    _Adv.half => (_bhada / 2).round(),
    _Adv.none => 0,
    _Adv.custom => _customAdvance > _bhada ? _bhada : _customAdvance,
  };

  /// A remembered vehicle/party may have been deleted since: only keep it if it still exists.
  String? _valid(String? id, Iterable<String> existing) =>
      existing.contains(id) ? id : null;

  Future<void> _pickPlace(bool isFrom) async {
    final t = AppL10n.of(context);
    final place = await showPlacePicker(
      context,
      title: isFrom ? t.fromPlace : t.toPlace,
    );
    if (place != null && mounted) {
      setState(() => isFrom ? _from = place : _to = place);
    }
  }

  Future<void> _typeBhada() async {
    final t = AppL10n.of(context);
    final v = await showAmountSheet(context, title: t.bhada, initial: _bhada);
    if (v != null && mounted) setState(() => _bhada = v);
  }

  Future<void> _chooseAdvance(_Adv choice) async {
    final t = AppL10n.of(context);
    if (choice == _Adv.custom) {
      final v = await showAmountSheet(
        context,
        title: t.advanceLabel,
        initial: _customAdvance,
        max: _bhada,
      );
      if (v == null || !mounted) return;
      setState(() {
        _customAdvance = v;
        _adv = _Adv.custom;
      });
    } else {
      setState(() => _adv = choice);
    }
  }

  Future<void> _copyLast() async {
    try {
      final last = await ref.read(tripRepositoryProvider).list(limit: 1);
      if (last.isEmpty || !mounted) return;
      final trip = last.first;
      setState(() {
        _vehicleId = trip.vehicle.id;
        _driverId = trip.driver?.id;
        _partyId = trip.party.id;
        _from = trip.from;
        _to = trip.to;
        _bhada = trip.bhada.round();
      });
    } catch (_) {
      // Convenience only.
    }
  }

  Future<void> _save({
    required String? vehicleId,
    required String? partyId,
    required String? accountId,
  }) async {
    final t = AppL10n.of(context);
    String? problem;
    if (vehicleId == null) {
      problem = t.chooseVehicle;
    } else if (partyId == null) {
      problem = t.chooseParty;
    } else if (_from == null || _to == null) {
      problem = t.chooseRoute;
    } else if (_bhada <= 0) {
      problem = t.enterAmount;
    } else if (!_editing && _advanceAmount > 0 && accountId == null) {
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
    final advance = (!_editing && _advanceAmount > 0)
        ? AdvanceInput(
            amount: _advanceAmount,
            mode: _mode,
            accountId: accountId!,
          )
        : null;
    final input = TripInput(
      vehicleId: vehicleId!,
      driverId: _driverId,
      partyId: partyId!,
      fromPlaceId: _from!.id,
      toPlaceId: _to!.id,
      tripDate: _date,
      bhada: _bhada,
      advance: advance,
    );
    var queued = false;
    try {
      final repo = ref.read(tripRepositoryProvider);
      if (_editing) {
        await repo.update(widget.trip!.id, input);
      } else {
        final lang = Localizations.localeOf(context).languageCode;
        final vehicle = ref.read(vehiclesProvider).asData?.value.where((v) => v.id == vehicleId).firstOrNull;
        final party = ref.read(partiesProvider).asData?.value.where((p) => p.id == partyId).firstOrNull;
        final out = await ref.read(outboxProvider.notifier).save(OutboxItem(
              kind: OutboxKind.trip,
              body: {...input.toJson(), 'id': newId()},
              title: '${_from!.nameFor(lang)} → ${_to!.nameFor(lang)}',
              subtitle: '${party?.name ?? ''} · ${vehicle?.name ?? ''}',
              amount: _bhada.toDouble(),
              date: _date,
            ));
        queued = out == SaveOutcome.queued;
      }
      final defaults = ref.read(defaultsProvider);
      await defaults.setVehicle(vehicleId);
      await defaults.setParty(partyId);
      if (advance != null) {
        await defaults.setAccount(accountId!);
        await defaults.setPayMode(_mode);
      }
      ref.invalidate(tripsProvider);
      invalidateReports(ref);
      ref.invalidate(recentRoutesProvider);
      ref.invalidate(partyBalancesProvider);
      ref.invalidate(partyLedgerProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Haptics.success();
      showSavedTick(context);
      context.pop();
      messenger.showSnackBar(SnackBar(content: Text(queued ? t.savedOffline : t.tripSaved)));
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
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(fontSize: 14, color: AppColors.muted),
    ),
  );

  Widget _stepper(IconData icon, String tip, VoidCallback onTap) =>
      IconButton.filled(
        tooltip: tip,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.gold,
          fixedSize: const Size(52, 52),
        ),
        icon: Icon(icon, size: 28),
        onPressed: onTap,
      );

  Widget _placeBox(
    String hint,
    Place? place,
    IconData icon,
    String lang,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.fieldLine, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.gold, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      place?.nameFor(lang) ?? hint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        color: place == null ? AppColors.muted : AppColors.text,
                      ),
                    ),
                  ),
                ],
              ),
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
    final parties = ref.watch(partiesProvider).asData?.value;
    final accounts = ref.watch(accountsProvider).asData?.value;
    final drivers = ref.watch(driversProvider).asData?.value ?? const [];
    final routes = ref.watch(recentRoutesProvider).asData?.value ?? const [];

    final vehicleId = vehicles == null
        ? _vehicleId
        : _valid(_vehicleId, vehicles.map((v) => v.id)) ??
              (vehicles.length == 1 ? vehicles.first.id : null);
    final partyId = parties == null
        ? _partyId
        : _valid(_partyId, parties.map((p) => p.id)) ??
              (parties.length == 1 ? parties.first.id : null);
    final accountId = accounts == null
        ? _accountId
        : _valid(_accountId, accounts.map((a) => a.id)) ??
              (accounts.length == 1 ? accounts.first.id : null);

    final advance = _advanceAmount;
    final balance = _bhada - advance;

    return FormShell(
      title: _editing ? t.editTrip : t.newTrip,
      onSave: () =>
          _save(vehicleId: vehicleId, partyId: partyId, accountId: accountId),
      saving: _saving,
      error: _error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_editing) ...[
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: _copyLast,
              icon: const Icon(Icons.copy_rounded),
              label: Text(t.copyLastTrip, style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 16),
          ],
          _label(t.vehicle),
          VehicleChips(
            selectedId: vehicleId,
            onChanged: (v) => setState(() {
              _vehicleId = v.id;
              final match = drivers.where((d) => d.defaultVehicleId == v.id);
              if (match.isNotEmpty) _driverId = match.first.id;
            }),
          ),
          const SizedBox(height: 16),
          _label(t.party),
          PartyChips(
            selectedId: partyId,
            onChanged: (p) => setState(() => _partyId = p.id),
          ),
          if (routes.isNotEmpty) ...[
            const SizedBox(height: 16),
            _label(t.quickRoutes),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in routes)
                  AppChip(
                    label: '${r.from.nameFor(lang)} → ${r.to.nameFor(lang)}',
                    selected: _from?.id == r.from.id && _to?.id == r.to.id,
                    onTap: () => setState(() {
                      _from = r.from;
                      _to = r.to;
                      _bhada = r.lastBhada.round();
                    }),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _placeBox(
                t.fromPlace,
                _from,
                Icons.my_location_rounded,
                lang,
                () => _pickPlace(true),
              ),
              IconButton(
                tooltip: '⇄',
                icon: Icon(
                  Icons.swap_horiz_rounded,
                  color: AppColors.muted,
                ),
                onPressed: () => setState(() {
                  final f = _from;
                  _from = _to;
                  _to = f;
                }),
              ),
              _placeBox(
                t.toPlace,
                _to,
                Icons.flag_rounded,
                lang,
                () => _pickPlace(false),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label(t.bhada),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _stepper(
                  Icons.remove_rounded,
                  '-500',
                  () => setState(() {
                    _bhada = (_bhada - 500).clamp(0, 999999999);
                  }),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _typeBhada,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        children: [
                          Text(
                            _bhada > 0 ? formatRupees(_bhada) : '₹ 0',
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            t.tapToType,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                _stepper(
                  Icons.add_rounded,
                  '+500',
                  () => setState(() => _bhada += 500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (_editing)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.goldSoft,
                border: Border.all(color: AppColors.goldLine),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.advanceNotEditable,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            _label(t.advanceReceived),
            Row(
              children: [
                for (final (choice, label) in [
                  (_Adv.full, t.advFull),
                  (_Adv.half, t.advHalf),
                  (_Adv.none, t.advNone),
                  (_Adv.custom, t.advCustom),
                ]) ...[
                  Expanded(
                    child: AppChip(
                      label: label,
                      selected: _adv == choice,
                      expand: true,
                      onTap: () => _chooseAdvance(choice),
                    ),
                  ),
                  if (choice != _Adv.custom) const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.goldSoft,
                border: Border.all(color: AppColors.goldLine),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.advanceLabel,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        formatRupees(advance),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: AppColors.income,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        t.balanceLeft,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                      Text(
                        formatRupees(balance),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: balance > 0
                              ? AppColors.expense
                              : AppColors.income,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (advance > 0) ...[
              const SizedBox(height: 16),
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
              const SizedBox(height: 12),
              _label(t.whichAccount),
              AccountChips(
                selectedId: accountId,
                onChanged: (id) => setState(() => _accountId = id),
              ),
            ],
          ],
          const SizedBox(height: 16),
          _label(t.dateLabel),
          DateChips(date: _date, onChanged: (d) => setState(() => _date = d)),
          if (drivers.isNotEmpty) ...[
            const SizedBox(height: 16),
            _label(t.driver),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChip(
                  label: t.none,
                  selected: _driverId == null,
                  onTap: () => setState(() => _driverId = null),
                ),
                for (final d in drivers)
                  AppChip(
                    label: d.name,
                    selected: _driverId == d.id,
                    onTap: () => setState(() => _driverId = d.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
