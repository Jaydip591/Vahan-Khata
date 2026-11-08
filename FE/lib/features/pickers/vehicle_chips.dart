import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_chip.dart';
import '../../l10n/app_localizations.dart';
import '../vehicles/data/vehicle.dart';
import '../vehicles/data/vehicle_repository.dart';

/// Row of vehicle chips for entry forms: one tap to choose a vehicle.
class VehicleChips extends ConsumerWidget {
  const VehicleChips({super.key, required this.selectedId, required this.onChanged});

  final String? selectedId;
  final ValueChanged<Vehicle> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    return ref.watch(vehiclesProvider).when(
          loading: () => const SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ),
          ),
          error: (_, _) => OutlinedButton(
            onPressed: () => ref.invalidate(vehiclesProvider),
            child: Text(t.retry),
          ),
          data: (vehicles) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final v in vehicles)
                AppChip(
                  label: v.name,
                  icon: v.type.icon,
                  selected: v.id == selectedId,
                  onTap: () => onChanged(v),
                ),
            ],
          ),
        );
  }
}
