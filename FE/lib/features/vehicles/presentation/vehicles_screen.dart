import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui/master_list.dart';
import '../../../l10n/app_localizations.dart';
import '../data/vehicle.dart';
import '../data/vehicle_repository.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    return MasterListScreen<Vehicle>(
      title: t.vehicles,
      items: ref.watch(vehiclesProvider),
      emptyText: t.emptyVehicles,
      emptyIcon: Icons.local_shipping_rounded,
      addLabel: t.addVehicle,
      onAdd: () => context.push('/vehicles/new'),
      onRefresh: () async => ref.refresh(vehiclesProvider.future),
      itemBuilder: (c, v) => MasterTile(
        icon: v.type.icon,
        title: v.name,
        subtitle: '${v.number} · ${v.fuelType.label(AppL10n.of(context))}',
        onTap: () => context.push('/vehicles/edit', extra: v),
      ),
    );
  }
}
