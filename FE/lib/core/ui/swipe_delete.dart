import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../haptics.dart';
import '../network/api_error.dart';
import '../theme/app_colors.dart';
import 'master_list.dart' show confirmDialog;

/// Swipe a row to the left to delete it. Asks first; the row only goes away if the
/// server accepted the delete. [onGone] runs once the row has slid out (hide it locally,
/// then refresh the lists).
class SwipeDelete extends StatelessWidget {
  const SwipeDelete({
    super.key,
    required this.onDelete,
    required this.onGone,
    required this.child,
  });

  final Future<void> Function() onDelete;
  final VoidCallback onGone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Dismissible(
      key: key ?? UniqueKey(),
      direction: DismissDirection.endToStart,
      dismissThresholds: const {DismissDirection.endToStart: 0.35},
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 30),
      ),
      confirmDismiss: (_) async {
        Haptics.tap();
        final ok = await confirmDialog(
          context,
          title: t.deleteConfirmTitle,
          body: t.deleteConfirmBody,
          confirmLabel: t.delete,
        );
        if (!ok) return false;
        try {
          await onDelete();
          Haptics.heavy();
          return true;
        } catch (e) {
          Haptics.error();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage(t, e))));
          }
          return false;
        }
      },
      onDismissed: (_) => onGone(),
      child: child,
    );
  }
}
