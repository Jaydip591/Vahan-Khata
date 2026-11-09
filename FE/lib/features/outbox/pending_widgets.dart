import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money.dart';
import '../../core/theme/app_colors.dart';
import '../../core/ui/app_button.dart';
import '../../core/ui/ink_header.dart';
import '../../core/ui/status_tag.dart';
import '../../l10n/app_localizations.dart';
import 'outbox_controller.dart';
import 'outbox_item.dart';

/// Thin strip above the tab bar: "2 entries not sent yet". Tap to see them.
class PendingStrip extends ConsumerWidget {
  const PendingStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(outboxProvider);
    if (items.isEmpty) return const SizedBox.shrink();
    final t = AppL10n.of(context);
    final failed = items.any((i) => i.failed);
    return Material(
      color: failed ? AppColors.expense : AppColors.goldSoft,
      child: InkWell(
        onTap: () => context.push('/pending'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                failed ? Icons.error_outline_rounded : Icons.cloud_off_rounded,
                color: failed ? Colors.white : AppColors.ink,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.pendingStrip(items.length),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: failed ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: failed ? Colors.white : AppColors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A saved-offline entry shown inside the normal Trips / Kharcha lists.
class PendingTile extends StatelessWidget {
  const PendingTile({super.key, required this.item});
  final OutboxItem item;

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    return Material(
      color: AppColors.goldSoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.goldLine),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/pending'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(_icon(item.kind), color: AppColors.ink, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.subtitle.isNotEmpty)
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.muted,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatDay(item.date),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        StatusTag(
                          item.failed ? t.notSentFailed : t.notSentYet,
                          item.failed ? TagKind.bad : TagKind.neutral,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                formatRupees(item.amount),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _icon(OutboxKind k) => switch (k) {
  OutboxKind.trip => Icons.local_shipping_rounded,
  OutboxKind.expense => Icons.local_gas_station_rounded,
  OutboxKind.payment => Icons.payments_outlined,
};

/// Every entry still waiting, with "send now" and delete.
class PendingScreen extends ConsumerWidget {
  const PendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final items = ref.watch(outboxProvider);
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: Column(
        children: [
          InkHeader(
            title: t.pendingTitle,
            leading: IconButton(
              color: Colors.white,
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.cloud_done_rounded,
                          size: 56,
                          color: AppColors.gold,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          t.allSent,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        t.pendingHelp,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.muted,
                        ),
                      ),
                      const SizedBox(height: 12),
                      for (final item in items) ...[
                        _PendingCard(item: item),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
          if (items.isNotEmpty)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: AppButton(
                  label: t.sendNow,
                  icon: Icons.cloud_upload_rounded,
                  onPressed: () => ref.read(outboxProvider.notifier).syncNow(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PendingCard extends ConsumerWidget {
  const _PendingCard({required this.item});
  final OutboxItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PendingTile(item: item),
        if (item.failed)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
            child: Text(
              '${t.notSentFailedHelp}  (${item.error ?? ''})',
              style: const TextStyle(fontSize: 14, color: AppColors.expense),
            ),
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(t.deletePendingTitle),
                  content: Text(
                    t.deletePendingBody,
                    style: const TextStyle(fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(t.cancel),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        t.delete,
                        style: const TextStyle(color: AppColors.expense),
                      ),
                    ),
                  ],
                ),
              );
              if (ok == true) ref.read(outboxProvider.notifier).remove(item.id);
            },
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.expense,
            ),
            label: Text(
              t.delete,
              style: const TextStyle(fontSize: 16, color: AppColors.expense),
            ),
          ),
        ),
      ],
    );
  }
}
