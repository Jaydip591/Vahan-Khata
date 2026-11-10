import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_error.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/form_shell.dart';
import '../../../core/ui/motion.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';

final _phoneRe = RegExp(r'^\+?[0-9]{10,14}$');

/// Change your own name and mobile number.
class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authControllerProvider);
    if (auth is Authenticated) {
      _name.text = auth.user.name;
      _phone.text = auth.user.phone ?? '';
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
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(
            name: _name.text.trim(),
            phone: _phone.text.replaceAll(RegExp(r'[\s-]'), ''),
          );
      if (!mounted) return;
      showSavedTick(context);
      context.pop();
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
    return FormShell(
      title: t.editProfile,
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
            AppTextField(
              label: t.phoneOptional,
              controller: _phone,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
              validator: (v) {
                final value = (v ?? '').replaceAll(RegExp(r'[\s-]'), '');
                if (value.isEmpty) return null;
                return _phoneRe.hasMatch(value) ? null : t.phoneInvalid;
              },
            ),
          ],
        ),
      ),
    );
  }
}
