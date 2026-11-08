import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/placeholder_tab.dart';
import '../../features/home/presentation/shell_scaffold.dart';
import '../../features/more/presentation/more_screen.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      return switch (auth) {
        AuthLoading() => loc == '/splash' ? null : '/splash',
        Unauthenticated() => loc == '/login' ? null : '/login',
        Authenticated() => (loc == '/splash' || loc == '/login') ? '/home' : null,
      };
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _Splash()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/trips',
              builder: (c, _) => PlaceholderTab(
                  title: AppL10n.of(c).tabTrips, icon: Icons.local_shipping_rounded),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/kharcha',
              builder: (c, _) => PlaceholderTab(
                  title: AppL10n.of(c).tabKharcha, icon: Icons.local_gas_station_rounded),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/khata',
              builder: (c, _) => PlaceholderTab(
                  title: AppL10n.of(c).tabKhata, icon: Icons.menu_book_rounded),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/report',
              builder: (c, _) => PlaceholderTab(
                  title: AppL10n.of(c).tabReport, icon: Icons.bar_chart_rounded),
            ),
          ]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.ink,
      body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
    );
  }
}
