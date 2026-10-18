import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/models/route_point.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/features/trips/presentation/providers/trips_providers.dart';
import 'package:driveops_management/features/trips/presentation/widgets/trip_map_view.dart';
import 'package:driveops_management/features/trips/presentation/widgets/recommended_drivers_section.dart';
import 'package:driveops_management/features/trips/presentation/widgets/cancel_trip_dialog.dart';

/// Right-side panel for a selected trip: map, full details and contextual
/// actions. Fixed ~440px width, full height.
class TripDetailsPanel extends ConsumerWidget {
  final double width;

  const TripDetailsPanel({super.key, this.width = 440});

  bool _isAssignable(Trip trip) {
    return trip.driverId == null &&
        (trip.tripStatus == TripStatus.requested ||
            trip.tripStatus == TripStatus.noDriverAvailable);
  }

  bool _isCancellable(Trip trip) {
    return trip.tripStatus == TripStatus.assigned ||
        trip.tripStatus == TripStatus.driverEnRoute ||
        trip.tripStatus == TripStatus.inProgress;
  }

  Future<void> _cancelTrip(BuildContext context, WidgetRef ref, Trip trip) async {
    final reason = await CancelTripDialog.show(context);
    if (reason == null) return;

    try {
      await ref
          .read(tripRepositoryProvider)
          .cancelTrip(trip.id, reason: reason.isEmpty ? null : reason);
      ref.invalidate(tripsAsyncProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Trip cancelled')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel trip: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trip = ref.watch(selectedTripProvider);
    if (trip == null) return const SizedBox.shrink();

    final routePointsAsync = ref.watch(tripRoutePointsProvider);
    final driversMapAsync = ref.watch(driversMapProvider);

    LatLng? driverPosition;
    if (trip.driverId != null) {
      final driver = driversMapAsync.value?[trip.driverId];
      if (driver != null &&
          driver.currentLatitude != null &&
          driver.currentLongitude != null) {
        driverPosition = LatLng(
          driver.currentLatitude!,
          driver.currentLongitude!,
        );
      }
    }

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        border: Border(
          left: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(ref, trip),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 280,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: TripMapView(
                        pickupLatitude: trip.pickupLatitude,
                        pickupLongitude: trip.pickupLongitude,
                        dropoffLatitude: trip.dropoffLatitude,
                        dropoffLongitude: trip.dropoffLongitude,
                        routePoints: routePointsAsync.value ?? const <RoutePoint>[],
                        driverPosition: driverPosition,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_isAssignable(trip)) ...[
                    RecommendedDriversSection(trip: trip),
                    const SizedBox(height: 16),
                  ],
                  _buildInfoSection('Route', [
                    _buildInfoRow('Pickup', trip.pickupAddress),
                    _buildInfoRow('Dropoff', trip.dropoffAddress),
                  ]),
                  _buildInfoSection('Schedule', [
                    _buildInfoRow('Requested', _formatDateTime(trip.requestedAt)),
                    if (trip.scheduledAt != null)
                      _buildInfoRow('Scheduled', _formatDateTime(trip.scheduledAt!)),
                    if (trip.assignedAt != null)
                      _buildInfoRow('Assigned', _formatDateTime(trip.assignedAt!)),
                    if (trip.pickupTime != null)
                      _buildInfoRow('Picked up', _formatDateTime(trip.pickupTime!)),
                    if (trip.dropoffTime != null)
                      _buildInfoRow('Dropped off', _formatDateTime(trip.dropoffTime!)),
                  ]),
                  _buildInfoSection('Metrics', [
                    if (trip.estimatedDistance != null || trip.actualDistance != null)
                      _buildInfoRow(
                        'Distance',
                        _estimateVsActual(
                          trip.actualDistance?.toStringAsFixed(1),
                          trip.estimatedDistance?.toStringAsFixed(1),
                          unit: ' km',
                        ),
                      ),
                    if (trip.estimatedDuration != null || trip.actualDuration != null)
                      _buildInfoRow(
                        'Duration',
                        _estimateVsActual(
                          trip.actualDuration?.toString(),
                          trip.estimatedDuration?.toString(),
                          unit: ' min',
                        ),
                      ),
                    if (trip.estimatedFare != null || trip.actualFare != null)
                      _buildInfoRow(
                        'Fare',
                        _estimateVsActual(
                          trip.actualFare?.toStringAsFixed(2),
                          trip.estimatedFare?.toStringAsFixed(2),
                          prefix: '\$',
                        ),
                      ),
                  ]),
                  _buildInfoSection('People', [
                    _buildInfoRow('Customer', trip.customerName ?? trip.customerId),
                    _buildInfoRow('Driver', trip.driverName ?? 'Unassigned'),
                    _buildInfoRow('Vehicle', trip.vehiclePlate ?? '—'),
                  ]),
                  if (trip.paymentMethod != null || trip.paymentStatus != null)
                    _buildInfoSection('Payment', [
                      if (trip.paymentMethod != null)
                        _buildInfoRow('Method', _enumName(trip.paymentMethod!)),
                      if (trip.paymentStatus != null)
                        _buildInfoRow('Status', _enumName(trip.paymentStatus!)),
                    ]),
                  if (trip.customerRating != null || trip.driverRating != null)
                    _buildInfoSection('Ratings', [
                      if (trip.customerRating != null)
                        _buildInfoRow('Customer rating', '${trip.customerRating} / 5'),
                      if (trip.driverRating != null)
                        _buildInfoRow('Driver rating', '${trip.driverRating} / 5'),
                    ]),
                  if (trip.cancellationReason != null || trip.specialInstructions != null)
                    _buildInfoSection('Notes', [
                      if (trip.cancellationReason != null)
                        _buildInfoRow('Cancellation', trip.cancellationReason!),
                      if (trip.specialInstructions != null)
                        _buildInfoRow('Instructions', trip.specialInstructions!),
                    ]),
                ],
              ),
            ),
          ),
          if (_isCancellable(trip)) _buildFooter(context, ref, trip),
        ],
      ),
    );
  }

  Widget _buildHeader(WidgetRef ref, Trip trip) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Trip Details',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _statusChip(trip.tripStatus),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 18),
            onPressed: () => ref.read(selectedTripIdProvider.notifier).select(null),
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref, Trip trip) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFEF4444),
        ),
        onPressed: () => _cancelTrip(context, ref, trip),
        icon: const Icon(Icons.cancel, size: 16),
        label: const Text('Cancel Trip'),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF3B82F6),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF252538),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: rows),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _estimateVsActual(String? actual, String? estimated, {String? unit, String? prefix}) {
    final suffix = unit ?? '';
    final pre = prefix ?? '';
    if (actual != null && estimated != null && actual != estimated) {
      return '$pre$actual$suffix (est. $pre$estimated$suffix)';
    }
    final value = actual ?? estimated ?? '—';
    return '$pre$value$suffix';
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _enumName(Object value) {
    final name = value.toString().split('.').last;
    return name[0].toUpperCase() + name.substring(1);
  }

  Widget _statusChip(TripStatus status) {
    final (color, label) = switch (status) {
      TripStatus.completed => (const Color(0xFF22C55E), 'Completed'),
      TripStatus.cancelled => (const Color(0xFFEF4444), 'Cancelled'),
      TripStatus.noDriverAvailable => (const Color(0xFFF59E0B), 'No Driver'),
      TripStatus.declined => (const Color(0xFFF59E0B), 'Declined'),
      TripStatus.inProgress => (const Color(0xFF3B82F6), 'In Progress'),
      TripStatus.driverEnRoute => (const Color(0xFF8B5CF6), 'En Route'),
      TripStatus.assigned => (const Color(0xFF06B6D4), 'Assigned'),
      TripStatus.requested => (const Color(0xFF6B7280), 'Requested'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}
