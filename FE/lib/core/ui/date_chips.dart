import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../money.dart';
import 'app_chip.dart';

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

DateTime today() {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day);
}

/// Today / Yesterday / pick another date. One tap for the usual cases.
class DateChips extends StatelessWidget {
  const DateChips({super.key, required this.date, required this.onChanged});
  final DateTime date;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final now = today();
    final yesterday = now.subtract(const Duration(days: 1));
    final isToday = _sameDay(date, now);
    final isYesterday = _sameDay(date, yesterday);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        AppChip(label: t.today, selected: isToday, onTap: () => onChanged(now)),
        AppChip(label: t.yesterday, selected: isYesterday, onTap: () => onChanged(yesterday)),
        AppChip(
          label: (isToday || isYesterday) ? t.otherDate : formatDay(date),
          icon: Icons.event_outlined,
          selected: !isToday && !isYesterday,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime(now.year - 2),
              lastDate: now.add(const Duration(days: 1)),
            );
            if (picked != null) onChanged(DateTime(picked.year, picked.month, picked.day));
          },
        ),
      ],
    );
  }
}
