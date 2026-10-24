import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/features/drivers/presentation/providers/drivers_providers.dart';
import 'package:driveops_management/features/vehicles/presentation/providers/vehicles_providers.dart';

class DriverDetailDialog extends ConsumerWidget {
  final Driver driver;
  const DriverDetailDialog({super.key, required this.driver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPending = driver.status == DriverStatus.pending;
    final isSuspended = driver.status == DriverStatus.suspended;
    // Approval gate: a Pending driver is approved (→ Active) here; a Suspended
    // driver is reactivated (→ Active); anyone else can be suspended. Approve and
    // Activate both call POST /api/driver/{id}/activate.
    final String primaryLabel;
    final IconData primaryIcon;
    final Color primaryColor;
    if (isPending) {
      primaryLabel = 'Approve';
      primaryIcon = Icons.verified_user_outlined;
      primaryColor = const Color(0xFF22C55E);
    } else if (isSuspended) {
      primaryLabel = 'Activate';
      primaryIcon = Icons.check_circle_outline;
      primaryColor = const Color(0xFF22C55E);
    } else {
      primaryLabel = 'Suspend';
      primaryIcon = Icons.block_outlined;
      primaryColor = const Color(0xFFEF4444);
    }

    return Dialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: _getAvatarColor(driver.driverName),
                      child: Text(
                        driver.driverName.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.driverName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildStatusChip(driver.status, driver.isOnline),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildInfoSection('Contact Information', [
                  _buildInfoRow(Icons.email_outlined, driver.email.isNotEmpty ? driver.email : 'N/A'),
                  _buildInfoRow(Icons.phone_outlined, driver.phoneNumber.isNotEmpty ? driver.phoneNumber : 'N/A'),
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('License', [
                  _buildInfoRow(Icons.badge_outlined, driver.licenseNumber),
                  _buildInfoRow(Icons.calendar_today_outlined,
                    '${driver.licenseExpiryDate.month}/${driver.licenseExpiryDate.day}/${driver.licenseExpiryDate.year}',
                    color: _expiryColor(driver.licenseExpiryDate)),
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Performance', [
                  _buildInfoRow(Icons.star_outlined, '${driver.rating.toStringAsFixed(1)} / 5.0'),
                  _buildInfoRow(Icons.route_outlined, '${driver.totalTrips} trips'),
                  _buildInfoRow(Icons.attach_money_outlined, '\$${driver.totalRevenue.toStringAsFixed(0)}'),
                ]),
                const SizedBox(height: 16),
                _buildVehiclesSection(context, ref),
                if (driver.emergencyContactName != null || driver.emergencyContactPhone != null) ...[
                  const SizedBox(height: 16),
                  _buildInfoSection('Emergency Contact', [
                    if (driver.emergencyContactName != null)
                      _buildInfoRow(Icons.person_outline, driver.emergencyContactName!),
                    if (driver.emergencyContactPhone != null)
                      _buildInfoRow(Icons.phone, driver.emergencyContactPhone!),
                  ]),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: primaryLabel,
                        icon: primaryIcon,
                        color: primaryColor,
                        onTap: () => _changeStatus(context, ref),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        label: 'Assign Vehicle',
                        icon: Icons.directions_car_outlined,
                        color: const Color(0xFF3B82F6),
                        onTap: () => _showAssignVehicle(context, ref),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(DriverStatus status, bool isOnline) {
    Color color;
    String label;
    switch (status) {
      case DriverStatus.active:
        color = isOnline ? const Color(0xFF22C55E) : const Color(0xFF3B82F6);
        label = isOnline ? 'Online' : 'Active';
      case DriverStatus.suspended:
        color = const Color(0xFFEF4444);
        label = 'Suspended';
      case DriverStatus.inactive:
        color = const Color(0xFF6B7280);
        label = 'Inactive';
      case DriverStatus.onTrip:
        color = const Color(0xFF8B5CF6);
        label = 'On Trip';
      case DriverStatus.pending:
        color = const Color(0xFFF59E0B);
        label = 'Pending';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF252538),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: rows),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: color ?? Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _expiryColor(DateTime date) {
    final now = DateTime.now();
    if (date.isBefore(now)) return const Color(0xFFEF4444);
    if (date.isBefore(now.add(const Duration(days: 30)))) return const Color(0xFFF59E0B);
    return Colors.white;
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF3B82F6), const Color(0xFF8B5CF6), const Color(0xFF06B6D4),
      const Color(0xFFF59E0B), const Color(0xFF22C55E), const Color(0xFFEF4444),
      const Color(0xFFEC4899), const Color(0xFF6366F1),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  Widget _buildVehiclesSection(BuildContext context, WidgetRef ref) {
    final allVehiclesAsync = ref.watch(allVehiclesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vehicles',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF252538),
            borderRadius: BorderRadius.circular(8),
          ),
          child: allVehiclesAsync.when(
            data: (vehicles) {
              final assigned = vehicles.where((v) => v.assignedDriverId == driver.id).toList();
              if (assigned.isEmpty) {
                return Row(
                  children: [
                    const Icon(Icons.directions_car_outlined, size: 16, color: Colors.white38),
                    const SizedBox(width: 8),
                    const Text('No vehicle assigned', style: TextStyle(color: Colors.white38)),
                  ],
                );
              }
              return Column(
                children: assigned.map((v) => _buildVehicleRow(context, ref, v)).toList(),
              );
            },
            loading: () => const SizedBox(
              height: 40,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)),
                ),
              ),
            ),
            error: (e, _) => Text('Failed to load vehicles: $e',
              style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleRow(BuildContext context, WidgetRef ref, Vehicle v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.directions_car, color: Color(0xFF3B82F6), size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${v.make} ${v.model}',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                Text(
                  '${v.year} · ${v.licensePlate}',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
          _buildVehicleStatusChip(v.status),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => _unassignVehicle(context, ref, v),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, color: Color(0xFFEF4444), size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleStatusChip(VehicleStatus status) {
    Color color;
    String label;
    switch (status) {
      case VehicleStatus.available:
        color = const Color(0xFF22C55E);
        label = 'Available';
      case VehicleStatus.inUse:
        color = const Color(0xFF3B82F6);
        label = 'In Use';
      case VehicleStatus.maintenance:
        color = const Color(0xFFF59E0B);
        label = 'Maintenance';
      case VehicleStatus.retired:
        color = const Color(0xFF6B7280);
        label = 'Retired';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
    );
  }

  Future<void> _unassignVehicle(BuildContext context, WidgetRef ref, Vehicle v) async {
    try {
      await ref.read(vehicleRepositoryProvider).unassignVehicle(v.id);
      ref.invalidate(vehiclesAsyncProvider);
      ref.invalidate(filteredVehiclesProvider);
      ref.invalidate(allVehiclesProvider);
      ref.invalidate(allVehiclesForAssignProvider);
      ref.invalidate(vehiclesNeedingServiceProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${v.licensePlate} has been unassigned'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to unassign: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    final wasPending = driver.status == DriverStatus.pending;
    final activating = wasPending || driver.status == DriverStatus.suspended;
    try {
      final repo = ref.read(driverRepositoryProvider);
      if (activating) {
        await repo.activateDriver(driver.id);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(wasPending
                ? '${driver.driverName} has been approved'
                : '${driver.driverName} has been activated'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      } else {
        await repo.suspendDriver(driver.id);
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${driver.driverName} has been suspended'),
            backgroundColor: const Color(0xFFF59E0B),
          ),
        );
      }
      ref.invalidate(driversAsyncProvider);
      ref.invalidate(filteredDriversProvider);
      ref.invalidate(activeDriversProvider);
      ref.invalidate(allDriversProvider);
      if (context.mounted) Navigator.of(context).pop();
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Action failed: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  void _showAssignVehicle(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => AssignVehicleDialog(driverId: driver.id, driverName: driver.driverName),
    );
  }
}

class AssignVehicleDialog extends ConsumerWidget {
  final String driverId;
  final String driverName;
  const AssignVehicleDialog({super.key, required this.driverId, required this.driverName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(allVehiclesForAssignProvider);

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
                  const Icon(Icons.directions_car_outlined, color: Color(0xFF3B82F6)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Assign Vehicle',
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
                'Select a vehicle to assign to $driverName. Previous vehicle will be unassigned.',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),
              vehiclesAsync.when(
                data: (vehicles) {
                  if (vehicles.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'No vehicles available for assignment.',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    );
                  }
                  return SizedBox(
                    height: 300,
                    child: ListView.separated(
                      itemCount: vehicles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final v = vehicles[index];
                        return _buildVehicleTile(context, ref, v);
                      },
                    ),
                  );
                },
                loading: () => SizedBox(
                  height: 200,
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Failed to load vehicles: $e',
                    style: const TextStyle(color: Color(0xFFEF4444))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTile(BuildContext context, WidgetRef ref, Vehicle v) {
    final isCurrentlyAssigned = v.assignedDriverId == driverId;
    final isAssignedToOther = v.assignedDriverId != null && v.assignedDriverId != driverId;
    final isRetired = v.status == VehicleStatus.retired;

    return InkWell(
      onTap: isRetired || isAssignedToOther ? null : () => _assign(context, ref, v),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentlyAssigned
              ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
              : isRetired || isAssignedToOther
                  ? const Color(0xFF1A1A2E)
                  : const Color(0xFF252538),
          borderRadius: BorderRadius.circular(8),
          border: isCurrentlyAssigned
              ? Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCurrentlyAssigned
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.2)
                    : isRetired || isAssignedToOther
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isCurrentlyAssigned ? Icons.directions_car : Icons.directions_car_outlined,
                color: isCurrentlyAssigned
                    ? const Color(0xFF3B82F6)
                    : isRetired || isAssignedToOther
                        ? Colors.white24
                        : const Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${v.make} ${v.model}',
                    style: TextStyle(
                      color: isRetired || isAssignedToOther ? Colors.white38 : Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${v.year} · ${v.licensePlate}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      if (isCurrentlyAssigned) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text('Current', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10)),
                        ),
                      ],
                      if (isAssignedToOther) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(v.assignedDriverName ?? 'Assigned', style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isCurrentlyAssigned)
              const Icon(Icons.check_circle, color: Color(0xFF3B82F6), size: 20)
            else if (isRetired)
              const Icon(Icons.block, color: Colors.white24, size: 20)
            else if (isAssignedToOther)
              const Icon(Icons.lock, color: Colors.white24, size: 16)
            else
              const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }

Future<void> _assign(BuildContext context, WidgetRef ref, Vehicle v) async {
    final allVehicles = await ref.read(allVehiclesForAssignProvider.future);
    final currentVehicle = allVehicles.where((veh) => veh.assignedDriverId == driverId).firstOrNull;

    if (currentVehicle != null) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Switch Vehicle?', style: TextStyle(color: Colors.white)),
          content: Text(
            '$driverName currently has ${currentVehicle.make} ${currentVehicle.model} (${currentVehicle.licensePlate}) assigned.\n\n'
            'Assigning ${v.make} ${v.model} (${v.licensePlate}) will unassign the current vehicle. Proceed?',
            style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Switch Vehicle', style: TextStyle(color: Color(0xFF3B82F6))),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      await ref.read(vehicleRepositoryProvider).assignVehicle(v.id, driverId);
      ref.invalidate(driversAsyncProvider);
      ref.invalidate(allVehiclesProvider);
      ref.invalidate(allVehiclesForAssignProvider);
      ref.invalidate(vehiclesAsyncProvider);
      ref.invalidate(filteredVehiclesProvider);
      ref.invalidate(vehiclesNeedingServiceProvider);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${v.licensePlate} assigned to $driverName'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign vehicle: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }
}

// autoDispose so the Assign Vehicle dialog refetches on every open — otherwise a
// vehicle unassigned/assigned in a previous dialog shows a stale status here.
final allVehiclesForAssignProvider = FutureProvider.autoDispose<List<Vehicle>>((ref) async {
  final all = await ref.watch(vehicleRepositoryProvider).getAllVehicles();
  return all.where((v) => v.status != VehicleStatus.retired).toList();
});