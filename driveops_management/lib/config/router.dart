import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/drivers/presentation/drivers_screen.dart';
import '../features/rides/presentation/rides_screen.dart';
import '../features/messages/presentation/messages_screen.dart';
import '../features/vehicles/presentation/vehicles_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../shared/widgets/sidebar.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/dashboard',
  routes: [
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
          path: '/rides',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RidesScreen(),
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
          path: '/profile',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),
  ],
);

class ScaffoldWithSidebar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithSidebar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Sidebar(),
        Expanded(child: child),
      ],
    );
  }
}
