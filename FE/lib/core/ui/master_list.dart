import 'package:flutter/material.dart';
import '../haptics.dart';
import 'motion.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/app_localizations.dart';
import '../network/api_error.dart';
import '../theme/app_colors.dart';
import 'app_button.dart';
import 'ink_header.dart';

/// One row of a master list: icon, title, optional subtitle and trailing widget.
class MasterTile extends StatelessWidget {
  const MasterTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.dimmed = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool dimmed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(child: Opacity(
      opacity: dimmed ? 0.55 : 1,
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.line),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Haptics.tap();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.chipFill,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: AppColors.text, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      if (subtitle != null && subtitle!.isNotEmpty)
                        Text(subtitle!,
                            style: TextStyle(fontSize: 14, color: AppColors.muted)),
                    ],
                  ),
                ),
                ?trailing,
                Icon(Icons.chevron_right_rounded, color: AppColors.muted),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

/// Screen for a master list (vehicles, drivers, ...): list, empty state, retry,
/// pull to refresh and a big Add button at the bottom.
class MasterListScreen<T> extends ConsumerWidget {
  const MasterListScreen({
    super.key,
    required this.title,
    required this.items,
    required this.itemBuilder,
    required this.emptyText,
    required this.addLabel,
    required this.onAdd,
    required this.onRefresh,
    this.emptyIcon = Icons.inbox_outlined,
  });

  final String title;
  final AsyncValue<List<T>> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final String emptyText;
  final String addLabel;
  final VoidCallback onAdd;
  final Future<void> Function() onRefresh;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    return Scaffold(
      body: Column(
        children: [
          InkHeader(
            title: title,
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              color: AppColors.gold,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          Expanded(
            child: items.when(
              loading: () => const SkeletonList(),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(errorMessage(t, e),
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 17)),
                      const SizedBox(height: 16),
                      OutlinedButton(onPressed: onRefresh, child: Text(t.retry)),
                    ],
                  ),
                ),
              ),
              data: (list) => AppRefresh(
                onRefresh: onRefresh,
                child: list.isEmpty
                    ? ListView(
                        children: [
                          const SizedBox(height: 80),
                          Icon(emptyIcon, size: 56, color: AppColors.gold),
                          const SizedBox(height: 12),
                          Text(emptyText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text(t.emptyHint,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 15, color: AppColors.muted)),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: list.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (c, i) => EntryFade(index: i, child: itemBuilder(c, list[i])),
                      ),
              ),
            ),
          ),
          Material(
            color: AppColors.ivory,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: AppButton(label: addLabel, icon: Icons.add_rounded, onPressed: onAdd),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
}) async {
  final t = AppL10n.of(context);
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body, style: const TextStyle(fontSize: 16)),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(t.cancel, style: TextStyle(fontSize: 17, color: AppColors.muted)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel, style: TextStyle(fontSize: 17, color: AppColors.expense)),
        ),
      ],
    ),
  );
  return ok == true;
}
