import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ink_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/money.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../ledger/data/ledger_repository.dart';
import '../../ledger/presentation/payment_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = AppL10n.of(context);
    final auth = ref.watch(authControllerProvider);
    final name = auth is Authenticated ? auth.user.name : '';
    return Column(
      children: [
        InkHeader(
          title: t.appName,
          trailing: IconButton(
            tooltip: t.more,
            iconSize: 28,
            color: AppColors.gold,
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => context.push('/more'),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (name.isNotEmpty)
                Text(t.hello(name),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.local_shipping_rounded,
                      label: t.newTrip,
                      onTap: () => context.push('/trip/new'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.local_gas_station_rounded,
                      label: t.tabKharcha,
                      onTap: () => context.go('/kharcha'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickTile(
                      icon: Icons.payments_outlined,
                      label: t.receivePayment,
                      onTap: () => showPaymentSheet(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Material(
                color: AppColors.ink,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => context.go('/khata'),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(t.homeDueCard,
                              style: const TextStyle(color: AppColors.mutedOnInk, fontSize: 16)),
                        ),
                        Text(
                          ref.watch(partyBalancesProvider).asData?.value.totalDue == null
                              ? '—'
                              : formatRupees(ref.watch(partyBalancesProvider).asData!.value.totalDue),
                          style: const TextStyle(
                              color: AppColors.expenseOnInk, fontSize: 24, fontWeight: FontWeight.w500),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.mutedOnInk),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
                child: Icon(icon, color: AppColors.gold, size: 26),
              ),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
