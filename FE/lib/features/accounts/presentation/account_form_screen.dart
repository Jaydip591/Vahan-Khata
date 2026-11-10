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
import '../data/account.dart';
import '../data/account_repository.dart';
import 'accounts_screen.dart' show accountIcon;

final _moneyRe = RegExp(r'^\d{1,10}(\.\d{1,2})?$');

class AccountFormScreen extends ConsumerStatefulWidget {
  const AccountFormScreen({super.key, this.account});
  final Account? account;

  @override
  ConsumerState<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends ConsumerState<AccountFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _opening = TextEditingController(text: '0');
  AccountKind _kind = AccountKind.cash;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.account != null;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _name.text = a.name;
      _opening.text = a.openingBalance;
      _kind = a.kind;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _opening.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final t = AppL10n.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final opening = _opening.text.trim().isEmpty ? '0' : _opening.text.trim();
    try {
      final repo = ref.read(accountRepositoryProvider);
      if (_editing) {
        await repo.update(widget.account!.id, _name.text.trim(), _kind, opening);
      } else {
        await repo.create(_name.text.trim(), _kind, opening);
      }
      ref.invalidate(accountsProvider);
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
      await ref.read(accountRepositoryProvider).delete(widget.account!.id);
      ref.invalidate(accountsProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) setState(() => _error = errorMessage(t, e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return FormShell(
      title: _editing ? t.editAccount : t.addAccount,
      onSave: _save,
      saving: _saving,
      error: _error,
      onDelete: _editing ? _delete : null,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                for (final k in AccountKind.values) ...[
                  Expanded(
                    child: AppChip(
                      label: k.label(t),
                      icon: accountIcon(k),
                      selected: _kind == k,
                      expand: true,
                      onTap: () => setState(() => _kind = k),
                    ),
                  ),
                  if (k != AccountKind.values.last) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 18),
            AppTextField(
              label: t.accountName,
              hint: t.accountNameHint,
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? t.required : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: t.openingBalance,
              controller: _opening,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              suffixIcon: Padding(
                padding: EdgeInsets.all(14),
                child: Text('₹', style: TextStyle(fontSize: 20, color: AppColors.muted)),
              ),
              validator: (v) {
                final value = (v ?? '').trim();
                return value.isEmpty || _moneyRe.hasMatch(value) ? null : t.errorInvalid;
              },
            ),
          ],
        ),
      ),
    );
  }
}
