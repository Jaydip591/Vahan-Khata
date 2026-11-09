import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/month_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../data/report_repository.dart';

/// "< November 2026 >" bar shared by Home and Reports.
class MonthSwitcher extends ConsumerWidget {
  const MonthSwitcher({super.key, this.onInk = false});
  final bool onInk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final lang = Localizations.localeOf(context).languageCode;
    final month = ref.watch(selectedMonthProvider);
    final now = DateTime.now();
    final isCurrent = month.year == now.year && month.month == now.month;
    final color = onInk ? Colors.white : AppColors.ink;
    return Row(
      children: [
        IconButton(
          tooltip: t.monthPrev,
          color: color,
          icon: const Icon(Icons.chevron_left_rounded, size: 30),
          onPressed: () => ref.read(selectedMonthProvider.notifier).shift(-1),
        ),
        Expanded(
          child: Text(monthLabel(lang, month),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: color)),
        ),
        IconButton(
          tooltip: t.monthNext,
          color: color,
          icon: const Icon(Icons.chevron_right_rounded, size: 30),
          onPressed: isCurrent ? null : () => ref.read(selectedMonthProvider.notifier).shift(1),
        ),
      ],
    );
  }
}
