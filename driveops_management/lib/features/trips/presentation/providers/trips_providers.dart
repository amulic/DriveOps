import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/route_point.dart';
import 'package:driveops_management/shared/models/recommended_driver.dart';
import 'package:driveops_management/shared/dtos/requests/trip_requests.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/services/trip_api_service.dart';

final tripsAsyncProvider = FutureProvider<List<Trip>>((ref) async {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getAllTrips();
});

final tripsDriversAsyncProvider = FutureProvider<List<Driver>>((ref) async {
  final repo = ref.watch(driverRepositoryProvider);
  return repo.getAllDrivers();
});

final driversMapProvider = Provider<AsyncValue<Map<String, Driver>>>((ref) {
  final driversAsync = ref.watch(tripsDriversAsyncProvider);
  return driversAsync.when(
    data: (drivers) => AsyncValue.data({for (final d in drivers) d.id: d}),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class TripsSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

class TripsStatusFilterNotifier extends Notifier<TripStatus?> {
  @override
  TripStatus? build() => null;

  void update(TripStatus? value) => state = value;
}

final tripsSearchQueryProvider = NotifierProvider<TripsSearchQueryNotifier, String>(TripsSearchQueryNotifier.new);
final tripsStatusFilterProvider = NotifierProvider<TripsStatusFilterNotifier, TripStatus?>(TripsStatusFilterNotifier.new);

final filteredTripsProvider = Provider<AsyncValue<List<Trip>>>((ref) {
  final tripsAsync = ref.watch(tripsAsyncProvider);
  final query = ref.watch(tripsSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(tripsStatusFilterProvider);

  return tripsAsync.when(
    data: (trips) {
      var result = trips;

      if (statusFilter != null) {
        result = result.where((t) => t.tripStatus == statusFilter).toList();
      }

      if (query.isNotEmpty) {
        result = result.where((t) {
          return t.pickupAddress.toLowerCase().contains(query) ||
              t.dropoffAddress.toLowerCase().contains(query) ||
              (t.driverName?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      return AsyncValue.data(result);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

class SelectedTripIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

/// Id of the trip whose details panel is open; null = panel closed.
final selectedTripIdProvider =
    NotifierProvider<SelectedTripIdNotifier, String?>(SelectedTripIdNotifier.new);

/// Live trip derived from the trips list — auto-refreshes when SignalR
/// invalidates the list provider.
final selectedTripProvider = Provider<Trip?>((ref) {
  final id = ref.watch(selectedTripIdProvider);
  if (id == null) return null;

  final tripsAsync = ref.watch(tripsAsyncProvider);
  return tripsAsync.value?.where((t) => t.id == id).firstOrNull;
});

/// Route points for the selected trip: recorded breadcrumbs for
/// in-progress/completed trips, OSRM planned geometry otherwise, with a
/// straight pickup→dropoff line as the final fallback.
final tripRoutePointsProvider = FutureProvider<List<RoutePoint>>((ref) async {
  final trip = ref.watch(selectedTripProvider);
  if (trip == null) return [];

  final repo = ref.watch(tripRepositoryProvider);

  List<RoutePoint> recorded = [];
  if (trip.tripStatus == TripStatus.inProgress ||
      trip.tripStatus == TripStatus.completed) {
    recorded = await repo.getTripRoute(trip.id);
    if (recorded.length >= 2) return recorded;
  }

  List<RoutePoint> planned = [];
  try {
    final estimate = await ref.watch(tripApiServiceProvider).estimateTrip(
          TripEstimateRequest(
            pickupLatitude: trip.pickupLatitude,
            pickupLongitude: trip.pickupLongitude,
            dropoffLatitude: trip.dropoffLatitude,
            dropoffLongitude: trip.dropoffLongitude,
            tripType: trip.tripType.toInt(),
          ),
        );
    planned = estimate.routePoints;
  } catch (_) {
    // OSRM unavailable — fall through to the straight-line fallback.
  }

  if (planned.length >= 2) return planned;

  return [
    RoutePoint(latitude: trip.pickupLatitude, longitude: trip.pickupLongitude),
    RoutePoint(latitude: trip.dropoffLatitude, longitude: trip.dropoffLongitude),
  ];
});

/// True when the selected trip can receive a driver assignment.
bool _isAssignable(Trip? trip) {
  if (trip == null) return false;
  return trip.driverId == null &&
      (trip.tripStatus == TripStatus.requested ||
          trip.tripStatus == TripStatus.noDriverAvailable);
}

/// Ranked driver recommendations for the selected trip; empty when the trip
/// is not assignable.
final recommendedDriversProvider = FutureProvider<List<RecommendedDriver>>((ref) async {
  final trip = ref.watch(selectedTripProvider);
  if (!_isAssignable(trip)) return [];

  final repo = ref.watch(tripRepositoryProvider);
  return repo.getRecommendedDrivers(trip!.id);
});