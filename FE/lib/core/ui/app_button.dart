import 'package:flutter/material.dart';

import '../haptics.dart';
import '../theme/app_colors.dart';
import 'motion.dart';

/// Primary action button: gold with ink text, 56dp high, full width.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      scale: 0.98,
      child: ElevatedButton(
      onPressed: loading || onPressed == null
          ? null
          : () {
              Haptics.press();
              onPressed!();
            },
      style: ElevatedButton.styleFrom(
        disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.6),
        disabledForegroundColor: AppColors.ink,
      ),
      child: loading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.ink),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: 8)],
                Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
              ],
            ),
      ),
    );
  }
}
