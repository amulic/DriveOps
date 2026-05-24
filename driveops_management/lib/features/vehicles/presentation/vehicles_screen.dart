import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/features/vehicles/presentation/providers/vehicles_providers.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  @override
  Widget build(BuildContext context) {
    final filteredVehicles = ref.watch(filteredVehiclesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(filteredVehicles),
          const SizedBox(height: 16),
          _buildToolbar(),
          const SizedBox(height: 16),
          Expanded(child: filteredVehicles.when(
            data: (vehicles) => _buildTable(vehicles),
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load vehicles: $error', style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(vehiclesAsyncProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<Vehicle>> filteredVehicles) {
    final count = filteredVehicles.value?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Text(
            'Vehicles',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              filteredVehicles.isLoading ? '...' : '$count',
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final statusFilter = ref.watch(vehiclesStatusFilterProvider);
    final needsService = ref.watch(vehiclesShowNeedsServiceProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 16,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              onChanged: (value) {
                ref.read(vehiclesSearchQueryProvider.notifier).update(value);
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by make, model, plate...',
                hintStyle: const TextStyle(color: Colors.white38),
                prefixIcon: const Icon(Icons.search, color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF252538),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          _buildStatusDropdown(statusFilter),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: needsService,
                onChanged: (value) {
                  ref.read(vehiclesShowNeedsServiceProvider.notifier).update(value ?? false);
                },
                activeColor: const Color(0xFFF59E0B),
                checkColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
              const Text(
                'Needs Service',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(VehicleStatus? current) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VehicleStatus?>(
          value: current,
          hint: const Text('All Statuses', style: TextStyle(color: Colors.white54, fontSize: 14)),
          dropdownColor: const Color(0xFF252538),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: [
            const DropdownMenuItem<VehicleStatus?>(
              value: null,
              child: Text('All Statuses'),
            ),
            ...VehicleStatus.values.map((s) => DropdownMenuItem<VehicleStatus?>(
              value: s,
              child: Text(_statusLabel(s)),
            )),
          ],
          onChanged: (value) {
            ref.read(vehiclesStatusFilterProvider.notifier).update(value);
          },
        ),
      ),
    );
  }

  Widget _buildTable(List<Vehicle> vehicles) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        color: const Color(0xFF252538),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 20,
              horizontalMargin: 20,
              columns: const [
                DataColumn(label: Text('Vehicle')),
                DataColumn(label: StatusColumnHeader()),
                DataColumn(label: Text('Driver')),
                DataColumn(label: Text('Fuel')),
                DataColumn(label: Text('Mileage')),
                DataColumn(label: ExpiryColumnHeader(label: 'Insurance')),
                DataColumn(label: ExpiryColumnHeader(label: 'Registration')),
                DataColumn(label: Text('')),
              ],
              rows: vehicles.map((vehicle) {
                return DataRow(
                  cells: [
                    DataCell(_buildVehicleCell(vehicle)),
                    DataCell(_buildStatusChip(vehicle.status)),
                    DataCell(_buildDriverCell(vehicle)),
                    DataCell(_buildFuelChip(vehicle.fuelType)),
                    DataCell(Text(
                      _formatMileage(vehicle.mileage),
                      style: const TextStyle(color: Colors.white),
                    )),
                    DataCell(Text(
                      _formatDate(vehicle.insuranceExpiryDate),
                      style: TextStyle(color: _getExpiryColor(vehicle.insuranceExpiryDate)),
                    )),
                    DataCell(Text(
                      _formatDate(vehicle.registrationExpiryDate),
                      style: TextStyle(color: _getExpiryColor(vehicle.registrationExpiryDate)),
                    )),
                    DataCell(_buildMoreActions()),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCell(Vehicle vehicle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _getVehicleColor(vehicle).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getVehicleIcon(vehicle.fuelType),
            color: _getVehicleColor(vehicle),
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${vehicle.make} ${vehicle.model}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${vehicle.year} · ${vehicle.licensePlate}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverCell(Vehicle vehicle) {
    if (vehicle.assignedDriverName == null) {
      return Text(
        'Unassigned',
        style: TextStyle(color: Colors.white38, fontSize: 13, fontStyle: FontStyle.italic),
      );
    }
    return Text(
      vehicle.assignedDriverName!,
      style: const TextStyle(color: Colors.white),
    );
  }

  Widget _buildFuelChip(FuelType fuelType) {
    Color color;
    IconData icon;

    switch (fuelType) {
      case FuelType.electric:
        color = const Color(0xFF22C55E);
        icon = Icons.bolt;
      case FuelType.hybrid:
        color = const Color(0xFF06B6D4);
        icon = Icons.eco;
      case FuelType.diesel:
        color = const Color(0xFFF59E0B);
        icon = Icons.local_gas_station;
      case FuelType.petrol:
        color = const Color(0xFFEF4444);
        icon = Icons.local_gas_station;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            fuelType.name[0].toUpperCase() + fuelType.name.substring(1),
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreActions() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white54),
      color: const Color(0xFF252538),
      onSelected: (value) {},
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'view',
          child: Row(
            children: [
              Icon(Icons.visibility, color: Colors.white54, size: 18),
              SizedBox(width: 8),
              Text('View Details', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'assign',
          child: Row(
            children: [
              Icon(Icons.person_add, color: Colors.white54, size: 18),
              SizedBox(width: 8),
              Text('Assign Driver', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'maintenance',
          child: Row(
            children: [
              Icon(Icons.build, color: Color(0xFFF59E0B), size: 18),
              SizedBox(width: 8),
              Text('Set Maintenance', style: TextStyle(color: Color(0xFFF59E0B))),
            ],
          ),
        ),
      ],
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

  String _statusLabel(VehicleStatus status) {
    switch (status) {
      case VehicleStatus.available: return 'Available';
      case VehicleStatus.inUse: return 'In Use';
      case VehicleStatus.maintenance: return 'Maintenance';
      case VehicleStatus.retired: return 'Retired';
    }
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

class StatusColumnHeader extends StatelessWidget {
  const StatusColumnHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Status'),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Green = Available, Blue = In Use,\nAmber = Maintenance, Gray = Retired',
          child: Icon(Icons.info_outline, size: 16, color: Colors.white38),
        ),
      ],
    );
  }
}

class ExpiryColumnHeader extends StatelessWidget {
  final String label;
  const ExpiryColumnHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(width: 4),
        Tooltip(
          message: 'Red = Expired, Amber = Within 30 days',
          child: Icon(Icons.info_outline, size: 16, color: Colors.white38),
        ),
      ],
    );
  }
}