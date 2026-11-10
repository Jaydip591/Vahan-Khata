import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/haptics.dart';
import '../../../core/ui/motion.dart';
import '../../../core/locale_controller.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/theme_mode_controller.dart';
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
            child: Text(t.cancel, style: TextStyle(fontSize: 17, color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(t.logout,
                style: TextStyle(fontSize: 17, color: AppColors.expense)),
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
    final themeMode = ref.watch(themeModeProvider);
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
                if (user != null && user.name.isNotEmpty) _ProfileCard(name: user.name, username: user.username),
                const SizedBox(height: 20),
                _Heading(t.manage),
                for (final item in [
                  (Icons.local_shipping_rounded, t.vehicles, '/vehicles'),
                  (Icons.badge_rounded, t.drivers, '/drivers'),
                  (Icons.groups_rounded, t.parties, '/parties'),
                  (Icons.account_balance_wallet_rounded, t.accounts, '/accounts'),
                  (Icons.qr_code_2_rounded, t.payees, '/payees'),
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
                _Heading(t.settings),
                Text(t.language, style: TextStyle(fontSize: 14, color: AppColors.muted)),
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
                const SizedBox(height: 20),
                Text(t.themeLabel, style: TextStyle(fontSize: 14, color: AppColors.muted)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    for (final (i, m) in [
                      (ThemeMode.system, t.themeSystem),
                      (ThemeMode.light, t.themeLight),
                      (ThemeMode.dark, t.themeDark),
                    ].indexed) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: _LangChip(
                          label: m.$2,
                          selected: themeMode == m.$1,
                          onTap: () => ref.read(themeModeProvider.notifier).set(m.$1),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 20),
                const _VibrationRow(),
                const SizedBox(height: 10),
                const _VersionRow(),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, ref),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(t.logout),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.expense,
                    side: BorderSide(color: AppColors.expense, width: 2),
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
          color: selected ? AppColors.selected : AppColors.card,
          border: Border.all(color: selected ? AppColors.selected : AppColors.fieldLine, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.onSelected : AppColors.text,
          ),
        ),
      ),
    );
  }
}

/// Switch for the vibration on taps and saves.
class _VibrationRow extends ConsumerStatefulWidget {
  const _VibrationRow();

  @override
  ConsumerState<_VibrationRow> createState() => _VibrationRowState();
}

class _VibrationRowState extends ConsumerState<_VibrationRow> {
  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.vibration_rounded, color: AppColors.text),
          const SizedBox(width: 12),
          Expanded(
            child: Text(t.vibration, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ),
          Switch(
            value: Haptics.enabled,
            activeTrackColor: AppColors.selected,
            activeThumbColor: AppColors.selectedAccent,
            onChanged: (on) async {
              await Haptics.setEnabled(ref.read(sharedPreferencesProvider), on);
              if (mounted) setState(() {});
            },
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 13, letterSpacing: 0.8, color: AppColors.muted, fontWeight: FontWeight.w600)),
      );
}

/// Avatar card at the top; opens the profile.
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.name, required this.username});
  final String name;
  final String username;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      child: Material(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Haptics.tap();
            context.push('/profile');
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ink2,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: Text(
                    name.characters.first.toUpperCase(),
                    style: const TextStyle(color: AppColors.gold, fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                      Text('@$username', style: const TextStyle(fontSize: 14, color: AppColors.mutedOnInk)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.gold, size: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

class _VersionRow extends ConsumerWidget {
  const _VersionRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final version = ref.watch(appVersionProvider).value ?? '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.text),
          const SizedBox(width: 12),
          Expanded(child: Text(t.appVersion, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500))),
          Text(version, style: TextStyle(fontSize: 16, color: AppColors.muted)),
        ],
      ),
    );
  }
}
