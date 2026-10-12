import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:driveops_mobile/services/auth_service.dart';
import 'package:driveops_mobile/services/location_signalr_service.dart';
import 'package:driveops_mobile/shared/dtos/requests/trip_requests.dart';
import 'package:driveops_mobile/shared/location/current_position_provider.dart';
import 'package:driveops_mobile/shared/models/route_point.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';
import 'package:driveops_mobile/shared/widgets/map/map_utils.dart';
import 'package:driveops_mobile/features/driver/providers/driver_providers.dart';

// ---------------------------------------------------------------------------
// Location hub connection
// ---------------------------------------------------------------------------

final locationSignalrServiceProvider = Provider<LocationSignalrService>((ref) {
  final service = LocationSignalrService();
  ref.onDispose(() {
    service.disconnect();
    service.dispose();
  });
  return service;
});

/// Connects the location hub while the user is authenticated.
final locationSignalrConnectionProvider = Provider<void>((ref) {
  final signalr = ref.watch(locationSignalrServiceProvider);
  final authState = ref.watch(authProvider);

  if (authState.value?.isAuthenticated == true) {
    AuthService().getAccessToken().then((t) {
      if (t != null) signalr.connect(t);
    });
  } else {
    signalr.disconnect();
  }
});

// ---------------------------------------------------------------------------
// Active trip (also the future data source for the "trip in progress" banner)
// ---------------------------------------------------------------------------

/// The driver's current trip (assigned / en-route / in-progress), or null.
///
/// `/active` also returns declined trips, so they are filtered client-side.
/// Refreshes immediately, then polls every 30 s; invalidate for an instant
/// refresh (tab tap, trip action, TripStatusChanged push).
final driverActiveTripProvider = StreamProvider.autoDispose<Trip?>((ref) async* {
  final driver = await ref.watch(currentDriverProvider.future);
  if (driver == null) {
    yield null;
    return;
  }
  final repo = ref.watch(tripRepositoryProvider);

  Future<Trip?> fetch() async {
    final trips = await repo.getActiveTripsByDriver(driver.id);
    final active = trips
        .where((t) =>
            t.tripStatus == TripStatus.assigned ||
            t.tripStatus == TripStatus.driverEnRoute ||
            t.tripStatus == TripStatus.inProgress)
        .toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
    return active.isEmpty ? null : active.first;
  }

  yield await fetch();
  await for (final _ in Stream.periodic(const Duration(seconds: 30))) {
    yield await fetch();
  }
});

// ---------------------------------------------------------------------------
// Driver GPS streaming (active trip only)
// ---------------------------------------------------------------------------

/// Forwards device GPS fixes to the LocationHub while a trip is active.
/// Watched by the DriverShell so streaming runs regardless of the open tab.
final driverLocationStreamingProvider = Provider<void>((ref) {
  final activeTripId =
      ref.watch(driverActiveTripProvider.select((a) => a.value?.id));
  if (activeTripId == null) return;

  ref.watch(locationSignalrConnectionProvider);
  final hub = ref.watch(locationSignalrServiceProvider);

  final sub = ref.listen(currentPositionProvider, (previous, next) {
    final position = next.value;
    if (position != null) {
      hub.sendDriverLocation(position.latLng);
    }
  });
  ref.onDispose(sub.close);
});

// ---------------------------------------------------------------------------
// Route for the current trip leg
// ---------------------------------------------------------------------------

class ActiveTripRouteState {
  final List<RoutePoint> points;
  final double? distanceKm;
  final int? durationMin;
  final bool loading;

  const ActiveTripRouteState({
    this.points = const [],
    this.distanceKm,
    this.durationMin,
    this.loading = false,
  });
}

/// Computes the route polyline for the current leg via POST /api/trip/estimate:
/// assigned/en-route → current position to pickup; in-progress → to dropoff.
/// Refetches when the leg changes or the driver moved >100 m since routing.
class ActiveTripRouteNotifier extends Notifier<ActiveTripRouteState> {
  LatLng? _lastOrigin;
  String? _lastLegKey;
  List<RoutePoint> _points = const [];
  double? _distanceKm;
  int? _durationMin;
  bool _loading = false;

  @override
  ActiveTripRouteState build() {
    final trip = ref.watch(driverActiveTripProvider.select((a) => a.value));
    final position = ref.watch(currentPositionProvider.select((a) => a.value));

    if (trip == null || position == null) {
      return _reset();
    }

    final destination = _legDestination(trip);
    if (destination == null) {
      return _reset();
    }

    final legKey = '${trip.id}:${trip.tripStatus}';
    final movedEnough = _lastOrigin == null ||
        haversineMeters(_lastOrigin!, position.latLng) > 100;

    if (legKey != _lastLegKey || movedEnough) {
      _lastLegKey = legKey;
      _lastOrigin = position.latLng;
      _loading = true;
      Future.microtask(() => _fetch(trip, position.latLng, destination));
    }

    return ActiveTripRouteState(
      points: _points,
      distanceKm: _distanceKm,
      durationMin: _durationMin,
      loading: _loading,
    );
  }

