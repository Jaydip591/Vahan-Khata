import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/accounts/data/account.dart';
import '../../features/accounts/presentation/account_form_screen.dart';
import '../../features/accounts/presentation/accounts_screen.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/drivers/data/driver.dart';
import '../../features/drivers/presentation/driver_form_screen.dart';
import '../../features/drivers/presentation/drivers_screen.dart';
import '../../features/parties/data/party.dart';
import '../../features/parties/presentation/parties_screen.dart';
import '../../features/parties/presentation/party_form_screen.dart';
import '../../features/expenses/presentation/kharcha_screen.dart';
import '../../features/ledger/presentation/khata_screen.dart';
import '../../features/ledger/presentation/party_ledger_screen.dart';
import '../../features/trips/data/trip.dart';
import '../../features/trips/presentation/trip_detail_screen.dart';
import '../../features/trips/presentation/trip_form_screen.dart';
import '../../features/trips/presentation/trips_screen.dart';
import '../../features/users/data/managed_user.dart';
import '../../features/users/presentation/user_form_screen.dart';
import '../../features/users/presentation/users_screen.dart';
import '../../features/vehicles/data/vehicle.dart';
import '../../features/vehicles/presentation/vehicle_form_screen.dart';
import '../../features/vehicles/presentation/vehicles_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/reports/presentation/month_detail_screen.dart';
import '../../features/reports/presentation/report_screen.dart';
import '../../features/reports/presentation/vehicle_detail_screen.dart';
import '../../features/home/presentation/shell_scaffold.dart';
import '../../features/more/presentation/more_screen.dart';
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
        Authenticated() =>
          (loc == '/splash' || loc == '/login') ? '/home' : null,
      };
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const _Splash()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/more', builder: (_, _) => const MoreScreen()),
      GoRoute(
        path: '/party/:id',
        builder: (_, s) => PartyLedgerScreen(partyId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/report/month',
        builder: (_, _) => const MonthDetailScreen(),
      ),
      GoRoute(
        path: '/report/vehicle',
        builder: (_, s) {
          final a = s.extra as List<String>;
          return VehicleDetailScreen(vehicleId: a[0], name: a[1]);
        },
      ),
      GoRoute(path: '/trip/new', builder: (_, _) => const TripFormScreen()),
      GoRoute(
        path: '/trip/edit',
        builder: (_, s) => TripFormScreen(trip: s.extra as Trip?),
      ),
      GoRoute(
        path: '/trip/detail',
        builder: (_, s) => TripDetailScreen(trip: s.extra as Trip),
      ),
      GoRoute(
        path: '/vehicles',
        builder: (_, _) => const VehiclesScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const VehicleFormScreen()),
          GoRoute(
            path: 'edit',
            builder: (_, s) => VehicleFormScreen(vehicle: s.extra as Vehicle?),
          ),
        ],
      ),
      GoRoute(
        path: '/drivers',
        builder: (_, _) => const DriversScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const DriverFormScreen()),
          GoRoute(
            path: 'edit',
            builder: (_, s) => DriverFormScreen(driver: s.extra as Driver?),
          ),
        ],
      ),
      GoRoute(
        path: '/parties',
        builder: (_, _) => const PartiesScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const PartyFormScreen()),
          GoRoute(
            path: 'edit',
            builder: (_, s) => PartyFormScreen(party: s.extra as Party?),
          ),
        ],
      ),
      GoRoute(
        path: '/accounts',
        builder: (_, _) => const AccountsScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const AccountFormScreen()),
          GoRoute(
            path: 'edit',
            builder: (_, s) => AccountFormScreen(account: s.extra as Account?),
          ),
        ],
      ),
      GoRoute(
        path: '/users',
        builder: (_, _) => const UsersScreen(),
        routes: [
          GoRoute(path: 'new', builder: (_, _) => const UserFormScreen()),
          GoRoute(
            path: 'edit',
            builder: (_, s) => UserFormScreen(user: s.extra as ManagedUser?),
          ),
        ],
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ShellScaffold(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/trips', builder: (_, _) => const TripsScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/kharcha',
                builder: (_, _) => const KharchaScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/khata', builder: (_, _) => const KhataScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/report', builder: (_, _) => const ReportScreen()),
            ],
          ),
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
