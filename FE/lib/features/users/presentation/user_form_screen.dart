import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/form_shell.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/managed_user.dart';
import '../data/user_repository.dart';

final _usernameRe = RegExp(r'^[a-z0-9._-]{3,32}$');

class UserFormScreen extends ConsumerStatefulWidget {
  const UserFormScreen({super.key, this.user});
  final ManagedUser? user;

  @override
  ConsumerState<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends ConsumerState<UserFormScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _active = true;
  bool _hidePassword = true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.user != null;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    if (u != null) {
      _name.text = u.name;
      _username.text = u.username;
      _active = u.isActive;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
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
      final repo = ref.read(userRepositoryProvider);
      if (_editing) {
        final u = widget.user!;
        await repo.update(
          u.id,
          name: _name.text.trim() == u.name ? null : _name.text.trim(),
          password: _password.text.isEmpty ? null : _password.text,
          isActive: _active == u.isActive ? null : _active,
        );
      } else {
        await repo.create(
          username: _username.text.trim().toLowerCase(),
          name: _name.text.trim(),
          password: _password.text,
        );
      }
      ref.invalidate(usersProvider);
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

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final auth = ref.watch(authControllerProvider);
    final isSelf = _editing && auth is Authenticated && auth.user.id == widget.user!.id;
    return FormShell(
      title: _editing ? t.editUser : t.addUser,
      onSave: _save,
      saving: _saving,
      error: _error,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              label: t.fullName,
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? t.required : null,
            ),
            const SizedBox(height: 14),
            if (_editing)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text('@${_username.text}',
                    style: const TextStyle(fontSize: 17, color: AppColors.muted)),
              )
            else ...[
              AppTextField(
                label: t.username,
                hint: t.usernameRule,
                controller: _username,
                keyboardType: TextInputType.visiblePassword,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9._-]')),
                  TextInputFormatter.withFunction(
                    (old, nu) => nu.copyWith(text: nu.text.toLowerCase()),
                  ),
                ],
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return t.required;
                  return _usernameRe.hasMatch(value) ? null : t.usernameRule;
                },
              ),
              const SizedBox(height: 14),
            ],
            AppTextField(
              label: _editing ? t.newPasswordOptional : t.password,
              controller: _password,
              obscureText: _hidePassword,
              keyboardType: TextInputType.visiblePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: AppColors.muted,
                ),
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
              ),
              validator: (v) {
                final value = v ?? '';
                if (_editing && value.isEmpty) return null;
                if (value.isEmpty) return t.required;
                return value.length < 6 ? t.passwordTooShort : null;
              },
            ),
            if (_editing && !isSelf) ...[
              const SizedBox(height: 18),
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: AppColors.fieldLine, width: 1.5),
                ),
                child: SwitchListTile(
                  title: Text(t.userActive, style: const TextStyle(fontSize: 17)),
                  value: _active,
                  activeThumbColor: AppColors.gold,
                  activeTrackColor: AppColors.ink,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
