import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/repositories/repositories.dart';
import 'package:driveops_management/shared/repositories/dummy_repositories.dart';
import 'package:driveops_management/shared/repositories/api_repositories.dart';
import 'package:driveops_management/services/cache_service.dart';
import 'package:driveops_management/services/api_service.dart';
import 'package:driveops_management/services/driver_api_service.dart';
import 'package:driveops_management/services/trip_api_service.dart';
import 'package:driveops_management/services/vehicle_api_service.dart';
import 'package:driveops_management/shared/providers/auth_provider.dart';

final useDummyDataProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return !(authState.value?.isAuthenticated ?? false);
});

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

final driverApiServiceProvider = Provider<DriverApiService>((ref) {
  return DriverApiService(ref.watch(apiServiceProvider));
});

final tripApiServiceProvider = Provider<TripApiService>((ref) {
  return TripApiService(ref.watch(apiServiceProvider));
});

final vehicleApiServiceProvider = Provider<VehicleApiService>((ref) {
  return VehicleApiService(ref.watch(apiServiceProvider));
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  final useDummy = ref.watch(useDummyDataProvider);
  if (useDummy) {
    return DummyDriverRepository();
  }
  final cache = ref.watch(cacheServiceProvider);
  return ApiDriverRepository(
    ref.watch(driverApiServiceProvider),
    cache,
  );
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final useDummy = ref.watch(useDummyDataProvider);
  if (useDummy) {
    return DummyTripRepository();
  }
  final cache = ref.watch(cacheServiceProvider);
  return ApiTripRepository(
    ref.watch(tripApiServiceProvider),
    cache,
  );
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final useDummy = ref.watch(useDummyDataProvider);
  if (useDummy) {
    return DummyVehicleRepository();
  }
  final cache = ref.watch(cacheServiceProvider);
  return ApiVehicleRepository(
    ref.watch(vehicleApiServiceProvider),
    cache,
  );
});

final allDriversProvider = FutureProvider<List<Driver>>((ref) async {
  final repo = ref.watch(driverRepositoryProvider);
  return repo.getAllDrivers();
});

final activeDriversProvider = FutureProvider<List<Driver>>((ref) async {
  final repo = ref.watch(driverRepositoryProvider);
  return repo.getActiveDrivers();
});

final allTripsProvider = FutureProvider<List<Trip>>((ref) async {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getAllTrips();
});

final allVehiclesProvider = FutureProvider<List<Vehicle>>((ref) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getAllVehicles();
});

final vehiclesNeedingServiceProvider = FutureProvider<List<Vehicle>>((ref) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getVehiclesNeedingService();
});

final totalRevenueProvider = FutureProvider<double>((ref) async {
  final driversAsync = ref.watch(allDriversProvider);
  return driversAsync.when(
    data: (drivers) => drivers.fold<double>(0.0, (sum, d) => sum + d.totalRevenue),
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final driverScoreboardProvider = FutureProvider<List<Driver>>((ref) async {
  final driversAsync = ref.watch(allDriversProvider);
  return driversAsync.when(
    data: (drivers) {
      final sorted = List<Driver>.from(drivers)
        ..sort((a, b) {
          final ratingCompare = b.rating.compareTo(a.rating);
          if (ratingCompare != 0) return ratingCompare;
          return b.totalTrips.compareTo(a.totalTrips);
        });
      return sorted.take(5).toList();
    },
    loading: () => <Driver>[],
    error: (_, __) => <Driver>[],
  );
});

final tripStatisticsProvider = FutureProvider<Map<String, int>>((ref) async {
  final tripsAsync = ref.watch(allTripsProvider);
  return tripsAsync.when(
    data: (trips) {
      final completed = trips.where((t) => t.tripStatus == TripStatus.completed).length;
      final cancelled = trips.where((t) => t.tripStatus == TripStatus.cancelled).length;
      final noDriver = trips.where((t) => t.tripStatus == TripStatus.noDriverAvailable).length;
      return {'completed': completed, 'cancelled': cancelled, 'noDriverAvailable': noDriver};
    },
    loading: () => {'completed': 0, 'cancelled': 0, 'noDriverAvailable': 0},
    error: (_, __) => {'completed': 0, 'cancelled': 0, 'noDriverAvailable': 0},
  );
});