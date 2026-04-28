import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/vehicle.dart';
import '../providers/dashboard_providers.dart';

class VehiclesServiceTable extends ConsumerWidget {
  const VehiclesServiceTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesData = ref.watch(vehiclesProvider);
    final vehiclesNeedingService = vehiclesData.needingService;

    return Card(
      color: const Color(0xFF252538),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Vehicles Needing Service',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${vehiclesNeedingService.length} vehicles',
                    style: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
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
                rows: vehiclesNeedingService.map((vehicle) {
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
            ),
          ],
        ),
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
        break;
      case VehicleStatus.available:
        color = const Color(0xFF22C55E);
        label = 'Available';
        break;
      case VehicleStatus.inUse:
        color = const Color(0xFF3B82F6);
        label = 'In Use';
        break;
      case VehicleStatus.retired:
        color = const Color(0xFF6B7280);
        label = 'Retired';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
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
