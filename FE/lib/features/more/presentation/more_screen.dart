import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/locale_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ink_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/ui/master_list.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../outbox/outbox_controller.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final t = AppL10n.of(context);
    final pending = ref.read(outboxProvider).length;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.logoutConfirmTitle),
        content: Text(
          pending > 0 ? '${t.logoutConfirmBody}\n\n${t.logoutPendingWarning(pending)}' : t.logoutConfirmBody,
          style: const TextStyle(fontSize: 16),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(t.cancel, style: const TextStyle(fontSize: 17, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.logout,
                style: const TextStyle(fontSize: 17, color: AppColors.expense)),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(authControllerProvider.notifier).logout();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final auth = ref.watch(authControllerProvider);
    final locale = ref.watch(localeProvider);
    final user = auth is Authenticated ? auth.user : null;

    return Scaffold(
      body: Column(
        children: [
          InkHeader(
            title: t.more,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              color: AppColors.gold,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (user != null && user.name.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.ink,
                          child: Text(
                            user.name.characters.first.toUpperCase(),
                            style: const TextStyle(
                                color: AppColors.gold, fontSize: 20, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.name,
                                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500)),
                              Text('@${user.username}',
                                  style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                for (final item in [
                  (Icons.local_shipping_rounded, t.vehicles, '/vehicles'),
                  (Icons.badge_rounded, t.drivers, '/drivers'),
                  (Icons.groups_rounded, t.parties, '/parties'),
                  (Icons.account_balance_wallet_rounded, t.accounts, '/accounts'),
                  (Icons.people_alt_rounded, t.users, '/users'),
                ]) ...[
                  MasterTile(
                    icon: item.$1,
                    title: item.$2,
                    onTap: () => context.push(item.$3),
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 10),
                Text(t.language, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _LangChip(
                        label: t.languageGujarati,
                        selected: locale.languageCode == 'gu',
                        onTap: () => ref.read(localeProvider.notifier).set(const Locale('gu')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LangChip(
                        label: t.languageEnglish,
                        selected: locale.languageCode == 'en',
                        onTap: () => ref.read(localeProvider.notifier).set(const Locale('en')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, ref),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(t.logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    side: const BorderSide(color: AppColors.expense, width: 2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : Colors.white,
          border: Border.all(color: selected ? AppColors.ink : AppColors.fieldLine, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}
