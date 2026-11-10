import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/master_list.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/app_user.dart';
import '../../auth/presentation/auth_controller.dart';

/// Big avatar, name, username, company, phone and role, with Edit and Change password.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final auth = ref.watch(authControllerProvider);
    final user = auth is Authenticated ? auth.user : null;
    if (user == null) return const Scaffold();
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Hero(user: user),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _InfoCard(rows: [
                  (Icons.phone_rounded, t.phoneLabel, user.phone ?? t.noPhone, user.phone == null),
                  (Icons.alternate_email_rounded, t.usernameLabel, user.username, false),
                  if (user.companyName.isNotEmpty)
                    (Icons.business_rounded, t.companyLabel, user.companyName, false),
                  (Icons.verified_user_rounded, t.roleLabel, t.roleSuperadmin, false),
                ]),
                const SizedBox(height: 16),
                MasterTile(
                  icon: Icons.edit_rounded,
                  title: t.editProfile,
                  onTap: () => context.push('/profile/edit'),
                ),
                const SizedBox(height: 10),
                MasterTile(
                  icon: Icons.lock_reset_rounded,
                  title: t.changePassword,
                  onTap: () => context.push('/profile/password'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final initial = user.name.isEmpty ? '?' : user.name.characters.first.toUpperCase();
    return Material(
      color: AppColors.ink,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 28),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                    color: AppColors.gold,
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(t.profile,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.ink2,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold, width: 2.5),
                ),
                child: Text(initial,
                    style: const TextStyle(
                        color: AppColors.gold, fontSize: 42, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              Text(user.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: AppSizes.fontTitle + 2, fontWeight: FontWeight.w600)),
              Text('@${user.username}',
                  style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.rows});
  final List<(IconData, String, String, bool)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line, indent: 56),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(rows[i].$1, color: AppColors.gold),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rows[i].$2, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                        Text(rows[i].$3,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: rows[i].$4 ? AppColors.muted : AppColors.ink)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
