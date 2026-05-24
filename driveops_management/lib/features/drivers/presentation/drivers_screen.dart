import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/features/drivers/presentation/providers/drivers_providers.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  @override
  Widget build(BuildContext context) {
    final filteredDrivers = ref.watch(filteredDriversProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(filteredDrivers),
          const SizedBox(height: 16),
          _buildToolbar(),
          const SizedBox(height: 16),
          Expanded(child: filteredDrivers.when(
            data: (drivers) => _buildTable(drivers),
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load drivers: $error', style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(driversAsyncProvider),
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

  Widget _buildHeader(AsyncValue<List<Driver>> filteredDrivers) {
    final count = filteredDrivers.value?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Text(
            'Drivers',
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
              filteredDrivers.isLoading ? '...' : '$count',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              onChanged: (value) {
                ref.read(driversSearchQueryProvider.notifier).update(value);
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name...',
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
          const SizedBox(width: 20),
          Row(
            children: [
              Checkbox(
                value: ref.watch(driversShowActiveOnlyProvider),
                onChanged: (value) {
                  ref.read(driversShowActiveOnlyProvider.notifier).update(
                      value ?? false);
                },
                activeColor: const Color(0xFF3B82F6),
                checkColor: Colors.white,
                side: const BorderSide(color: Colors.white38),
              ),
              const Text(
                'Active only',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const Spacer(),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Driver'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFF3B82F6)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(List<Driver> drivers) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        color: const Color(0xFF252538),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 20,
            columns: const [
              DataColumn(label: Text('Driver')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Rides')),
              DataColumn(label: Text('Active Time')),
              DataColumn(label: Text('Earnings')),
              DataColumn(label: Text('')),
            ],
            rows: drivers.map((driver) {
              return DataRow(
                cells: [
                  DataCell(_buildDriverCell(driver)),
                  DataCell(_buildStatusChip(driver.status, driver.isOnline)),
                  DataCell(Text(
                    '${driver.totalTrips}',
                    style: const TextStyle(color: Colors.white),
                  )),
                  DataCell(Text(
                    _formatActiveTime(driver.activeTimeHours),
                    style: const TextStyle(color: Colors.white),
                  )),
                  DataCell(Text(
                    '\$${driver.totalRevenue.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                  DataCell(_buildMoreActions()),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildDriverCell(Driver driver) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: _getAvatarColor(driver.driverName),
          child: Text(
            driver.driverName.split(' ').map((n) => n[0]).take(2).join(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              driver.driverName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: const Color(0xFFFBBF24),
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  driver.rating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ],
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
              Icon(Icons.directions_car, color: Colors.white54, size: 18),
              SizedBox(width: 8),
              Text('Assign Vehicle', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'suspend',
          child: Row(
            children: [
              Icon(Icons.block, color: Color(0xFFEF4444), size: 18),
              SizedBox(width: 8),
              Text('Suspend', style: TextStyle(color: Color(0xFFEF4444))),
            ],
          ),
        ),
      ],
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFF06B6D4),
      const Color(0xFFF59E0B),
      const Color(0xFF22C55E),
      const Color(0xFFEF4444),
      const Color(0xFFEC4899),
      const Color(0xFF6366F1),
    ];
    final index = name.hashCode % colors.length;
    return colors[index.abs()];
  }

  String _formatActiveTime(double hours) {
    if (hours >= 24) {
      final days = (hours / 24).floor();
      final remainingHours = (hours % 24).round();
      return '${days}d ${remainingHours}h';
    }
    return '${hours.round()}h';
  }
}