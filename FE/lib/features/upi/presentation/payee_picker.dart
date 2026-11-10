import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_chip.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/keypad.dart';
import '../../../l10n/app_localizations.dart';
import '../data/payee.dart';
import '../data/payee_repository.dart';
import 'qr_scan_screen.dart';

/// "Pay whom?": a saved payee in one tap, or scan a QR / type a UPI ID once (it is saved).
Future<Payee?> showPayeePicker(BuildContext context) =>
    showAppSheet<Payee>(context, (_) => const _PayeePicker());

class _PayeePicker extends ConsumerStatefulWidget {
  const _PayeePicker();

  @override
  ConsumerState<_PayeePicker> createState() => _PayeePickerState();
}

class _PayeePickerState extends ConsumerState<_PayeePicker> {
  bool _adding = false;
  final _name = TextEditingController();
  final _upi = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final qr = await scanUpiQr(context);
    if (qr == null || !mounted) return;
    setState(() {
      _adding = true;
      _upi.text = qr.upiId;
      _name.text = qr.name ?? '';
    });
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final t = AppL10n.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final p = await ref.read(payeeRepositoryProvider).create(_name.text.trim(), _upi.text.trim());
      ref.invalidate(payeesProvider);
      if (mounted) Navigator.pop(context, p);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = errorMessage(t, e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final payees = ref.watch(payeesProvider).asData?.value ?? const <Payee>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SheetHandle(),
          const SizedBox(height: 8),
          Text(t.payWhom, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          if (!_adding) ...[
            if (payees.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final p in payees.where((p) => p.isActive))
                    AppChip(label: p.name, selected: false, onTap: () => Navigator.pop(context, p)),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _scan,
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(t.scanQr),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _adding = true),
                    icon: const Icon(Icons.keyboard_rounded),
                    label: Text(t.typeUpiId),
                  ),
                ),
              ],
            ),
          ] else
            Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    label: t.payeeName,
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => (v == null || v.trim().isEmpty) ? t.required : null,
                  ),
                  const SizedBox(height: 12),
                  AppTextField(
                    label: t.upiIdLabel,
                    hint: t.upiIdHint,
                    controller: _upi,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => UpiQr.isValidId(v ?? '') ? null : t.upiIdInvalid,
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_error!, style: TextStyle(color: AppColors.expense, fontSize: 15)),
                    ),
                  const SizedBox(height: 14),
                  AppButton(label: t.savePayee, loading: _saving, onPressed: _save),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
