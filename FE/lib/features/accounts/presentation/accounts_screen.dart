import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/master_list.dart';
import '../../../l10n/app_localizations.dart';
import '../data/account.dart';
import '../data/account_repository.dart';

IconData accountIcon(AccountKind k) => switch (k) {
      AccountKind.cash => Icons.payments_outlined,
      AccountKind.bank => Icons.account_balance_outlined,
      AccountKind.upi => Icons.phone_android_rounded,
    };

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    return MasterListScreen<Account>(
      title: t.accounts,
      items: ref.watch(accountsProvider),
      emptyText: t.emptyAccounts,
      emptyIcon: Icons.account_balance_wallet_rounded,
      addLabel: t.addAccount,
      onAdd: () => context.push('/accounts/new'),
      onRefresh: () async => ref.refresh(accountsProvider.future),
      itemBuilder: (c, a) => MasterTile(
        icon: accountIcon(a.kind),
        title: a.name,
        subtitle: a.kind.label(t),
        onTap: () => context.push('/accounts/edit', extra: a),
      ),
    );
  }
}
