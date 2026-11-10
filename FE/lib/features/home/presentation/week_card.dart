import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/money.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../reports/data/report.dart';
import '../../reports/data/report_repository.dart';

/// "This week" in plain words a driver understands: trips, earned, spent, left,
/// and one small bar per day (today in gold).
class WeekCard extends ConsumerWidget {
  const WeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weekProvider).asData?.value;
    if (week == null) return const SizedBox.shrink();
    final t = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.date_range_rounded, color: AppColors.gold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(t.thisWeek, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              Text('${formatDay(week.start)} – ${formatDay(week.end)}',
                  style: TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
          ),
          const SizedBox(height: 12),
          if (week.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(t.weekEmpty, style: TextStyle(fontSize: 16, color: AppColors.muted)),
            )
          else ...[
            Row(
              children: [
                _Stat(label: t.weekTrips, value: '${week.trips}', color: AppColors.text),
                _Stat(label: t.weekEarned, value: formatRupees(week.income), color: AppColors.income),
                _Stat(label: t.weekSpent, value: formatRupees(week.expense), color: AppColors.expense),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.ivory, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Expanded(child: Text(t.weekLeft, style: const TextStyle(fontSize: 17))),
                  Text(formatRupees(week.profit),
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: week.profit < 0 ? AppColors.expense : AppColors.income)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(t.weekBarsNote, style: TextStyle(fontSize: 13, color: AppColors.muted)),
            const SizedBox(height: 6),
            SizedBox(height: 110, child: WeekBars(week: week)),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 14, color: AppColors.muted)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: color)),
            ),
          ],
        ),
      );
}

/// Seven bars, Monday first; they grow in from zero once shown.
class WeekBars extends StatefulWidget {
  const WeekBars({super.key, required this.week});
  final WeekSummary week;

  @override
  State<WeekBars> createState() => _WeekBarsState();
}

class _WeekBarsState extends State<WeekBars> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    final names = t.weekdaysShort.split(',');
    final now = DateTime.now();
    final top = widget.week.days.fold<double>(0, (m, d) => d.income > m ? d.income : m);
    return BarChart(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: top == 0 ? 1 : top * 1.1,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppColors.ink,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              formatRupees(widget.week.days[group.x].income),
              const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                final d = widget.week.days[i].day;
                final today = d.year == now.year && d.month == now.month && d.day == now.day;
                return SideTitleWidget(
                  meta: meta,
                  child: Text(i < names.length ? names[i] : '',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: today ? FontWeight.w700 : FontWeight.w400,
                          color: today ? AppColors.text : AppColors.muted)),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < widget.week.days.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: _shown ? widget.week.days[i].income : 0,
                width: 18,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                color: _isToday(widget.week.days[i].day, now) ? AppColors.gold : AppColors.income,
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: top == 0 ? 1 : top * 1.1,
                  color: AppColors.line.withValues(alpha: 0.5),
                ),
              ),
            ]),
        ],
      ),
    );
  }

  static bool _isToday(DateTime d, DateTime now) => d.year == now.year && d.month == now.month && d.day == now.day;
}
