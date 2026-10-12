import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:driveops_mobile/features/driver/providers/map_providers.dart';
import 'package:driveops_mobile/shared/location/current_position_provider.dart';
import 'package:driveops_mobile/shared/location/location_service.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'package:driveops_mobile/shared/widgets/map/drive_ops_map.dart';
import 'package:driveops_mobile/shared/widgets/map/map_markers.dart';
import 'package:driveops_mobile/shared/widgets/map/map_utils.dart';
import 'package:driveops_mobile/shared/widgets/map/route_polyline_layer.dart';

/// Driver live map: current position + active-trip guidance.
///
/// Two trip modes:
/// - **Driving to pickup** (assigned/en-route): route to the customer,
///   Start/Decline actions.
/// - **Trip in progress** (in-progress): route to the dropoff,
///   Complete action.
class DriverMapScreen extends ConsumerStatefulWidget {
  const DriverMapScreen({super.key});

  @override
  ConsumerState<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends ConsumerState<DriverMapScreen> {
  final MapController _mapController = MapController();
  String? _fittedTripId;
  bool _actionInFlight = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenter(LatLng position) {
    _mapController.move(position, 16);
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);
    final trip = ref.watch(driverActiveTripProvider).value;
    final route = ref.watch(activeTripRouteProvider);
    final position = positionAsync.value;

    // One-shot camera fit when a trip becomes active.
    if (trip != null && position != null && _fittedTripId != trip.id) {
      _fittedTripId = trip.id;
      final boundsPoints = [
        position.latLng,
        LatLng(trip.pickupLatitude, trip.pickupLongitude),
        LatLng(trip.dropoffLatitude, trip.dropoffLongitude),
      ];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _mapController.fitCamera(fitMapBounds(boundsPoints));
        } catch (_) {
          // Map not attached yet — the recenter FAB still works.
        }
      });
    }
    if (trip == null && _fittedTripId != null) {
      _fittedTripId = null;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Map'),
      ),
      body: switch (positionAsync) {
        AsyncValue(hasError: true, :final error) =>
          _LocationError(error: error),
        AsyncValue(value: null) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
        _ => Stack(
            children: [
              DriveOpsMap(
                mapController: _mapController,
                initialCenter: position!.latLng,
                layers: [
                  if (trip != null)
                    routePolylineLayer(
                      route.points,
                      fallbackStart: position.latLng,
                      fallbackEnd: _legDestinationOf(trip),
                    ),
                  CircleLayer(circles: [
                    currentLocationAccuracyCircle(
                        position.latLng, position.accuracyMeters),
                  ]),
                  MarkerLayer(markers: [
                    currentLocationMarker(position.latLng),
                    if (trip != null)
                      pickupMarker(
                          LatLng(trip.pickupLatitude, trip.pickupLongitude)),
                    if (trip != null)
                      dropoffMarker(
                          LatLng(trip.dropoffLatitude, trip.dropoffLongitude)),
                  ]),
                ],
              ),
              Positioned(
                right: 16,
                bottom: trip != null ? 208 : 32,
                child: FloatingActionButton.small(
                  heroTag: 'recenter',
                  backgroundColor: const Color(0xFF252538),
                  onPressed: () => _recenter(position.latLng),
                  child: const Icon(Icons.my_location,
                      color: Color(0xFF3B82F6), size: 20),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _TripPanel(
                  trip: trip,
                  route: route,
                  actionInFlight: _actionInFlight,
                  onAction: _runAction,
                ),
              ),
            ],
          ),
      },
    );
  }

  LatLng _legDestinationOf(Trip trip) {
    return trip.tripStatus == TripStatus.inProgress
        ? LatLng(trip.dropoffLatitude, trip.dropoffLongitude)
        : LatLng(trip.pickupLatitude, trip.pickupLongitude);
  }

  Future<void> _runAction(Future<void> Function(TripActions) action,
      {String? successMessage}) async {
    if (_actionInFlight) return;
    setState(() => _actionInFlight = true);
    try {
      await action(ref.read(tripActionsProvider));
      if (mounted && successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(successMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Action failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _actionInFlight = false);
    }
  }
}

