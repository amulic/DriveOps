import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/models/route_point.dart';
import 'package:driveops_management/shared/models/recommended_driver.dart';
import 'package:driveops_management/shared/models/keycloak_candidate.dart';
import 'package:driveops_management/services/driver_api_service.dart';
import 'package:driveops_management/services/trip_api_service.dart';
import 'package:driveops_management/services/vehicle_api_service.dart';
import 'package:driveops_management/services/cache_service.dart';
import 'package:driveops_management/shared/repositories/repositories.dart';
import 'package:driveops_management/shared/dtos/requests/driver_requests.dart';
import 'package:driveops_management/shared/dtos/requests/vehicle_requests.dart';
import 'package:driveops_management/shared/dtos/requests/trip_requests.dart';

class ApiDriverRepository implements DriverRepository {
  final DriverApiService _api;
  final CacheService _cache;

  ApiDriverRepository(this._api, this._cache);

  @override
  Future<List<Driver>> getAllDrivers() async {
    final cached = _cache.get(CacheService.driversAll);
    if (cached != null) {
      return (cached as List).map((e) => Driver.fromJson(e as Map<String, dynamic>)).toList();
    }
    final drivers = await _api.getAllDrivers();
    await _cache.setList(CacheService.driversAll, drivers.map((d) => d.toJson()).toList());
    return drivers;
  }

  @override
  Future<List<Driver>> getActiveDrivers() async {
    final cached = _cache.get(CacheService.driversActive);
    if (cached != null) {
      return (cached as List).map((e) => Driver.fromJson(e as Map<String, dynamic>)).toList();
    }
    final drivers = await _api.getAllDrivers();
    final active = drivers.where((d) => d.status == DriverStatus.active).toList();
    await _cache.setList(CacheService.driversActive, active.map((d) => d.toJson()).toList());
    return active;
  }

  @override
  Future<List<Driver>> getAvailableDrivers() async {
    final cached = _cache.get(CacheService.driversAvailable);
    if (cached != null) {
      return (cached as List).map((e) => Driver.fromJson(e as Map<String, dynamic>)).toList();
    }
    final drivers = await _api.getAvailableDrivers();
    await _cache.setList(CacheService.driversAvailable, drivers.map((d) => d.toJson()).toList());
    return drivers;
  }

  @override
  Future<Driver?> getDriverById(String id) async {
    final cached = _cache.get(CacheService.driver(id));
    if (cached != null) {
      return Driver.fromJson(cached as Map<String, dynamic>);
    }
    final driver = await _api.getDriver(id);
    await _cache.setSingle(CacheService.driver(id), driver.toJson());
    return driver;
  }

