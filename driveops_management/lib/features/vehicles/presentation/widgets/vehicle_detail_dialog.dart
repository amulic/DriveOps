import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/features/vehicles/presentation/providers/vehicles_providers.dart';
import 'package:driveops_management/features/drivers/presentation/providers/drivers_providers.dart';
import 'package:driveops_management/features/vehicles/presentation/widgets/assign_driver_dialog.dart';

class VehicleDetailDialog extends ConsumerWidget {
  final Vehicle vehicle;
  const VehicleDetailDialog({super.key, required this.vehicle});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: _getVehicleColor(vehicle).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getVehicleIcon(vehicle.fuelType),
                        color: _getVehicleColor(vehicle),
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${vehicle.make} ${vehicle.model}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${vehicle.year} · ${vehicle.licensePlate}',
                            style: const TextStyle(color: Colors.white54, fontSize: 13),
                          ),
                          const SizedBox(height: 6),
                          _buildStatusChip(vehicle.status),
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
                _buildInfoSection('Vehicle Details', [
                  _buildInfoRow(Icons.tag, 'VIN: ${vehicle.vin}'),
                  _buildInfoRow(Icons.palette_outlined, 'Color: ${vehicle.color}'),
                  _buildInfoRow(Icons.people_outline, 'Seats: ${vehicle.seatingCapacity ?? "-"}'),
                  _buildInfoRow(Icons.speed_outlined, 'Mileage: ${_formatMileage(vehicle.mileage)}'),
                  _buildInfoRow(Icons.local_gas_station_outlined,
                    fuelTypeLabel(vehicle.fuelType),
                    color: _getFuelColor(vehicle.fuelType)),
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Expiry Dates', [
                  _buildInfoRow(Icons.verified_user_outlined,
                    _formatDate(vehicle.insuranceExpiryDate),
                    color: _expiryColor(vehicle.insuranceExpiryDate),
                    label: 'Insurance: '),
                  _buildInfoRow(Icons.badge_outlined,
                    _formatDate(vehicle.registrationExpiryDate),
                    color: _expiryColor(vehicle.registrationExpiryDate),
                    label: 'Registration: '),
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Assignment', [
                  if (vehicle.assignedDriverName != null)
                    _buildInfoRow(Icons.person_outlined, vehicle.assignedDriverName!)
                  else
                    _buildInfoRow(Icons.person_off_outlined, 'Unassigned',
                      color: Colors.white38),
                ]),
                const SizedBox(height: 24),
                Row(
                  children: [
                    if (vehicle.assignedDriverId == null)
                      Expanded(
                        child: _buildActionButton(
                          label: 'Assign Driver',
                          icon: Icons.person_add_outlined,
                          color: const Color(0xFF3B82F6),
                          onTap: () => _showAssignDriver(context),
                        ),
                      )
                    else ...[
                      Expanded(
                        child: _buildActionButton(
                          label: 'Unassign',
                          icon: Icons.person_remove_outlined,
                          color: const Color(0xFFEF4444),
                          onTap: () => _unassign(context, ref),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (vehicle.assignedDriverId != null)
                      Expanded(
                        child: _buildActionButton(
                          label: 'Assign to Different Driver',
                          icon: Icons.swap_horiz,
                          color: const Color(0xFFF59E0B),
                          onTap: () => _showAssignDriver(context),
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

  Widget _buildStatusChip(VehicleStatus status) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
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

  Widget _buildInfoRow(IconData icon, String value, {Color? color, String? label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white38),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label != null ? '$label$value' : value,
              style: TextStyle(color: color ?? Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getVehicleColor(Vehicle vehicle) {
    switch (vehicle.fuelType) {
      case FuelType.electric: return const Color(0xFF22C55E);
      case FuelType.hybrid: return const Color(0xFF06B6D4);
      case FuelType.diesel: return const Color(0xFFF59E0B);
      case FuelType.petrol: return const Color(0xFF3B82F6);
    }
  }

  IconData _getVehicleIcon(FuelType fuelType) {
    switch (fuelType) {
      case FuelType.electric: return Icons.electric_car;
      case FuelType.hybrid: return Icons.directions_car;
      default: return Icons.directions_car;
    }
  }

  Color _getFuelColor(FuelType fuelType) {
    switch (fuelType) {
      case FuelType.electric: return const Color(0xFF22C55E);
      case FuelType.hybrid: return const Color(0xFF06B6D4);
      case FuelType.diesel: return const Color(0xFFF59E0B);
      case FuelType.petrol: return const Color(0xFFEF4444);
    }
  }

  String fuelTypeLabel(FuelType ft) {
    return ft.name[0].toUpperCase() + ft.name.substring(1);
  }

  String _formatMileage(int? mileage) {
    if (mileage == null) return '-';
    return '${(mileage / 1000).toStringAsFixed(1)}k mi';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Color _expiryColor(DateTime date) {
    final now = DateTime.now();
    if (date.isBefore(now)) return const Color(0xFFEF4444);
    if (date.isBefore(now.add(const Duration(days: 30)))) return const Color(0xFFF59E0B);
    return Colors.white;
  }

  void _showAssignDriver(BuildContext context) {
    Navigator.of(context).pop();
    showDialog(
      context: context,
      builder: (context) => AssignDriverDialog(vehicle: vehicle),
    );
  }

  Future<void> _unassign(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(vehicleRepositoryProvider).unassignVehicle(vehicle.id);
      ref.invalidate(vehiclesAsyncProvider);
      ref.invalidate(filteredVehiclesProvider);
      ref.invalidate(allVehiclesProvider);
      ref.invalidate(vehiclesNeedingServiceProvider);
      ref.invalidate(driversAsyncProvider);
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${vehicle.licensePlate} has been unassigned'),
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
}