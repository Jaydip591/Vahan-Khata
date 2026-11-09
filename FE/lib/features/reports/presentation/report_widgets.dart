import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A thin horizontal bar filled to [fraction] (0..1).
class MeterBar extends StatelessWidget {
  const MeterBar({super.key, required this.fraction, required this.color, this.height = 10});
  final double fraction;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final f = fraction.isNaN ? 0.0 : fraction.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: AppColors.line,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: f == 0 ? 0 : f.clamp(0.02, 1.0),
          child: Container(color: color),
        ),
      ),
    );
  }
}

/// White card used by every report row.
class ReportCard extends StatelessWidget {
  const ReportCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: child,
      );
}

/// Profit colour: emerald when positive, coral when negative.
Color profitColor(double v) => v < 0 ? AppColors.expense : AppColors.income;

class ErrorRetry extends StatelessWidget {
  const ErrorRetry({super.key, required this.message, required this.retryLabel, required this.onRetry});
  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, style: const TextStyle(fontSize: 17)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      );
}
