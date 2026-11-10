import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../outbox/outbox_controller.dart';
import '../../outbox/pending_widgets.dart';

import '../../../core/haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

/// Bottom bar with the five main tabs. Active tab has a gold top border.
class ShellScaffold extends ConsumerStatefulWidget {
  const ShellScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    value: 1,
  );
  int _lastIndex = 0;
  StatefulNavigationShell get navigationShell => widget.navigationShell;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Anything saved without internet last time is sent as soon as the app opens.
    Future.microtask(() => ref.read(outboxProvider.notifier).syncNow());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fade.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(outboxProvider.notifier).syncNow();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppL10n.of(context);
    if (_lastIndex != navigationShell.currentIndex) {
      _lastIndex = navigationShell.currentIndex;
      _fade.forward(from: 0.35);
    }
    final items = [
      (Icons.home_outlined, Icons.home_rounded, t.tabHome),
      (Icons.local_shipping_outlined, Icons.local_shipping_rounded, t.tabTrips),
      (
        Icons.local_gas_station_outlined,
        Icons.local_gas_station_rounded,
        t.tabKharcha,
      ),
      (Icons.menu_book_outlined, Icons.menu_book_rounded, t.tabKhata),
      (Icons.bar_chart_outlined, Icons.bar_chart_rounded, t.tabReport),
    ];
    return Scaffold(
      body: FadeTransition(opacity: _fade, child: navigationShell),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const PendingStrip(),
          Material(
            color: AppColors.card,
            child: SafeArea(
              top: false,
              child: Container(
                height: 66,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.line)),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: _BarItem(
                          icon: items[i].$1,
                          activeIcon: items[i].$2,
                          label: items[i].$3,
                          active: navigationShell.currentIndex == i,
                          onTap: () {
                            Haptics.tap();
                            navigationShell.goBranch(
                              i,
                              initialLocation: i == navigationShell.currentIndex,
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  const _BarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.text : AppColors.muted;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: active ? AppColors.gold : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? activeIcon : icon, size: 26, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: active ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
