import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/trip.dart';
import '../../../../shared/models/driver.dart';
import 'providers/rides_providers.dart';

class RidesScreen extends ConsumerStatefulWidget {
  const RidesScreen({super.key});

  @override
  ConsumerState<RidesScreen> createState() => _RidesScreenState();
}

class _RidesScreenState extends ConsumerState<RidesScreen> {
  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(filteredTripsProvider);
    final driversMapAsync = ref.watch(driversMapProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(tripsAsync),
          const SizedBox(height: 16),
          _buildToolbar(),
          const SizedBox(height: 16),
          Expanded(child: tripsAsync.when(
            data: (trips) {
              final driversMap = driversMapAsync.valueOrNull ?? {};
              return _buildTable(trips, driversMap);
            },
            loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                  const SizedBox(height: 16),
                  Text('Failed to load rides: $error', style: const TextStyle(color: Colors.white54)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(tripsAsyncProvider),
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

  Widget _buildHeader(AsyncValue<List<Trip>> tripsAsync) {
    final count = tripsAsync.valueOrNull?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Text(
            'Rides',
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
              tripsAsync.isLoading ? '...' : '$count',
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
    final selectedStatus = ref.watch(ridesStatusFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              onChanged: (value) {
                ref.read(ridesSearchQueryProvider.notifier).state = value;
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search rides...',
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
          const SizedBox(width: 16),
          _buildStatusFilter(selectedStatus),
        ],
      ),
    );
  }

  Widget _buildStatusFilter(TripStatus? selectedStatus) {
    final filters = <MapEntry<String, TripStatus?>>[
      const MapEntry('All', null),
      const MapEntry('Requested', TripStatus.requested),
      const MapEntry('Assigned', TripStatus.assigned),
      const MapEntry('In Progress', TripStatus.inProgress),
      const MapEntry('Completed', TripStatus.completed),
      const MapEntry('Cancelled', TripStatus.cancelled),
      const MapEntry('No Driver', TripStatus.noDriverAvailable),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((entry) {
          final isSelected = selectedStatus == entry.value;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(entry.key),
              selected: isSelected,
              onSelected: (_) {
                ref.read(ridesStatusFilterProvider.notifier).state =
                    isSelected ? null : entry.value;
              },
              selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
              backgroundColor: const Color(0xFF252538),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF3B82F6)
                    : Colors.white.withValues(alpha: 0.1),
              ),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF3B82F6) : Colors.white70,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTable(List<Trip> trips, Map<String, Driver> driversMap) {
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
              DataColumn(label: Text('Route')),
              DataColumn(label: Text('Date & Time')),
              DataColumn(label: Text('Driver')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Fare')),
              DataColumn(label: Text('')),
            ],
            rows: trips.map((trip) {
              return DataRow(
                cells: [
                  DataCell(_buildRouteCell(trip)),
                  DataCell(_buildDateTimeCell(trip.requestedAt)),
                  DataCell(_buildDriverCell(trip, driversMap)),
                  DataCell(_buildStatusChip(trip.tripStatus)),
                  DataCell(_buildFareCell(trip)),
                  DataCell(_buildMoreActions(trip)),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCell(Trip trip) {
    final pickup = _abbreviateAddress(trip.pickupAddress);
    final dropoff = _abbreviateAddress(trip.dropoffAddress);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.trip_origin, color: const Color(0xFF22C55E), size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            pickup,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward, color: Colors.white38, size: 14),
        const SizedBox(width: 6),
        Icon(Icons.location_on, color: const Color(0xFFEF4444), size: 14),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            dropoff,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeCell(DateTime dateTime) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatDate(dateTime),
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
        Text(
          _formatTime(dateTime),
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildDriverCell(Trip trip, Map<String, Driver> driversMap) {
    if (trip.driverId == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Text(
          'Unassigned',
          style: TextStyle(color: Color(0xFFF59E0B), fontSize: 12),
        ),
      );
    }

    final driver = driversMap[trip.driverId];
    if (driver == null) {
      return const Text(
        'Unknown',
        style: TextStyle(color: Colors.white54),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: _getAvatarColor(driver.driverName),
          child: Text(
            driver.driverName.split(' ').map((n) => n[0]).take(2).join(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            driver.driverName,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(TripStatus status) {
    Color color;
    String label;

    switch (status) {
      case TripStatus.completed:
        color = const Color(0xFF22C55E);
        label = 'Completed';
      case TripStatus.cancelled:
        color = const Color(0xFFEF4444);
        label = 'Cancelled';
      case TripStatus.noDriverAvailable:
        color = const Color(0xFFF59E0B);
        label = 'No Driver';
      case TripStatus.inProgress:
        color = const Color(0xFF3B82F6);
        label = 'In Progress';
      case TripStatus.driverEnRoute:
        color = const Color(0xFF8B5CF6);
        label = 'En Route';
      case TripStatus.assigned:
        color = const Color(0xFF06B6D4);
        label = 'Assigned';
      case TripStatus.requested:
        color = const Color(0xFF6B7280);
        label = 'Requested';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  Widget _buildFareCell(Trip trip) {
    final fare = trip.actualFare ?? trip.estimatedFare;
    if (fare == null) {
      return const Text('-', style: TextStyle(color: Colors.white54));
    }

    final isEstimated = trip.actualFare == null;
    return Text(
      '\$${fare.toStringAsFixed(2)}${isEstimated ? '*' : ''}',
      style: TextStyle(
        color: isEstimated ? Colors.white54 : Colors.white,
        fontWeight: isEstimated ? FontWeight.normal : FontWeight.w600,
      ),
    );
  }

  Widget _buildMoreActions(Trip trip) {
    final canAssign = trip.driverId == null &&
        (trip.tripStatus == TripStatus.requested ||
            trip.tripStatus == TripStatus.noDriverAvailable);

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
        if (canAssign)
          const PopupMenuItem(
            value: 'assign',
            child: Row(
              children: [
                Icon(Icons.person_add, color: Color(0xFF3B82F6), size: 18),
                SizedBox(width: 8),
                Text('Assign Driver',
                    style: TextStyle(color: Color(0xFF3B82F6))),
              ],
            ),
          ),
        if (trip.tripStatus == TripStatus.inProgress ||
            trip.tripStatus == TripStatus.assigned ||
            trip.tripStatus == TripStatus.driverEnRoute)
          const PopupMenuItem(
            value: 'cancel',
            child: Row(
              children: [
                Icon(Icons.cancel, color: Color(0xFFEF4444), size: 18),
                SizedBox(width: 8),
                Text('Cancel Ride',
                    style: TextStyle(color: Color(0xFFEF4444))),
              ],
            ),
          ),
      ],
    );
  }

  String _abbreviateAddress(String address) {
    final parts = address.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return address;
  }

  String _formatDate(DateTime dateTime) {
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dateTime.month]} ${dateTime.day}, ${dateTime.year}';
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute $amPm';
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
}