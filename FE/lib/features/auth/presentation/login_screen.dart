import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/app_button.dart';
import '../../../l10n/app_localizations.dart';
import '../data/auth_repository.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _hidePassword = true;
  bool _loading = false;
  LoginFailure? _failure;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _failure = null;
    });
    final failure = await ref
        .read(authControllerProvider.notifier)
        .login(_username.text.trim(), _password.text);
    if (!mounted) return;
    // On success the router moves to Home by itself.
    setState(() {
      _loading = false;
      _failure = failure;
    });
  }

  String _message(AppL10n t, LoginFailure f) => switch (f) {
        LoginFailure.invalid => t.loginInvalid,
        LoginFailure.disabled => t.loginDisabled,
        LoginFailure.network => t.errorNoConnection,
        LoginFailure.unknown => t.errorGeneric,
      };

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) {
    OutlineInputBorder border(Color c) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: c),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.mutedOnInk),
      prefixIcon: Icon(icon, color: AppColors.gold),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.ink2,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: border(AppColors.ink3),
      focusedBorder: border(AppColors.gold),
      errorBorder: border(AppColors.expenseOnInk),
      focusedErrorBorder: border(AppColors.expenseOnInk),
      errorStyle: const TextStyle(color: AppColors.expenseOnInk, fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    const fieldStyle = TextStyle(color: Colors.white, fontSize: 18);
    return Scaffold(
      backgroundColor: AppColors.ink,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset('assets/brand/logo_mark.png',
                          width: 128, height: 128),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      t.appName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.tagline,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 15),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _username,
                      style: fieldStyle,
                      cursorColor: AppColors.gold,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.visiblePassword,
                      inputFormatters: [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
                      decoration: _decoration(t.username, Icons.person_outline),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? t.enterUsername : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _password,
                      style: fieldStyle,
                      cursorColor: AppColors.gold,
                      obscureText: _hidePassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: _decoration(
                        t.password,
                        Icons.lock_outline,
                        suffix: IconButton(
                          tooltip: _hidePassword ? 'Show' : 'Hide',
                          icon: Icon(
                            _hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: AppColors.mutedOnInk,
                          ),
                          onPressed: () => setState(() => _hidePassword = !_hidePassword),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? t.enterPassword : null,
                    ),
                    if (_failure != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.expenseOnInk, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _message(t, _failure!),
                              style: const TextStyle(
                                  color: AppColors.expenseOnInk, fontSize: 15),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    AppButton(label: t.loginButton, loading: _loading, onPressed: _submit),
                    const SizedBox(height: 16),
                    Text(
                      t.stayLoggedInNote,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
