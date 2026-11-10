import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/form_shell.dart';
import '../../../core/ui/master_list.dart';
import '../../../l10n/app_localizations.dart';
import '../data/payee.dart';
import '../data/payee_repository.dart';
import 'qr_scan_screen.dart';

/// Saved UPI payees (pumps, shops): rename, fix the UPI ID or remove.
class PayeesScreen extends ConsumerWidget {
  const PayeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    return MasterListScreen<Payee>(
      title: t.payees,
      items: ref.watch(payeesProvider),
      emptyText: t.emptyPayees,
      emptyIcon: Icons.qr_code_2_rounded,
      addLabel: t.addPayee,
      onAdd: () => context.push('/payees/new'),
      onRefresh: () async => ref.refresh(payeesProvider.future),
      itemBuilder: (c, p) => MasterTile(
        icon: Icons.qr_code_2_rounded,
        title: p.name,
        subtitle: p.upiId,
        onTap: () => context.push('/payees/edit', extra: p),
      ),
    );
  }
}

class PayeeFormScreen extends ConsumerStatefulWidget {
  const PayeeFormScreen({super.key, this.payee});
  final Payee? payee;

  @override
  ConsumerState<PayeeFormScreen> createState() => _PayeeFormScreenState();
}

class _PayeeFormScreenState extends ConsumerState<PayeeFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.payee?.name ?? '');
  late final _upi = TextEditingController(text: widget.payee?.upiId ?? '');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _upi.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    final t = AppL10n.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await action();
      ref.invalidate(payeesProvider);
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

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final repo = ref.read(payeeRepositoryProvider);
    final p = widget.payee;
    await _run(() => p == null
        ? repo.create(_name.text.trim(), _upi.text.trim())
        : repo.update(p.id, _name.text.trim(), _upi.text.trim()));
  }

  Future<void> _delete() async {
    final t = AppL10n.of(context);
    final ok = await confirmDialog(context, title: t.deleteConfirmTitle, body: t.deleteConfirmBody, confirmLabel: t.delete);
    if (ok) await _run(() => ref.read(payeeRepositoryProvider).delete(widget.payee!.id));
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return FormShell(
      title: widget.payee == null ? t.addPayee : t.editPayee,
      onSave: _save,
      saving: _saving,
      error: _error,
      onDelete: widget.payee == null ? null : _delete,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                final qr = await scanUpiQr(context);
                if (qr == null) return;
                setState(() {
                  _upi.text = qr.upiId;
                  if (_name.text.isEmpty) _name.text = qr.name ?? '';
                });
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: Text(t.scanQr),
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: t.payeeName,
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? t.required : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: t.upiIdLabel,
              hint: t.upiIdHint,
              controller: _upi,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => UpiQr.isValidId(v ?? '') ? null : t.upiIdInvalid,
            ),
          ],
        ),
      ),
    );
  }
}
