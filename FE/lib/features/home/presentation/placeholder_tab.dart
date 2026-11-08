import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ink_header.dart';
import '../../../l10n/app_localizations.dart';

/// Stand-in for tabs that are built in later phases.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Column(
      children: [
        InkHeader(title: title),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: AppColors.gold),
                const SizedBox(height: 12),
                Text(t.comingSoon, style: const TextStyle(color: AppColors.muted, fontSize: 16)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
