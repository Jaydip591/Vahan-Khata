import 'package:flutter/material.dart';


import '../../../core/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../expenses/data/expense.dart';

export 'report_widgets.dart' show ReportCard, MeterBar, profitColor, ErrorRetry;

/// One expense in a report list. Fuel (diesel, petrol, CNG) shows quantity, rate and odometer.
class ExpenseRow extends StatelessWidget {
  const ExpenseRow({super.key, required this.expense, this.showVehicle = false, this.onTap});
  final Expense expense;
  final bool showVehicle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final e = expense;
    final extras = <String>[
      if (e.liters != null)
        e.category == ExpenseCategory.cng ? t.kgValue(_trim(e.liters!)) : t.litersValue(_trim(e.liters!)),
      if (e.rate != null)
        e.category == ExpenseCategory.cng ? t.rateKg(formatRupees(e.rate!)) : t.rateValue(formatRupees(e.rate!)),
      if (e.odometer != null) t.kmValue(e.odometer!),
    ];
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(e.category.icon, color: AppColors.gold, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      showVehicle ? '${e.category.label(t)} · ${e.vehicle.name}' : e.category.label(t),
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                    Text(formatDay(e.date), style: TextStyle(fontSize: 14, color: AppColors.muted)),
                    if (extras.isNotEmpty)
                      Text(extras.join('  ·  '),
                          style: TextStyle(fontSize: 14, color: AppColors.muted)),
                  ],
                ),
              ),
              Text(formatRupees(e.amount),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.expense)),
            ],
          ),
        ),
      ),
    );
  }
}

String _trim(double v) => v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

/// Label + value pair used in the small totals strips.
class MiniStat extends StatelessWidget {
  const MiniStat({super.key, required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: color ?? AppColors.text)),
            ),
          ],
        ),
      );
}

Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
    );
