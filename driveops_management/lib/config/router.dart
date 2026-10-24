import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driveops_management/features/auth/presentation/login_screen.dart';
import 'package:driveops_management/features/auth/presentation/unauthorized_screen.dart';
import 'package:driveops_management/features/dashboard/presentation/dashboard_screen.dart';
import 'package:driveops_management/features/drivers/presentation/drivers_screen.dart';
import 'package:driveops_management/features/trips/presentation/trips_screen.dart';
import 'package:driveops_management/features/messages/presentation/messages_screen.dart';
import 'package:driveops_management/features/vehicles/presentation/vehicles_screen.dart';
import 'package:driveops_management/features/defects/presentation/defects_screen.dart';
import 'package:driveops_management/features/profile/presentation/profile_screen.dart';
import 'package:driveops_management/shared/providers/auth_provider.dart';
import 'package:driveops_management/shared/providers/fleet_update_provider.dart';
import 'package:driveops_management/features/messages/presentation/providers/chat_signalr_provider.dart';
import 'package:driveops_management/shared/widgets/sidebar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(WidgetRef ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isAuth = ref.watch(isAuthenticatedProvider);
      final isAuthorizedRole = ref.watch(isAuthorizedRoleProvider);
      final loggingIn = state.matchedLocation == '/login';
      final onUnauthorized = state.matchedLocation == '/unauthorized';
      if (!isAuth && !loggingIn) return '/login';
      if (isAuth && loggingIn) {
        if (!isAuthorizedRole) return '/unauthorized';
        return '/dashboard';
      }
      if (isAuth && !isAuthorizedRole && !onUnauthorized) return '/unauthorized';
      if (isAuth && isAuthorizedRole && onUnauthorized) return '/dashboard';
      return null;
    },
    refreshListenable: _RouterRefreshNotifier(ref),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/unauthorized',
        builder: (context, state) {
          final user = ref.read(currentUserProvider);
          return UnauthorizedScreen(role: user?.userType.name);
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithSidebar(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/drivers',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DriversScreen(),
            ),
          ),
          GoRoute(
            path: '/trips',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: TripsScreen(),
            ),
          ),
          GoRoute(
            path: '/messages',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MessagesScreen(),
            ),
          ),
          GoRoute(
            path: '/vehicles',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: VehiclesScreen(),
            ),
          ),
          GoRoute(
            path: '/defects',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DefectsScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this.ref) {
    ref.listen(authProvider, (_, __) {
      notifyListeners();
    });
  }

  final WidgetRef ref;
}

class ScaffoldWithSidebar extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithSidebar({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wire up SignalR fleet updates when authenticated
    ref.watch(fleetUpdateConnectionProvider);
    ref.watch(fleetUpdateListenerProvider);
    // Wire up chat SignalR when authenticated
    ref.watch(chatSignalrConnectionProvider);

    return Row(
      children: [
        const Sidebar(),
        Expanded(child: child),
      ],
    );
  }
}