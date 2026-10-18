import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:driveops_mobile/features/customer/providers/customer_providers.dart';
import 'package:driveops_mobile/shared/dtos/requests/trip_requests.dart';
import 'package:driveops_mobile/shared/location/current_position_provider.dart';
import 'package:driveops_mobile/shared/location/location_service.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';
import 'package:driveops_mobile/shared/widgets/map/drive_ops_map.dart';
import 'package:driveops_mobile/shared/widgets/map/map_markers.dart';
import 'package:driveops_mobile/shared/widgets/map/route_polyline_layer.dart';

/// Request a trip: map at the customer's current position, tap to drop the
/// destination pin, review the estimate card, confirm to create the trip.
class CustomerRequestScreen extends ConsumerStatefulWidget {
  const CustomerRequestScreen({super.key});

  @override
  ConsumerState<CustomerRequestScreen> createState() =>
      _CustomerRequestScreenState();
}

class _CustomerRequestScreenState extends ConsumerState<CustomerRequestScreen> {
  final MapController _mapController = MapController();
  LatLng? _dropoffPin;
  TripEstimateResponse? _estimate;
  bool _estimating = false;
  bool _confirming = false;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _recenter(LatLng position) => _mapController.move(position, 16);

  Future<void> _onMapTap(LatLng pin, LatLng currentPos) async {
    setState(() {
      _dropoffPin = pin;
      _estimate = null;
      _estimating = true;
    });

    try {
      final repo = ref.read(tripRepositoryProvider);
      final estimate = await repo.estimateTrip(TripEstimateRequest(
        pickupLatitude: currentPos.latitude,
        pickupLongitude: currentPos.longitude,
        dropoffLatitude: pin.latitude,
        dropoffLongitude: pin.longitude,
        tripType: TripType.standard.toInt(),
      ));
      // Ignore stale results if the pin moved again while fetching.
      if (mounted && _dropoffPin == pin) {
        setState(() {
          _estimate = estimate;
          _estimating = false;
        });
      }
    } catch (_) {
      if (mounted && _dropoffPin == pin) {
        setState(() => _estimating = false);
        _showSnack('Could not get an estimate for that destination.');
      }
    }
  }

  Future<void> _confirm(LatLng currentPos) async {
    final pin = _dropoffPin;
    if (pin == null || _confirming) return;

    setState(() => _confirming = true);

    try {
      final customer = await ref.read(currentCustomerProvider.future);
      if (customer == null) {
        _showSnack('Profile not loaded yet. Please try again.');
        return;
      }

      String fmt(LatLng p) =>
          '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';

      await ref.read(customerTripActionsProvider).requestTrip(CreateTripRequest(
            customerId: customer.id,
            tripType: TripType.standard.toInt(),
            pickupLatitude: currentPos.latitude,
            pickupLongitude: currentPos.longitude,
            pickupAddress: 'Current location (${fmt(currentPos)})',
            dropoffLatitude: pin.latitude,
            dropoffLongitude: pin.longitude,
            dropoffAddress: 'Pin (${fmt(pin)})',
          ));

      if (mounted) context.go('/customer/trip');
    } on StateError catch (e) {
      _showSnack(e.message);
      if (mounted) context.go('/customer/trip');
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        // Server-side one-trip guard (double-tap / second device race).
        _showSnack('You already have an active trip.');
        ref.invalidate(customerActiveTripProvider);
        ref.invalidate(customerTripsProvider);
      } else {
        _showSnack('Could not create the trip. Please try again.');
      }
    } catch (_) {
      _showSnack('Could not create the trip. Please try again.');
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Request a trip'),
      ),
      body: switch (positionAsync) {
        AsyncValue(hasError: true, :final error) => _LocationError(error: error),
        AsyncValue(value: null) => const Center(
            child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
        _ => _buildMap(positionAsync.value!),
      },
    );
  }

  Widget _buildMap(DevicePosition position) {
    final pin = _dropoffPin;

    return Stack(
      children: [
        DriveOpsMap(
          mapController: _mapController,
          initialCenter: position.latLng,
          onTap: (_, latlng) => _onMapTap(latlng, position.latLng),
          layers: [
            if (_estimate != null)
              routePolylineLayer(
                _estimate!.routePoints,
                fallbackStart: position.latLng,
                fallbackEnd: pin,
              ),
            CircleLayer(circles: [
              currentLocationAccuracyCircle(
                  position.latLng, position.accuracyMeters),
            ]),
            MarkerLayer(markers: [
              currentLocationMarker(position.latLng),
              if (pin != null) dropoffMarker(pin),
            ]),
          ],
        ),
        // Hint banner while no pin is set.
        if (pin == null)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white12),
              ),
              child: const Text(
                'Tap the map to drop your destination pin',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ),
        Positioned(
          right: 16,
          bottom: pin != null ? 208 : 32,
          child: FloatingActionButton.small(
            heroTag: 'recenter',
            backgroundColor: const Color(0xFF252538),
            onPressed: () => _recenter(position.latLng),
            child: const Icon(Icons.my_location,
                color: Color(0xFF3B82F6), size: 20),
          ),
        ),
        if (pin != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _EstimateCard(
              estimate: _estimate,
              estimating: _estimating,
              confirming: _confirming,
              onConfirm: () => _confirm(position.latLng),
              onClear: () => setState(() {
                _dropoffPin = null;
                _estimate = null;
                _estimating = false;
              }),
            ),
          ),
      ],
    );
  }
}

class _EstimateCard extends StatelessWidget {
  final TripEstimateResponse? estimate;
  final bool estimating;
  final bool confirming;
  final VoidCallback onConfirm;
  final VoidCallback onClear;

  const _EstimateCard({
    required this.estimate,
    required this.estimating,
    required this.confirming,
    required this.onConfirm,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Trip estimate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                  tooltip: 'Clear destination',
                  onPressed: confirming ? null : onClear,
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (estimating || estimate == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child:
                      CircularProgressIndicator(color: Color(0xFF3B82F6)),
                ),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _EstimateValue(
                    label: 'Distance',
                    value: '${estimate!.distanceKm.toStringAsFixed(1)} km',
                  ),
                  _EstimateValue(
                    label: 'Duration',
                    value: '~${estimate!.durationMinutes} min',
                  ),
                  _EstimateValue(
                    label: 'Fare',
                    value: '\$${estimate!.estimatedFare.toStringAsFixed(2)}',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: confirming ? null : onConfirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: confirming
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Confirm pickup',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EstimateValue extends StatelessWidget {
  final String label;
  final String value;

  const _EstimateValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 12),
        ),
      ],
    );
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
          'DriveOps needs your position to pick you up.',
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
