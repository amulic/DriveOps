import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driveops_mobile/features/driver/chat/presentation/providers/chat_signalr_provider.dart';
import 'package:driveops_mobile/features/driver/chat/presentation/providers/total_unread_provider.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

/// Driver area shell — hosts the 5-tab bottom navigation:
/// Home · History · Map · Chat · Vehicle
class DriverShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const DriverShell({super.key, required this.navigationShell});

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keep the chat hub connected for as long as the driver shell is alive.
    ref.watch(chatSignalrConnectionProvider);
    // Resolves the domain driver record (and warms the cache for all tabs).
    ref.watch(currentDriverProvider);

    final unread = ref.watch(totalUnreadProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1A1A2E),
        indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.25),
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onDestinationSelected,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: Color(0xFF3B82F6)),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history),
            selectedIcon: Icon(Icons.history, color: Color(0xFF3B82F6)),
            label: 'History',
          ),
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFF3B82F6)),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble_outline),
            ),
            selectedIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.chat_bubble, color: Color(0xFF3B82F6)),
            ),
            label: 'Chat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car, color: Color(0xFF3B82F6)),
            label: 'Vehicle',
          ),
        ],
      ),
    );
  }
}
