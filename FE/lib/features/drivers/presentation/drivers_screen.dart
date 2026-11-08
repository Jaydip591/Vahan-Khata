import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/master_list.dart';
import '../../../l10n/app_localizations.dart';
import '../data/driver.dart';
import '../data/driver_repository.dart';

class DriversScreen extends ConsumerWidget {
  const DriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    return MasterListScreen<Driver>(
      title: t.drivers,
      items: ref.watch(driversProvider),
      emptyText: t.emptyDrivers,
      emptyIcon: Icons.badge_rounded,
      addLabel: t.addDriver,
      onAdd: () => context.push('/drivers/new'),
      onRefresh: () async => ref.refresh(driversProvider.future),
      itemBuilder: (c, d) => MasterTile(
        icon: Icons.person_outline_rounded,
        title: d.name,
        subtitle: d.phone,
        onTap: () => context.push('/drivers/edit', extra: d),
      ),
    );
  }
}
