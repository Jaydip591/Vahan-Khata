import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';
import 'ink_header.dart';

/// Page layout for entry forms: ink header, scrolling body, Save button pinned
/// at the bottom (stays above the keyboard).
class FormShell extends StatelessWidget {
  const FormShell({
    super.key,
    required this.title,
    required this.child,
    required this.onSave,
    this.saving = false,
    this.error,
    this.onDelete,
    this.saveLabel,
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;
  final bool saving;
  final String? error;
  final VoidCallback? onDelete;
  final String? saveLabel;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: Column(
        children: [
          InkHeader(
            title: title,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              color: AppColors.gold,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
            trailing: onDelete == null
                ? null
                : IconButton(
                    tooltip: t.delete,
                    color: AppColors.expenseOnInk,
                    icon: const Icon(Icons.delete_outline_rounded),
                    onPressed: onDelete,
                  ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: child,
            ),
          ),
          Material(
            color: AppColors.ivory,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: AppColors.expense, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(error!,
                                  style: TextStyle(color: AppColors.expense, fontSize: 15)),
                            ),
                          ],
                        ),
                      ),
                    AppButton(label: saveLabel ?? t.save, loading: saving, onPressed: onSave),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
