import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/master_list.dart';
import '../../../l10n/app_localizations.dart';
import '../data/managed_user.dart';
import '../data/user_repository.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    return MasterListScreen<ManagedUser>(
      title: t.users,
      items: ref.watch(usersProvider),
      emptyText: t.emptyUsers,
      emptyIcon: Icons.people_alt_rounded,
      addLabel: t.addUser,
      onAdd: () => context.push('/users/new'),
      onRefresh: () async => ref.refresh(usersProvider.future),
      itemBuilder: (c, u) => MasterTile(
        icon: Icons.person_outline_rounded,
        title: u.name,
        subtitle: '@${u.username}',
        dimmed: !u.isActive,
        trailing: u.isActive
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(t.userInactive,
                    style: TextStyle(color: AppColors.expense, fontSize: 13)),
              ),
        onTap: () => context.push('/users/edit', extra: u),
      ),
    );
  }
}
