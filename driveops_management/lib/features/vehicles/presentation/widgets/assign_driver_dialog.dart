import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/features/drivers/presentation/providers/drivers_providers.dart';
import 'package:driveops_management/features/vehicles/presentation/providers/vehicles_providers.dart';

class AssignDriverDialog extends ConsumerWidget {
  final Vehicle vehicle;
  const AssignDriverDialog({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(driversAsyncProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_add_outlined, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Assign Driver',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Select a driver for ${vehicle.licensePlate} (${vehicle.make} ${vehicle.model})',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              driversAsync.when(
                data: (drivers) {
                  final active = drivers.where((d) => d.status == DriverStatus.active).toList();
                  if (active.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No active drivers available.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 300,
                    child: ListView.separated(
                      itemCount: active.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final d = active[index];
                        return _buildDriverTile(context, ref, d);
                      },
                    ),
                  );
                },
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  ),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Failed to load drivers: $e',
                    style: const TextStyle(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDriverTile(BuildContext context, WidgetRef ref, Driver d) {
    return InkWell(
      onTap: () => _assign(context, ref, d),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF252538),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: _getAvatarColor(d.driverName),
              child: Text(
                d.driverName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    d.driverName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFBBF24), size: 12),
                      const SizedBox(width: 2),
                      Text(
                        d.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${d.totalTrips} trips',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _assign(BuildContext context, WidgetRef ref, Driver d) async {
    if (vehicle.assignedDriverId != null && vehicle.assignedDriverId != d.id) {
      final currentName = vehicle.assignedDriverName ?? 'another driver';
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Reassign Vehicle?', style: TextStyle(color: Colors.white)),
          content: Text(
            '${vehicle.make} ${vehicle.model} (${vehicle.licensePlate}) is currently assigned to $currentName.\n\n'
            'Assigning it to ${d.driverName} will unassign $currentName. Proceed?',
            style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reassign', style: TextStyle(color: Color(0xFF3B82F6))),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await ref.read(vehicleRepositoryProvider).assignVehicle(vehicle.id, d.id);
      ref.invalidate(vehiclesAsyncProvider);
      ref.invalidate(filteredVehiclesProvider);
      ref.invalidate(allVehiclesProvider);
      ref.invalidate(vehiclesNeedingServiceProvider);
      ref.invalidate(driversAsyncProvider);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${d.driverName} assigned to ${vehicle.licensePlate}'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign driver: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF3B82F6), const Color(0xFF8B5CF6), const Color(0xFF06B6D4),
      const Color(0xFFF59E0B), const Color(0xFF22C55E), const Color(0xFFEF4444),
      const Color(0xFFEC4899), const Color(0xFF6366F1),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }
}