  ActiveTripRouteState _reset() {
    _lastOrigin = null;
    _lastLegKey = null;
    _points = const [];
    _distanceKm = null;
    _durationMin = null;
    _loading = false;
    return const ActiveTripRouteState();
  }

  LatLng? _legDestination(Trip trip) {
    return switch (trip.tripStatus) {
      TripStatus.assigned ||
      TripStatus.driverEnRoute =>
        LatLng(trip.pickupLatitude, trip.pickupLongitude),
      TripStatus.inProgress =>
        LatLng(trip.dropoffLatitude, trip.dropoffLongitude),
      _ => null,
    };
  }

  Future<void> _fetch(Trip trip, LatLng origin, LatLng destination) async {
    try {
      final estimate = await ref.read(tripRepositoryProvider).estimateTrip(
            TripEstimateRequest(
              pickupLatitude: origin.latitude,
              pickupLongitude: origin.longitude,
              dropoffLatitude: destination.latitude,
              dropoffLongitude: destination.longitude,
              tripType: trip.tripType.toInt(),
            ),
          );
      _points = estimate.routePoints;
      _distanceKm = estimate.distanceKm;
      _durationMin = estimate.durationMinutes;
    } catch (_) {
      // Keep the previous route; the next position update retries.
    } finally {
      _loading = false;
      state = ActiveTripRouteState(
        points: _points,
        distanceKm: _distanceKm,
        durationMin: _durationMin,
        loading: false,
      );
    }
  }
}

final activeTripRouteProvider =
    NotifierProvider<ActiveTripRouteNotifier, ActiveTripRouteState>(
        ActiveTripRouteNotifier.new);

// ---------------------------------------------------------------------------
// Distance tracker (accumulates real km while the trip is in progress)
// ---------------------------------------------------------------------------

/// Accumulates haversine distance over GPS fixes while the trip is inProgress.
/// Used as the actualDistance when completing a trip (fallback: estimate).
class TripDistanceTracker extends Notifier<double> {
  LatLng? _last;

  @override
  double build() {
    final status =
        ref.watch(driverActiveTripProvider.select((a) => a.value?.tripStatus));

    if (status != TripStatus.inProgress) {
      _last = null;
      return 0;
    }

    ref.listen(currentPositionProvider, (previous, next) {
      final position = next.value;
      if (position == null) return;
      final last = _last;
      if (last != null) {
        final meters = haversineMeters(last, position.latLng);
        // Filter GPS noise (<3 m) and teleport jumps (>1 km between fixes).
        if (meters > 3 && meters < 1000) {
          state = state + meters / 1000;
        }
      }
      _last = position.latLng;
    });

    return 0;
  }
}

final tripDistanceTrackerProvider =
    NotifierProvider<TripDistanceTracker, double>(TripDistanceTracker.new);

// ---------------------------------------------------------------------------
// Trip actions surfaced to the map screen
// ---------------------------------------------------------------------------

/// Listens for server-pushed trip status changes (assignments/cancellations
/// made elsewhere) and refreshes the active-trip + history providers.
final driverTripPushProvider = Provider<void>((ref) {
  ref.watch(notificationSignalrConnectionProvider);
  final signalr = ref.watch(notificationSignalrServiceProvider);

  void handler(List<dynamic>? args) {
    ref.invalidate(driverActiveTripProvider);
    ref.invalidate(driverTripsProvider);
  }

  signalr.on('TripStatusChanged', handler);
  ref.onDispose(() => signalr.off('TripStatusChanged'));
});

final tripActionsProvider = Provider<TripActions>((ref) => TripActions(ref));

class TripActions {
  final Ref _ref;
  TripActions(this._ref);

  void _refresh() {
    _ref.invalidate(driverActiveTripProvider);
    _ref.invalidate(driverTripsProvider);
  }

  Future<Trip> startTrip(String tripId) async {
    final trip = await _ref.read(tripRepositoryProvider).startTrip(tripId);
    _refresh();
    return trip;
  }

  Future<Trip> completeTrip(String tripId) async {
    final tracked = _ref.read(tripDistanceTrackerProvider);
    final fallback =
        _ref.read(driverActiveTripProvider).value?.estimatedDistance ?? 0;
    final trip = await _ref
        .read(tripRepositoryProvider)
        .completeTrip(tripId, tracked > 0 ? tracked : fallback);
    _refresh();
    return trip;
  }

  Future<Trip?> declineTrip(String tripId) async {
    final driver = _ref.read(currentDriverProvider).value;
    if (driver == null) return null;
    final trip = await _ref
        .read(tripRepositoryProvider)
        .declineTrip(tripId, driver.id, reason: 'Declined by driver');
    _refresh();
    return trip;
  }
}
