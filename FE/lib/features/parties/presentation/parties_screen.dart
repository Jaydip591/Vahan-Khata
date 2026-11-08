import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/master_list.dart';
import '../../../l10n/app_localizations.dart';
import '../data/party.dart';
import '../data/party_repository.dart';

class PartiesScreen extends ConsumerWidget {
  const PartiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    return MasterListScreen<Party>(
      title: t.parties,
      items: ref.watch(partiesProvider),
      emptyText: t.emptyParties,
      emptyIcon: Icons.groups_rounded,
      addLabel: t.addParty,
      onAdd: () => context.push('/parties/new'),
      onRefresh: () async => ref.refresh(partiesProvider.future),
      itemBuilder: (c, p) => MasterTile(
        icon: Icons.storefront_outlined,
        title: p.name,
        subtitle: [?p.phone, ?p.paymentCycle?.label(t)].join(' · '),
        onTap: () => context.push('/parties/edit', extra: p),
      ),
    );
  }
}
