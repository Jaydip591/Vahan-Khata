import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/ui/ink_header.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/auth_controller.dart';

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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.goldSoft,
                  border: Border.all(color: AppColors.goldLine),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.construction_rounded, color: AppColors.ink, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(t.comingSoon, style: const TextStyle(fontSize: 17)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
