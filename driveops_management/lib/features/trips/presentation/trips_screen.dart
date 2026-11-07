import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/features/trips/presentation/providers/trips_providers.dart';
import 'package:driveops_management/features/trips/presentation/widgets/trip_details_panel.dart';
import 'package:driveops_management/features/trips/presentation/widgets/cancel_trip_dialog.dart';
import 'package:driveops_management/services/cache_service.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key});

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  @override
  Widget build(BuildContext context) {
    final tripsAsync = ref.watch(filteredTripsProvider);
    final driversMapAsync = ref.watch(driversMapProvider);
    final selectedTrip = ref.watch(selectedTripProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(tripsAsync),
                const SizedBox(height: 16),
                _buildToolbar(),
                const SizedBox(height: 16),
                Expanded(child: tripsAsync.when(
                  data: (trips) {
                    final driversMap = driversMapAsync.value ?? {};
                    return _buildTable(trips, driversMap);
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                  error: (error, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 48),
                        const SizedBox(height: 16),
                        Text('Failed to load trips: $error', style: const TextStyle(color: Colors.white54)),
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
          ),
          if (selectedTrip != null) const TripDetailsPanel(),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<Trip>> tripsAsync) {
    final count = tripsAsync.value?.length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          const Text(
            'Trips',
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
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Refresh trips',
            icon: const Icon(Icons.refresh, color: Colors.white54, size: 20),
            onPressed: () async {
              await ref.read(cacheServiceProvider).remove(CacheService.tripsAll);
              ref.invalidate(tripsAsyncProvider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    final selectedStatus = ref.watch(tripsStatusFilterProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          SizedBox(
            width: 280,
            child: TextField(
              onChanged: (value) {
                ref.read(tripsSearchQueryProvider.notifier).update(value);
              },
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search trips...',
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

    // Dropdown instead of chips: a horizontal scroll view inside the toolbar
    // Row gets unbounded width and overflows (esp. with the details panel open).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TripStatus?>(
          value: selectedStatus,
          hint: const Text(
            'Status',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          dropdownColor: const Color(0xFF252538),
          icon: const Icon(Icons.keyboard_arrow_down,
              color: Colors.white54, size: 18),
          style: const TextStyle(color: Colors.white70, fontSize: 13),
          items: filters
              .map((entry) => DropdownMenuItem<TripStatus?>(
                    value: entry.value,
                    child: Text(entry.key),
                  ))
              .toList(),
          onChanged: (value) {
            ref.read(tripsStatusFilterProvider.notifier).update(value);
          },
        ),
      ),
    );
  }

  Widget _buildTable(List<Trip> trips, Map<String, Driver> driversMap) {
    final selectedTripId = ref.watch(selectedTripIdProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Card(
        color: const Color(0xFF252538),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: SingleChildScrollView(
          // Horizontal scroll keeps a too-wide table usable instead of
          // overflowing; ConstrainedBox keeps it full-width when there is room.
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 20,
            showCheckboxColumn: false,
            columns: const [
              DataColumn(label: Text('Route')),
              DataColumn(label: Text('Date & Time')),
              DataColumn(label: Text('Driver')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Fare')),
              DataColumn(label: Text('')),
            ],
            rows: trips.map((trip) {
              final isSelected = trip.id == selectedTripId;
              return DataRow(
                selected: isSelected,
                onSelectChanged: (_) {
                  ref.read(selectedTripIdProvider.notifier).select(
                      isSelected ? null : trip.id);
                },
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
              );
            },
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
      case TripStatus.declined:
        color = const Color(0xFFF59E0B);
        label = 'Declined';
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
      onSelected: (value) {
        switch (value) {
          case 'view':
          case 'assign':
            ref.read(selectedTripIdProvider.notifier).select(trip.id);
          case 'cancel':
            _cancelTrip(trip);
        }
      },
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
                Text('Cancel Trip',
                    style: TextStyle(color: Color(0xFFEF4444))),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _cancelTrip(Trip trip) async {
    final reason = await CancelTripDialog.show(context);
    if (reason == null) return;

    try {
      await ref
          .read(tripRepositoryProvider)
          .cancelTrip(trip.id, reason: reason.isEmpty ? null : reason);
      ref.invalidate(tripsAsyncProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel trip: $e')),
        );
      }
    }
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