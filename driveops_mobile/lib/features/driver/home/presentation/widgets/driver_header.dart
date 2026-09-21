import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/features/driver/providers/driver_providers.dart';
import 'package:driveops_mobile/shared/models/driver.dart';

/// Profile card: avatar, name, and the Active slider that controls whether
/// the driver receives ride requests.
class DriverHeader extends ConsumerWidget {
  final Driver driver;

  const DriverHeader({super.key, required this.driver});

  String get _initials {
    final f = driver.firstName.isNotEmpty ? driver.firstName[0] : '';
    final l = driver.lastName.isNotEmpty ? driver.lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineAsync = ref.watch(driverOnlineProvider);
    final isOnline = onlineAsync.value ?? driver.isOnline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
            backgroundImage: driver.profileImageUrl != null &&
                    driver.profileImageUrl!.isNotEmpty
                ? NetworkImage(driver.profileImageUrl!)
                : null,
            child: driver.profileImageUrl == null || driver.profileImageUrl!.isEmpty
                ? Text(
                    _initials,
                    style: const TextStyle(
                      color: Color(0xFF3B82F6),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline
                            ? const Color(0xFF22C55E)
                            : Colors.white24,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        color: isOnline
                            ? const Color(0xFF22C55E)
                            : Colors.white54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Switch(
                value: isOnline,
                activeThumbColor: const Color(0xFF22C55E),
                activeTrackColor: const Color(0xFF22C55E).withValues(alpha: 0.4),
                onChanged: onlineAsync.isLoading
                    ? null
                    : (value) async {
                        try {
                          await ref
                              .read(driverOnlineProvider.notifier)
                              .setOnline(value);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not update status: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          }
                        }
                      },
              ),
              const Text(
                'Active',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
