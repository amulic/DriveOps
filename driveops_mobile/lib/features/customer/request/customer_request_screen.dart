import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:driveops_mobile/features/customer/payment/payment_providers.dart';
import 'package:driveops_mobile/features/customer/providers/customer_providers.dart';
import 'package:driveops_mobile/services/geocoding_api_service.dart';
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
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  LatLng? _dropoffPin;
  TripEstimateResponse? _estimate;
  List<GeocodingResult> _searchResults = [];
  bool _searching = false;
  String? _pickupAddress;
  String? _dropoffAddress;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _estimating = false;
  bool _confirming = false;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _recenter(LatLng position) => _mapController.move(position, 16);

  // -------------------------------------------------------------------------
  // Geocoding
  // -------------------------------------------------------------------------

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final q = query.trim();
    if (q.length < 3) {
      setState(() {
        _searchResults = [];
        _searching = false;
      });
      return;
    }
    _searchDebounce =
        Timer(const Duration(milliseconds: 500), () => _search(q));
  }

  Future<void> _search(String query) async {
    setState(() => _searching = true);
    try {
      final results = await ref.read(geocodingApiServiceProvider).search(query);
      // Ignore stale results if the query changed while fetching.
      if (mounted && _searchController.text.trim() == query) {
        setState(() {
          _searchResults = results;
          _searching = false;
        });
      }
    } catch (e) {
      debugPrint('Address search failed: $e');
      if (mounted && _searchController.text.trim() == query) {
        setState(() {
          _searchResults = [];
          _searching = false;
        });
      }
    }
  }

  void _selectSearchResult(GeocodingResult result, LatLng currentPos) {
    final pin = LatLng(result.latitude, result.longitude);
    _searchController.text = result.displayName;
    setState(() => _searchResults = []);
    FocusScope.of(context).unfocus();
    _mapController.move(pin, 16);
    // The search hit is already a resolved address — no reverse lookup needed.
    _onMapTap(pin, currentPos, preResolvedAddress: result.displayName);
  }

  /// Best-effort reverse geocode; failures keep the coordinate-label fallback.
  Future<void> _resolvePickupAddress(LatLng pos) async {
    if (_pickupAddress != null) return;
    try {
      final name = await ref
          .read(geocodingApiServiceProvider)
          .reverse(pos.latitude, pos.longitude);
      if (mounted && name != null) {
        setState(() => _pickupAddress = name);
      }
    } catch (e) {
      debugPrint('Reverse geocode (pickup) failed: $e');
    }
  }

  Future<void> _resolveDropoffAddress(LatLng pin) async {
    try {
      final name = await ref
          .read(geocodingApiServiceProvider)
          .reverse(pin.latitude, pin.longitude);
      // Ignore stale results if the pin moved again while fetching.
      if (mounted && _dropoffPin == pin) {
        setState(() => _dropoffAddress = name);
      }
    } catch (e) {
      debugPrint('Reverse geocode (dropoff) failed: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Pin + estimate + confirm
  // -------------------------------------------------------------------------

  Future<void> _onMapTap(LatLng pin, LatLng currentPos,
      {String? preResolvedAddress}) async {
    setState(() {
      _dropoffPin = pin;
      _estimate = null;
      _estimating = true;
      _dropoffAddress = preResolvedAddress;
    });
    if (preResolvedAddress == null) {
      unawaited(_resolveDropoffAddress(pin));
    }

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
    } catch (e) {
      if (e is DioException) {
        debugPrint('Estimate failed: ${e.response?.statusCode} '
            '${e.response?.data ?? e.message}');
      } else {
        debugPrint('Estimate failed: $e');
      }
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
            pickupAddress:
                _pickupAddress ?? 'Current location (${fmt(currentPos)})',
            dropoffLatitude: pin.latitude,
            dropoffLongitude: pin.longitude,
            dropoffAddress: _dropoffAddress ?? 'Pin (${fmt(pin)})',
            paymentMethod: _paymentMethod.toInt(),
          ));

      if (mounted) context.go('/customer/trip');
    } on StateError catch (e) {
      _showSnack(e.message);
      if (mounted) context.go('/customer/trip');
    } on DioException catch (e) {
      debugPrint('Trip creation failed: ${e.response?.statusCode} '
          '${e.response?.data ?? e.message}');
      if (e.response?.statusCode == 409) {
        // Server-side one-trip guard (double-tap / second device race).
        _showSnack('You already have an active trip.');
        ref.invalidate(customerActiveTripProvider);
        ref.invalidate(customerTripsProvider);
      } else if (e.response?.statusCode == 400) {
        // e.g. the server-side no-saved-card guard for card trips.
        final data = e.response?.data;
        final message =
            data is Map<String, dynamic> ? data['message'] as String? : null;
        _showSnack(message ?? 'Could not create the trip. Please try again.');
      } else {
        _showSnack('Could not create the trip. Please try again.');
      }
    } catch (e) {
      debugPrint('Trip creation failed: $e');
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

  /// Card trips are charged off-session to a saved card — require one upfront
  /// (the API enforces this too with a 400 as the race-safe backstop).
  void _onPaymentMethodChanged(PaymentMethod method) {
    final isCard = method == PaymentMethod.creditCard ||
        method == PaymentMethod.debitCard;
    if (isCard) {
      final cards = ref.read(savedCardsProvider).value;
      if (cards == null || cards.isEmpty) {
        _showSnack('Add a card first — Profile → Payment methods.');
        return;
      }
    }
    setState(() => _paymentMethod = method);
  }

  @override
  Widget build(BuildContext context) {
    final positionAsync = ref.watch(currentPositionProvider);

    // Resolve a human-readable pickup address once the GPS fix is available.
    ref.listen(currentPositionProvider, (previous, next) {
      final pos = next.value;
      if (pos != null) unawaited(_resolvePickupAddress(pos.latLng));
    });

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

    // Prefetch saved cards so the card chip check has data by the time the
    // user picks a payment method.
    ref.watch(savedCardsProvider);

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
        // Address search bar + results.
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search for an address',
                    hintStyle:
                        const TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: Colors.white38, size: 20),
                    suffixIcon: _searching
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          )
                        : (_searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.white38, size: 18),
                                tooltip: 'Clear search',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchResults = []);
                                },
                              )
                            : null),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
              ),
              if (_searchResults.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E).withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: _searchResults.length,
                    itemBuilder: (ctx, i) {
                      final r = _searchResults[i];
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.place_outlined,
                            color: Colors.white38, size: 18),
                        title: Text(
                          r.displayName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 13),
                        ),
                        onTap: () =>
                            _selectSearchResult(r, position.latLng),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        // Hint banner while no pin is set.
        if (pin == null)
          Positioned(
            top: 68,
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
              dropoffAddress: _dropoffAddress,
              paymentMethod: _paymentMethod,
              onPaymentMethodChanged: _onPaymentMethodChanged,
              onConfirm: () => _confirm(position.latLng),
              onClear: () => setState(() {
                _dropoffPin = null;
                _estimate = null;
                _estimating = false;
                _dropoffAddress = null;
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
  final String? dropoffAddress;
  final PaymentMethod paymentMethod;
  final ValueChanged<PaymentMethod> onPaymentMethodChanged;
  final VoidCallback onConfirm;
  final VoidCallback onClear;

  const _EstimateCard({
    required this.estimate,
    required this.estimating,
    required this.confirming,
    required this.dropoffAddress,
    required this.paymentMethod,
    required this.onPaymentMethodChanged,
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
            if (dropoffAddress != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dropoffAddress!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
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
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PaymentChip(
                      label: 'Cash',
                      icon: Icons.payments_outlined,
                      selected: paymentMethod == PaymentMethod.cash,
                      onSelected: () =>
                          onPaymentMethodChanged(PaymentMethod.cash),
                    ),
                    _PaymentChip(
                      label: 'Credit card',
                      icon: Icons.credit_card,
                      selected: paymentMethod == PaymentMethod.creditCard,
                      onSelected: () =>
                          onPaymentMethodChanged(PaymentMethod.creditCard),
                    ),
                    _PaymentChip(
                      label: 'Digital wallet',
                      icon: Icons.account_balance_wallet_outlined,
                      selected: paymentMethod == PaymentMethod.digitalWallet,
                      onSelected: () =>
                          onPaymentMethodChanged(PaymentMethod.digitalWallet),
                    ),
                  ],
                ),
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

class _PaymentChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _PaymentChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF3B82F6);
    return Material(
      color: selected ? accent.withValues(alpha: 0.2) : const Color(0xFF252538),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? accent : Colors.white12,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15,
                  color: selected ? accent : Colors.white54),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.white54,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
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
