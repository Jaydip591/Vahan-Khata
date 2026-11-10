import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/form_shell.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';

/// Old password + new password twice. Other phones get logged out; this one stays in.
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _old = TextEditingController();
  final _new = TextEditingController();
  final _again = TextEditingController();
  bool _hide = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final t = AppL10n.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).changePassword(_old.text, _new.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.passwordChanged)));
      context.pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e is DioException && e.response?.statusCode == 400
              ? t.wrongCurrentPassword
              : errorMessage(t, e);
        });
      }
    }
  }

  Widget _field(String label, TextEditingController c, String? Function(String?) validator) =>
      AppTextField(
        label: label,
        controller: c,
        obscureText: _hide,
        keyboardType: TextInputType.visiblePassword,
        suffixIcon: IconButton(
          icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.muted),
          onPressed: () => setState(() => _hide = !_hide),
        ),
        validator: validator,
      );

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return FormShell(
      title: t.changePassword,
      onSave: _save,
      saving: _saving,
      error: _error,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _field(t.currentPassword, _old, (v) => (v ?? '').isEmpty ? t.required : null),
            const SizedBox(height: 14),
            _field(t.newPassword, _new, (v) {
              final value = v ?? '';
              if (value.isEmpty) return t.required;
              return value.length < 6 ? t.passwordTooShort : null;
            }),
            const SizedBox(height: 14),
            _field(t.confirmPassword, _again, (v) => v == _new.text ? null : t.passwordMismatch),
            const SizedBox(height: 16),
            Text(t.passwordChangeNote, style: TextStyle(fontSize: 15, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
