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
import '../../vehicles/data/vehicle_repository.dart';
import '../data/driver.dart';
import '../data/driver_repository.dart';

final phoneRe = RegExp(r'^\+?[0-9]{7,15}$');

class DriverFormScreen extends ConsumerStatefulWidget {
  const DriverFormScreen({super.key, this.driver});
  final Driver? driver;

  @override
  ConsumerState<DriverFormScreen> createState() => _DriverFormScreenState();
}

class _DriverFormScreenState extends ConsumerState<DriverFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  String? _vehicleId;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.driver != null;

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    if (d != null) {
      _name.text = d.name;
      _phone.text = d.phone ?? '';
      _vehicleId = d.defaultVehicleId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final t = AppL10n.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final phone = _phone.text.trim().isEmpty ? null : _phone.text.trim();
    try {
      final repo = ref.read(driverRepositoryProvider);
      if (_editing) {
        await repo.update(widget.driver!.id, _name.text.trim(), phone, _vehicleId);
      } else {
        await repo.create(_name.text.trim(), phone, _vehicleId);
      }
      ref.invalidate(driversProvider);
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
      await ref.read(driverRepositoryProvider).delete(widget.driver!.id);
      ref.invalidate(driversProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(t, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final vehicles = ref.watch(vehiclesProvider).asData?.value ?? const [];
    return FormShell(
      title: _editing ? t.editDriver : t.addDriver,
      onSave: _save,
      saving: _saving,
      error: _error,
      onDelete: _editing ? _delete : null,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: t.name,
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? t.required : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: t.phone,
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ -]'))],
              validator: (v) {
                final value = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
                return value.isEmpty || phoneRe.hasMatch(value) ? null : t.invalidPhone;
              },
            ),
            const SizedBox(height: 18),
            Text(t.defaultVehicle, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChip(
                    label: t.none, selected: _vehicleId == null, onTap: () => setState(() => _vehicleId = null)),
                for (final v in vehicles)
                  AppChip(
                    label: v.name,
                    selected: _vehicleId == v.id,
                    onTap: () => setState(() => _vehicleId = v.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
