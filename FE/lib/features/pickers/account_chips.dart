import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/ui/app_chip.dart';
import '../../l10n/app_localizations.dart';
import '../accounts/data/account_repository.dart';
import '../accounts/presentation/accounts_screen.dart' show accountIcon;

/// Chips to choose which account money went into / came out of.
/// With [allowNone] a "None" chip is added (for optional accounts).
class AccountChips extends ConsumerWidget {
  const AccountChips({
    super.key,
    required this.selectedId,
    required this.onChanged,
    this.allowNone = false,
  });

  final String? selectedId;
  final ValueChanged<String?> onChanged;
  final bool allowNone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    return ref.watch(accountsProvider).when(
          loading: () => const SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ),
          ),
          error: (_, _) => OutlinedButton(
            onPressed: () => ref.invalidate(accountsProvider),
            child: Text(t.retry),
          ),
          data: (accounts) {
            if (accounts.isEmpty && !allowNone) {
              return Text(t.needAccountFirst,
                  style: const TextStyle(color: AppColors.expense, fontSize: 15));
            }
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (allowNone)
                  AppChip(label: t.none, selected: selectedId == null, onTap: () => onChanged(null)),
                for (final a in accounts)
                  AppChip(
                    label: a.name,
                    icon: accountIcon(a.kind),
                    selected: a.id == selectedId,
                    onTap: () => onChanged(a.id),
                  ),
              ],
            );
          },
        );
  }
}
