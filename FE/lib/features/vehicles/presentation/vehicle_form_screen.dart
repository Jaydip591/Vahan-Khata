import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_chip.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/form_shell.dart';
import '../../../core/ui/master_list.dart';
import '../../../l10n/app_localizations.dart';
import '../data/vehicle.dart';
import '../data/vehicle_repository.dart';

final _numberRe = RegExp(r'^[A-Z0-9][A-Z0-9 -]{3,18}[A-Z0-9]$');

String formatDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.vehicle});

  /// null = add a new vehicle.
  final Vehicle? vehicle;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _number = TextEditingController();
  VehicleType _type = VehicleType.eicher;
  FuelType _fuel = FuelType.diesel;
  bool _nameEdited = false;
  bool _saving = false;
  bool _docsOpen = false;
  String? _error;
  DateTime? _insurance, _puc, _fitness, _permit, _tax;

  bool get _editing => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    final v = widget.vehicle;
    if (v != null) {
      _type = v.type;
      _fuel = v.fuelType;
      _name.text = v.name;
      _number.text = v.number;
      _insurance = v.insuranceExp;
      _puc = v.pucExp;
      _fitness = v.fitnessExp;
      _permit = v.permitExp;
      _tax = v.taxExp;
      _nameEdited = true;
      _docsOpen = [_insurance, _puc, _fitness, _permit, _tax].any((d) => d != null);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _suggestName());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    super.dispose();
  }

  Future<void> _suggestName() async {
    try {
      final name = await ref.read(vehicleRepositoryProvider).suggestName(_type);
      if (mounted && !_nameEdited) setState(() => _name.text = name);
    } catch (_) {
      // Suggestion is a convenience: the user can still type a name.
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final t = AppL10n.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final input = VehicleInput(
      type: _type,
      fuelType: _fuel,
      name: _name.text.trim(),
      number: _number.text.trim().toUpperCase(),
      insuranceExp: _insurance,
      pucExp: _puc,
      fitnessExp: _fitness,
      permitExp: _permit,
      taxExp: _tax,
    );
    try {
      final repo = ref.read(vehicleRepositoryProvider);
      if (_editing) {
        await repo.update(widget.vehicle!.id, input);
      } else {
        await repo.create(input);
      }
      ref.invalidate(vehiclesProvider);
      if (mounted) context.pop();
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
    final ok = await confirmDialog(context,
        title: t.deleteConfirmTitle, body: t.deleteConfirmBody, confirmLabel: t.delete);
    if (!ok) return;
    try {
      await ref.read(vehicleRepositoryProvider).delete(widget.vehicle!.id);
      ref.invalidate(vehiclesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(t, e));
    }
  }

  Future<DateTime?> _pick(DateTime? current) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 15),
    );
  }

  Widget _dateRow(String label, DateTime? value, ValueChanged<DateTime?> onChanged) {
    final t = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.fieldLine, width: 1.5),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () async {
            final d = await _pick(value);
            if (d != null) setState(() => onChanged(d));
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            child: Row(
              children: [
                Icon(Icons.event_outlined, color: AppColors.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(fontSize: 13, color: AppColors.muted)),
                      Text(
                        value == null ? t.pickDate : formatDate(value),
                        style: TextStyle(
                          fontSize: 17,
                          color: value == null ? AppColors.muted : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
                if (value != null)
                  IconButton(
                    tooltip: t.cancel,
                    icon: Icon(Icons.close_rounded, color: AppColors.muted),
                    onPressed: () => setState(() => onChanged(null)),
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
    return FormShell(
      title: _editing ? t.editVehicle : t.addVehicle,
      onSave: _save,
      saving: _saving,
      error: _error,
      onDelete: _editing ? _delete : null,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.vehicleType, style: TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 8),
            GridView.count(
              padding: EdgeInsets.zero,
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.45,
              children: [
                for (final type in VehicleType.values)
                  AppChip(
                    label: type.label(t),
                    icon: type.icon,
                    selected: _type == type,
                    expand: true,
                    onTap: () {
                      setState(() => _type = type);
                      if (!_editing) _suggestName();
                    },
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(t.fuelType, style: TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in FuelType.values)
                  AppChip(
                    label: f.label(t),
                    selected: _fuel == f,
                    onTap: () => setState(() => _fuel = f),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: t.vehicleName,
              hint: t.vehicleNameHint,
              controller: _name,
              onChanged: (_) => _nameEdited = true,
              suffixIcon: _nameEdited
                  ? null
                  : const Icon(Icons.auto_awesome_rounded, color: AppColors.gold),
              validator: (v) => (v == null || v.trim().isEmpty) ? t.required : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: t.vehicleNumber,
              hint: 'GJ05 AB 1234',
              controller: _number,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 -]')),
                TextInputFormatter.withFunction(
                  (old, nu) => nu.copyWith(text: nu.text.toUpperCase()),
                ),
              ],
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return t.required;
                return _numberRe.hasMatch(value.toUpperCase().replaceAll(RegExp(r'\s+'), ' '))
                    ? null
                    : t.invalidNumber;
              },
            ),
            const SizedBox(height: 18),
            Material(
              color: AppColors.goldSoft,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.goldLine),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _docsOpen = !_docsOpen),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(child: Text(t.docDates, style: const TextStyle(fontSize: 16))),
                      Icon(_docsOpen
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded),
                    ],
                  ),
                ),
              ),
            ),
            if (_docsOpen) ...[
              _dateRow(t.docInsurance, _insurance, (d) => _insurance = d),
              _dateRow(t.docPuc, _puc, (d) => _puc = d),
              _dateRow(t.docFitness, _fitness, (d) => _fitness = d),
              _dateRow(t.docPermit, _permit, (d) => _permit = d),
              _dateRow(t.docTax, _tax, (d) => _tax = d),
            ],
          ],
        ),
      ),
    );
  }
}