  @override
  Future<Driver?> getDriverByKeycloakId(String keycloakId) async {
    try {
      return await _api.getDriverByKeycloakId(keycloakId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Driver>> getNearbyDrivers(
      double latitude, double longitude, double radiusKm) async {
    return _api.getNearbyDrivers(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  // The driver list caches are interdependent: a status/online change moves a
  // driver between the all/active/available lists, so every mutation drops all
  // three (plus the single-driver entry). Without this the Drivers tab, Assign
  // Driver and New Conversation lists stay stale for up to the 5-min list TTL —
  // e.g. an approved (Pending→Active) driver would not become messagable.
  Future<void> _invalidateDriverCaches([String? id]) async {
    await _cache.remove(CacheService.driversAll);
    await _cache.remove(CacheService.driversActive);
    await _cache.remove(CacheService.driversAvailable);
    if (id != null) await _cache.remove(CacheService.driver(id));
  }

  @override
  Future<Driver> createDriver(CreateDriverRequest request) async {
    final driver = await _api.createDriver(request);
    await _invalidateDriverCaches();
    return driver;
  }

  // Promotion candidates are live Keycloak data — not cached.
  @override
  Future<List<KeycloakCandidate>> getPromotionCandidates(String search) {
    return _api.getPromotionCandidates(search);
  }

  @override
  Future<Driver> promoteDriver(CreateDriverRequest request) async {
    final driver = await _api.promoteDriver(request);
    await _invalidateDriverCaches();
    return driver;
  }

  @override
  Future<Driver> onboardDriver(OnboardDriverRequest request) async {
    final driver = await _api.onboardDriver(request);
    await _invalidateDriverCaches();
    return driver;
  }

  @override
  Future<Driver> updateDriver(String id, UpdateDriverRequest request) async {
    final driver = await _api.updateDriver(id, request);
    await _invalidateDriverCaches(id);
    return driver;
  }

  @override
  Future<void> suspendDriver(String id) async {
    await _api.suspendDriver(id);
    await _invalidateDriverCaches(id);
  }

  @override
  Future<void> activateDriver(String id) async {
    await _api.activateDriver(id);
    await _invalidateDriverCaches(id);
  }

  @override
  Future<void> setDriverStatus(String id, bool isOnline) async {
    await _api.setDriverStatus(id, SetDriverStatusRequest(isOnline: isOnline));
    await _invalidateDriverCaches(id);
  }
}

class ApiTripRepository implements TripRepository {
  final TripApiService _api;
  final CacheService _cache;

  ApiTripRepository(this._api, this._cache);

  @override
  Future<List<Trip>> getAllTrips() async {
    final cached = _cache.get(CacheService.tripsAll);
    if (cached != null) {
      return (cached as List).map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
    }
    final trips = await _api.getAllTrips();
    await _cache.setList(CacheService.tripsAll, trips.map((t) => t.toJson()).toList());
    return trips;
  }

  @override
  Future<Trip?> getTripById(String id) async {
    final cached = _cache.get(CacheService.trip(id));
    if (cached != null) {
      return Trip.fromJson(cached as Map<String, dynamic>);
    }
    final trip = await _api.getTrip(id);
    await _cache.setSingle(CacheService.trip(id), trip.toJson());
    return trip;
  }

  @override
  Future<List<Trip>> getTripsByCustomer(String customerId) async {
    final cached = _cache.get(CacheService.tripsCustomer(customerId));
    if (cached != null) {
      return (cached as List).map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
    }
    final trips = await _api.getTripsByCustomer(customerId);
    await _cache.setList(CacheService.tripsCustomer(customerId), trips.map((t) => t.toJson()).toList());
    return trips;
  }

  @override
  Future<List<Trip>> getTripsByDriver(String driverId) async {
    final cached = _cache.get(CacheService.tripsDriver(driverId));
    if (cached != null) {
      return (cached as List).map((e) => Trip.fromJson(e as Map<String, dynamic>)).toList();
    }
    final trips = await _api.getTripsByDriver(driverId);
    await _cache.setList(CacheService.tripsDriver(driverId), trips.map((t) => t.toJson()).toList());
    return trips;
  }

  @override
  Future<List<Trip>> getActiveTripsByDriver(String driverId) async {
    return _api.getActiveTripsByDriver(driverId);
  }

  @override
  Future<Trip> assignDriver(String tripId, String driverId, String vehicleId) async {
    final trip = await _api.assignDriver(
      tripId,
      AssignDriverRequest(driverId: driverId, vehicleId: vehicleId),
    );
    await _cache.remove(CacheService.tripsAll);
    await _cache.remove(CacheService.trip(tripId));
    return trip;
  }

  @override
  Future<Trip> cancelTrip(String tripId, {String? reason}) async {
    final trip = await _api.cancelTrip(tripId, CancelTripRequest(reason: reason));
    await _cache.remove(CacheService.tripsAll);
    await _cache.remove(CacheService.trip(tripId));
    return trip;
  }

  // Route breadcrumbs and recommendations are live data — not cached.
  @override
  Future<List<RoutePoint>> getTripRoute(String tripId) {
    return _api.getTripRoute(tripId);
  }

  @override
  Future<List<RecommendedDriver>> getRecommendedDrivers(String tripId, {int count = 5}) {
    return _api.getRecommendedDrivers(tripId, count: count);
  }
}

class ApiVehicleRepository implements VehicleRepository {
  final VehicleApiService _api;
  final CacheService _cache;

  ApiVehicleRepository(this._api, this._cache);

  @override
  Future<List<Vehicle>> getAllVehicles() async {
    final cached = _cache.get(CacheService.vehiclesAll);
    if (cached != null) {
      return (cached as List).map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
    }
    final vehicles = await _api.getAllVehicles();
    await _cache.setList(CacheService.vehiclesAll, vehicles.map((v) => v.toJson()).toList());
    return vehicles;
  }

  @override
  Future<List<Vehicle>> getAvailableVehicles() async {
    final cached = _cache.get(CacheService.vehiclesAvailable);
    if (cached != null) {
      return (cached as List).map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
    }
    final vehicles = await _api.getAvailableVehicles();
    await _cache.setList(CacheService.vehiclesAvailable, vehicles.map((v) => v.toJson()).toList());
    return vehicles;
  }

  @override
  Future<Vehicle?> getVehicleById(String id) async {
    final cached = _cache.get(CacheService.vehicle(id));
    if (cached != null) {
      return Vehicle.fromJson(cached as Map<String, dynamic>);
    }
    final vehicle = await _api.getVehicle(id);
    await _cache.setSingle(CacheService.vehicle(id), vehicle.toJson());
    return vehicle;
  }

  @override
  Future<List<Vehicle>> getVehiclesNeedingService() async {
    final cached = _cache.get(CacheService.vehiclesNeedingService);
    if (cached != null) {
      return (cached as List).map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
    }
    final vehicles = await _api.getAllVehicles();
    final now = DateTime.now();
    final thirtyDaysFromNow = now.add(const Duration(days: 30));
    final needingService = vehicles.where((v) {
      if (v.status == VehicleStatus.maintenance) return true;
      if (v.insuranceExpiryDate.isBefore(thirtyDaysFromNow)) return true;
      if (v.registrationExpiryDate.isBefore(thirtyDaysFromNow)) return true;
      return false;
    }).toList();
    await _cache.setList(CacheService.vehiclesNeedingService, needingService.map((v) => v.toJson()).toList());
    return needingService;
  }

  @override
  Future<Vehicle> assignVehicle(String vehicleId, String driverId) async {
    final vehicle = await _api.assignVehicle(vehicleId, AssignVehicleRequest(driverId: driverId));
    await _cache.remove(CacheService.vehiclesAll);
    await _cache.remove(CacheService.vehiclesAvailable);
    await _cache.remove(CacheService.vehicle(vehicleId));
    await _cache.remove(CacheService.vehiclesNeedingService);
    return vehicle;
  }

  @override
  Future<void> unassignVehicle(String vehicleId) async {
    await _api.unassignVehicle(vehicleId);
    await _cache.remove(CacheService.vehiclesAll);
    await _cache.remove(CacheService.vehiclesAvailable);
    await _cache.remove(CacheService.vehicle(vehicleId));
    await _cache.remove(CacheService.vehiclesNeedingService);
  }
}
