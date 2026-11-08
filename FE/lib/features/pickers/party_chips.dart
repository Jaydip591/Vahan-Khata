import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ui/app_chip.dart';
import '../../l10n/app_localizations.dart';
import '../parties/data/party.dart';
import '../parties/data/party_repository.dart';

/// Row of party chips for entry forms. [onAdd] shows a "+" chip when given.
class PartyChips extends ConsumerWidget {
  const PartyChips({super.key, required this.selectedId, required this.onChanged, this.onAdd});

  final String? selectedId;
  final ValueChanged<Party> onChanged;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    return ref.watch(partiesProvider).when(
          loading: () => const SizedBox(
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
            ),
          ),
          error: (_, _) => OutlinedButton(
            onPressed: () => ref.invalidate(partiesProvider),
            child: Text(t.retry),
          ),
          data: (parties) => Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final p in parties)
                AppChip(label: p.name, selected: p.id == selectedId, onTap: () => onChanged(p)),
              if (onAdd != null)
                AppChip(label: '+', selected: false, onTap: onAdd!),
            ],
          ),
        );
  }
}
