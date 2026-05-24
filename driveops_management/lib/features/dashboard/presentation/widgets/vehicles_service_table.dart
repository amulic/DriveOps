import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';

class VehiclesServiceTable extends ConsumerWidget {
  const VehiclesServiceTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(vehiclesNeedingServiceProvider);

    return Card(
      color: const Color(0xFF252538),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vehicles Needing Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            vehiclesAsync.when(
              data: (vehicles) => _buildTable(vehicles),
              loading: () => const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
              ),
              error: (_, __) => const SizedBox(
                height: 200,
                child: Center(child: Text('Failed to load', style: TextStyle(color: Colors.white54))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<Vehicle> vehicles) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Plate')),
          DataColumn(label: Text('Make / Model')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Mileage')),
          DataColumn(label: Text('Insurance')),
          DataColumn(label: Text('Registration')),
        ],
        rows: vehicles.map((vehicle) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  vehicle.licensePlate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${vehicle.make} ${vehicle.model}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              DataCell(_buildStatusChip(vehicle.status)),
              DataCell(
                Text(
                  _formatMileage(vehicle.mileage),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              DataCell(
                Text(
                  _formatDate(vehicle.insuranceExpiryDate),
                  style: TextStyle(
                    color: _getExpiryColor(vehicle.insuranceExpiryDate),
                  ),
                ),
              ),
              DataCell(
                Text(
                  _formatDate(vehicle.registrationExpiryDate),
                  style: TextStyle(
                    color: _getExpiryColor(vehicle.registrationExpiryDate),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChip(VehicleStatus status) {
    Color color;
    String label;

    switch (status) {
      case VehicleStatus.maintenance:
        color = const Color(0xFFF59E0B);
        label = 'Maintenance';
      case VehicleStatus.available:
        color = const Color(0xFF22C55E);
        label = 'Available';
      case VehicleStatus.inUse:
        color = const Color(0xFF3B82F6);
        label = 'In Use';
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
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatMileage(int? mileage) {
    if (mileage == null) return '-';
    return '${(mileage / 1000).toStringAsFixed(1)}k mi';
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  Color _getExpiryColor(DateTime date) {
    final now = DateTime.now();
    final daysUntilExpiry = date.difference(now).inDays;

    if (daysUntilExpiry < 0) {
      return const Color(0xFFEF4444);
    } else if (daysUntilExpiry < 30) {
      return const Color(0xFFF59E0B);
    }
    return Colors.white70;
  }
}