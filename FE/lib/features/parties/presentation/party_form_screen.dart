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
import '../../drivers/presentation/driver_form_screen.dart' show phoneRe;
import '../data/party.dart';
import '../data/party_repository.dart';

class PartyFormScreen extends ConsumerStatefulWidget {
  const PartyFormScreen({super.key, this.party});
  final Party? party;

  @override
  ConsumerState<PartyFormScreen> createState() => _PartyFormScreenState();
}

class _PartyFormScreenState extends ConsumerState<PartyFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  PaymentCycle? _cycle;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.party != null;

  @override
  void initState() {
    super.initState();
    final p = widget.party;
    if (p != null) {
      _name.text = p.name;
      _phone.text = p.phone ?? '';
      _cycle = p.paymentCycle;
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
      final repo = ref.read(partyRepositoryProvider);
      if (_editing) {
        await repo.update(widget.party!.id, _name.text.trim(), phone, _cycle);
      } else {
        await repo.create(_name.text.trim(), phone, _cycle);
      }
      ref.invalidate(partiesProvider);
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
      await ref.read(partyRepositoryProvider).delete(widget.party!.id);
      ref.invalidate(partiesProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(t, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return FormShell(
      title: _editing ? t.editParty : t.addParty,
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
              label: t.partyName,
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
            Text(t.paymentCycle, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppChip(label: t.none, selected: _cycle == null, onTap: () => setState(() => _cycle = null)),
                for (final c in PaymentCycle.values)
                  AppChip(
                      label: c.label(t), selected: _cycle == c, onTap: () => setState(() => _cycle = c)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
