import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driveops_mobile/features/auth/presentation/login_screen.dart';
import 'package:driveops_mobile/features/auth/presentation/unauthorized_screen.dart';
import 'package:driveops_mobile/features/customer/customer_home_screen.dart';
import 'package:driveops_mobile/features/customer/history/customer_history_screen.dart';
import 'package:driveops_mobile/features/customer/request/customer_request_screen.dart';
import 'package:driveops_mobile/features/customer/trip/customer_trip_screen.dart';
import 'package:driveops_mobile/features/customer/widgets/customer_gate.dart';
import 'package:driveops_mobile/features/driver/driver_shell.dart';
import 'package:driveops_mobile/features/driver/home/presentation/driver_home_screen.dart';
import 'package:driveops_mobile/features/driver/history/presentation/driver_history_screen.dart';
import 'package:driveops_mobile/features/driver/map/presentation/driver_map_screen.dart';
import 'package:driveops_mobile/features/driver/chat/presentation/driver_chat_screen.dart';
import 'package:driveops_mobile/features/driver/vehicle/presentation/driver_vehicle_screen.dart';
import 'package:driveops_mobile/shared/models/user.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Listens to auth changes and triggers go_router redirect re-evaluation.
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(WidgetRef ref) {
    ref.listen(authProvider, (_, _) => notifyListeners());
  }
}

GoRouter createAppRouter(WidgetRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    // Neutral entry point: the auth check runs against the splash screen and
    // the redirect below routes the user to their role's home once resolved.
    initialLocation: '/',
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      // Wait for the initial auth check to complete before routing.
      if (authState.isLoading) return null;

      final user = authState.value?.user;
      if (user == null) {
        return state.matchedLocation == '/login' ? null : '/login';
      }

      // Every location is role-checked, not just /, /login and /unauthorized:
      // a cold start must never strand a restored customer session in the
      // driver area (or vice versa) — see initialLocation above.
      final home = _homeForRole(user.userType);
      final onUnauthorized = state.matchedLocation == '/unauthorized';

      switch (user.userType) {
        case UserType.admin:
        case UserType.dispatcher:
          return onUnauthorized ? null : home;
        case UserType.driver:
          return state.matchedLocation.startsWith('/driver') ? null : home;
        case UserType.customer:
          return state.matchedLocation.startsWith('/customer') ? null : home;
      }
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const _SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) => const UnauthorizedScreen(),
      ),
      GoRoute(
        path: '/customer',
        builder: (context, state) => const CustomerHomeScreen(),
      ),
      // Customer area: each screen is wrapped in the profile-onboarding gate.
      GoRoute(
        path: '/customer/request',
        builder: (context, state) =>
            const CustomerGate(child: CustomerRequestScreen()),
      ),
      GoRoute(
        path: '/customer/trip',
        builder: (context, state) =>
            const CustomerGate(child: CustomerTripScreen()),
      ),
      GoRoute(
        path: '/customer/history',
        builder: (context, state) =>
            const CustomerGate(child: CustomerHistoryScreen()),
      ),
      // Driver area: 5-tab bottom navigation shell.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            DriverShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver/home',
                builder: (context, state) => const DriverHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver/history',
                builder: (context, state) => const DriverHistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver/map',
                builder: (context, state) => const DriverMapScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver/chat',
                builder: (context, state) => const DriverChatScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/driver/vehicle',
                builder: (context, state) => const DriverVehicleScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

String _homeForRole(UserType type) {
  switch (type) {
    case UserType.driver:
      return '/driver/home';
    case UserType.customer:
      return '/customer';
    case UserType.admin:
    case UserType.dispatcher:
      return '/unauthorized';
  }
}

/// Shown at `/` while the persisted session is resolved, so a cold start never
/// flashes a role area (previously the driver shell) before auth completes.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F0F1A),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
      ),
    );
  }
}
