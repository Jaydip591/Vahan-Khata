import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum TagKind { good, warn, bad, neutral }

/// Small coloured pill: green = paid/settled, gold = partly, coral = due.
class StatusTag extends StatelessWidget {
  const StatusTag(this.text, this.kind, {super.key});
  final String text;
  final TagKind kind;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (kind) {
      TagKind.good => (AppColors.tagGoodBg, AppColors.tagGoodFg),
      TagKind.warn => (AppColors.goldSoft, AppColors.tagWarnFg),
      TagKind.bad => (AppColors.tagBadBg, AppColors.tagBadFg),
      TagKind.neutral => (AppColors.chipFill, AppColors.muted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(text, style: TextStyle(fontSize: 13, color: fg, fontWeight: FontWeight.w500)),
    );
  }
}
