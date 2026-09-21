import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:driveops_management/config/api_config.dart';
import 'package:driveops_management/shared/models/user.dart';
import 'package:driveops_management/shared/providers/auth_provider.dart';
import 'package:driveops_management/features/messages/presentation/providers/total_unread_provider.dart';

class Sidebar extends ConsumerWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = GoRouterState.of(context).uri.path;
    final authState = ref.watch(authProvider);
    final user = authState.value?.user;
    final unreadCount = ref.watch(totalUnreadProvider);

    return Container(
      width: AppConstants.sidebarWidth,
      color: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogo(),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _SidebarTabButton(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  route: '/dashboard',
                  isSelected: currentRoute == '/dashboard',
                  onTap: () => context.go('/dashboard'),
                ),
                _SidebarTabButton(
                  icon: Icons.drive_eta_rounded,
                  label: 'Drivers',
                  route: '/drivers',
                  isSelected: currentRoute == '/drivers',
                  onTap: () => context.go('/drivers'),
                ),
                _SidebarTabButton(
                  icon: Icons.route_rounded,
                  label: 'Rides',
                  route: '/rides',
                  isSelected: currentRoute == '/rides',
                  onTap: () => context.go('/rides'),
                ),
                _SidebarTabButton(
                  icon: Icons.chat_rounded,
                  label: 'Messages',
                  route: '/messages',
                  isSelected: currentRoute == '/messages',
                  onTap: () => context.go('/messages'),
                  badge: unreadCount > 0 ? '$unreadCount' : null,
                ),
                _SidebarTabButton(
                  icon: Icons.directions_car_rounded,
                  label: 'Vehicles',
                  route: '/vehicles',
                  isSelected: currentRoute == '/vehicles',
                  onTap: () => context.go('/vehicles'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildProfileSection(context, ref, user),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.local_taxi, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          const Text(
            'DriveOps',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, WidgetRef ref, User? user) {
    final name = user?.fullName ?? 'Admin Manager';
    final initials = name
        .split(' ')
        .take(2)
        .map((n) => n.isNotEmpty ? n[0] : '')
        .join()
        .toUpperCase();
    String role;
    switch (user?.userType) {
      case UserType.admin:
        role = 'Administrator';
      case UserType.dispatcher:
        role = 'Dispatcher';
      case UserType.driver:
        role = 'Driver';
      case UserType.customer:
        role = 'Customer';
      default:
        role = 'User';
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => context.go('/profile'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF252538),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFF3B82F6),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            role,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white54),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white54,
                side: const BorderSide(color: Colors.white12),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;
  final VoidCallback onTap;
  final String? badge;

  const _SidebarTabButton({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: Colors.white10,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                  : null,
              borderRadius: BorderRadius.circular(8),
              border: isSelected
                  ? Border.all(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(4),
                      bottomRight: Radius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  icon,
                  color: isSelected ? const Color(0xFF3B82F6) : Colors.white70,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      badge!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
