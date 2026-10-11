import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:driveops_mobile/features/driver/vehicle/presentation/widgets/report_defect_dialog.dart';
import 'package:driveops_mobile/services/cache_service.dart';
import 'package:driveops_mobile/shared/models/vehicle.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

class DriverVehicleScreen extends ConsumerWidget {
  const DriverVehicleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(driverVehicleProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Vehicle'),
      ),
      body: RefreshIndicator(
        // Bypass the 5-minute Hive vehicle-list cache so a fresh assignment
        // made in the management app shows up immediately.
        onRefresh: () async {
          await ref.read(cacheServiceProvider).remove(CacheService.vehiclesAll);
          ref.invalidate(driverVehicleProvider);
        },
        child: vehicleAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
          ),
          error: (e, _) => ListView(
            children: [
              const SizedBox(height: 120),
              const Icon(Icons.error_outline,
                  color: Color(0xFFEF4444), size: 48),
              const SizedBox(height: 16),
              Text(
                'Failed to load vehicle: $e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          data: (vehicle) {
            if (vehicle == null) {
              return ListView(
                children: [
                  const SizedBox(height: 120),
                  Icon(Icons.directions_car_outlined,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'No vehicle assigned to you yet.',
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                  ),
                ],
              );
            }
            return _VehicleDetails(vehicle: vehicle);
          },
        ),
      ),
    );
  }
}

class _VehicleDetails extends StatelessWidget {
  final Vehicle vehicle;

  const _VehicleDetails({required this.vehicle});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Photo
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: vehicle.photoUrl != null && vehicle.photoUrl!.isNotEmpty
                ? Image.network(
                    vehicle.photoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _photoPlaceholder(),
                  )
                : _photoPlaceholder(),
          ),
        ),
        const SizedBox(height: 16),

        // Internal name + status
        Row(
          children: [
            Expanded(
              child: Text(
                vehicle.internalName ?? '${vehicle.make} ${vehicle.model}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _statusChip(vehicle.status),
          ],
        ),
        const SizedBox(height: 16),

        // Details
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              _detailRow(Icons.directions_car, 'Make', vehicle.make),
              _detailRow(Icons.directions_car_filled, 'Model', vehicle.model),
              _detailRow(Icons.calendar_today, 'Year', '${vehicle.year}'),
              _detailRow(Icons.palette_outlined, 'Color', vehicle.color),
              _detailRow(Icons.pin_outlined, 'License plate', vehicle.licensePlate),
              _detailRow(Icons.fingerprint, 'VIN', vehicle.vin),
              _detailRow(Icons.local_gas_station_outlined, 'Fuel',
                  _fuelLabel(vehicle.fuelType)),
              _detailRow(Icons.speed, 'Mileage',
                  vehicle.mileage != null ? '${vehicle.mileage} km' : 'â€”'),
              _detailRow(
                Icons.build_outlined,
                'Last service',
                vehicle.lastServiceDate != null
                    ? DateFormat('MMM d, yyyy')
                        .format(vehicle.lastServiceDate!.toLocal())
                    : 'â€”',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Report defect
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => ReportDefectDialog(vehicle: vehicle),
              );
            },
            icon: const Icon(Icons.report_problem_outlined, size: 20),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Report a Defect',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoPlaceholder() {
    return Container(
      color: const Color(0xFF252538),
      child: const Center(
        child: Icon(Icons.directions_car, size: 64, color: Colors.white24),
      ),
    );
  }

  Widget _statusChip(VehicleStatus status) {
    final (label, color) = switch (status) {
      VehicleStatus.available => ('Available', const Color(0xFF22C55E)),
      VehicleStatus.inUse => ('In Use', const Color(0xFF3B82F6)),
      VehicleStatus.maintenance => ('Maintenance', const Color(0xFFF59E0B)),
      VehicleStatus.retired => ('Retired', const Color(0xFF6B7280)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white38),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 14)),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _fuelLabel(FuelType type) => switch (type) {
        FuelType.petrol => 'Petrol',
        FuelType.diesel => 'Diesel',
        FuelType.hybrid => 'Hybrid',
        FuelType.electric => 'Electric',
      };
}