class _TripPanel extends StatelessWidget {
  final Trip? trip;
  final ActiveTripRouteState route;
  final bool actionInFlight;
  final Future<void> Function(Future<void> Function(TripActions),
      {String? successMessage}) onAction;

  const _TripPanel({
    required this.trip,
    required this.route,
    required this.actionInFlight,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final trip = this.trip;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: trip == null ? _buildIdle() : _buildTrip(context, trip),
    );
  }

  Widget _buildIdle() {
    return const Row(
      children: [
        Icon(Icons.map_outlined, color: Color(0xFF3B82F6), size: 28),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('No active trip',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 2),
              Text('Your route will appear here once a trip is assigned.',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrip(BuildContext context, Trip trip) {
    final toPickup = trip.tripStatus != TripStatus.inProgress;
    final title = toPickup ? 'Driving to pickup' : 'Trip in progress';
    final address = toPickup ? trip.pickupAddress : trip.dropoffAddress;
    final accent =
        toPickup ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Text(title,
                  style: TextStyle(
                      color: accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            if (route.distanceKm != null)
              _chip('${route.distanceKm!.toStringAsFixed(1)} km'),
            const SizedBox(width: 6),
            if (route.durationMin != null) _chip('~${route.durationMin} min'),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Icon(toPickup ? Icons.trip_origin : Icons.location_on,
                color: toPickup
                    ? const Color(0xFF22C55E)
                    : const Color(0xFFEF4444),
                size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        if (toPickup && trip.customerName != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_outline,
                  color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text(trip.customerName!,
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ],
        const SizedBox(height: 14),
        Row(
          children: [
            if (toPickup) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: actionInFlight
                      ? null
                      : () async {
                          final confirmed = await _confirm(
                            context,
                            title: 'Decline trip?',
                            message:
                                'The trip will be returned to the dispatcher.',
                            confirmLabel: 'Decline',
                          );
                          if (confirmed) {
                            await onAction(
                                (a) => a.declineTrip(trip.id).then((_) {}));
                          }
                        },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: actionInFlight
                      ? null
                      : () => onAction((a) => a.startTrip(trip.id).then((_) {}),
                          successMessage: 'Trip started — heading to dropoff.'),
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6)),
                  child: actionInFlight
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Start trip'),
                ),
              ),
            ] else
              Expanded(
                child: FilledButton(
                  onPressed: actionInFlight
                      ? null
                      : () async {
                          final confirmed = await _confirm(
                            context,
                            title: 'Complete trip?',
                            message:
                                'The fare will be calculated from the driven distance.',
                            confirmLabel: 'Complete',
                          );
                          if (confirmed) {
                            await onAction(
                                (a) => a.completeTrip(trip.id).then((_) {}),
                                successMessage: 'Trip completed.');
                          }
                        },
                  style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E)),
                  child: actionInFlight
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Complete trip'),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF252538),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 12)),
    );
  }

  Future<bool> _confirm(BuildContext context,
      {required String title,
      required String message,
      required String confirmLabel}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content:
            Text(message, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6)),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

/// Shown when GPS is unavailable (service off, permission denied...).
class _LocationError extends ConsumerWidget {
  final Object? error;

  const _LocationError({this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = error is LocationPermissionException
        ? (error! as LocationPermissionException).state
        : null;

    final (icon, title, message, actionLabel) = switch (state) {
      LocationPermissionState.serviceDisabled => (
          Icons.location_off_outlined,
          'Location is turned off',
          'Enable location services so the map can show your position.',
          'Turn on location'
        ),
      LocationPermissionState.deniedForever => (
          Icons.location_disabled_outlined,
          'Location permission blocked',
          'The permission was permanently denied. Enable it in the app '
              'settings to use the map.',
          'Open app settings'
        ),
      _ => (
          Icons.location_searching,
          'Location permission needed',
          'DriveOps needs your position to show the map and guide trips.',
          'Grant permission'
        ),
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: const Color(0xFF3B82F6)),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final service = ref.read(locationServiceProvider);
                switch (state) {
                  case LocationPermissionState.serviceDisabled:
                    await service.openLocationSettings();
                  case LocationPermissionState.deniedForever:
                    await service.openAppSettings();
                  default:
                    break;
                }
                ref.invalidate(currentPositionProvider);
              },
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6)),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
