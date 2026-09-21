import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driveops_mobile/features/auth/presentation/login_screen.dart';
import 'package:driveops_mobile/features/auth/presentation/unauthorized_screen.dart';
import 'package:driveops_mobile/features/customer/customer_home_screen.dart';
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
    initialLocation: '/driver/home',
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      // Wait for the initial auth check to complete before routing.
      if (authState.isLoading) return null;

      final user = authState.value?.user;
      final isAuth = user != null;
      final loggingIn = state.matchedLocation == '/login';
      final onUnauthorized = state.matchedLocation == '/unauthorized';

      if (!isAuth && !loggingIn) return '/login';

      if (isAuth && (loggingIn || state.matchedLocation == '/')) {
        return _homeForRole(user.userType);
      }

      if (isAuth && onUnauthorized) return _homeForRole(user.userType);

      return null;
    },
    routes: [
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
