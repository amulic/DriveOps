import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/models/user.dart';
import 'package:driveops_management/services/driver_api_service.dart';
import 'package:driveops_management/services/trip_api_service.dart';
import 'package:driveops_management/services/vehicle_api_service.dart';
import 'package:driveops_management/services/user_api_service.dart';
import 'package:driveops_management/services/cache_service.dart';
import 'package:driveops_management/shared/repositories/repositories.dart';
import 'package:driveops_management/shared/dtos/requests/driver_requests.dart';
import 'package:driveops_management/shared/dtos/requests/user_requests.dart';
import 'package:driveops_management/shared/dtos/requests/vehicle_requests.dart';

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
  Future<List<Driver>> getNearbyDrivers(
      double latitude, double longitude, double radiusKm) async {
    return _api.getNearbyDrivers(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
    );
  }

  @override
  Future<Driver> createDriver(CreateDriverRequest request) async {
    final driver = await _api.createDriver(request);
    await _cache.remove(CacheService.driversAll);
    return driver;
  }

  @override
  Future<Driver> updateDriver(String id, UpdateDriverRequest request) async {
    final driver = await _api.updateDriver(id, request);
    await _cache.remove(CacheService.driversAll);
    await _cache.remove(CacheService.driver(id));
    return driver;
  }

  @override
  Future<void> suspendDriver(String id) async {
    await _api.suspendDriver(id);
    await _cache.remove(CacheService.driversAll);
    await _cache.remove(CacheService.driver(id));
  }

  @override
  Future<void> activateDriver(String id) async {
    await _api.activateDriver(id);
    await _cache.remove(CacheService.driversAll);
    await _cache.remove(CacheService.driver(id));
  }

  @override
  Future<void> setDriverStatus(String id, bool isOnline) async {
    await _api.setDriverStatus(id, SetDriverStatusRequest(isOnline: isOnline));
    await _cache.remove(CacheService.driversAll);
    await _cache.remove(CacheService.driver(id));
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

class ApiUserRepository implements UserRepository {
  final UserApiService _api;
  final CacheService _cache;

  ApiUserRepository(this._api, this._cache);

  @override
  Future<User?> getCurrentUser() async {
    final cached = _cache.get(CacheService.userCurrent);
    if (cached != null) {
      return User.fromJson(cached as Map<String, dynamic>);
    }
    final user = await _api.getCurrentUser();
    await _cache.setSingle(CacheService.userCurrent, user.toJson());
    return user;
  }

  @override
  Future<User?> getUserById(String id) async {
    final cached = _cache.get(CacheService.user(id));
    if (cached != null) {
      return User.fromJson(cached as Map<String, dynamic>);
    }
    final user = await _api.getUser(id);
    await _cache.setSingle(CacheService.user(id), user.toJson());
    return user;
  }

  @override
  Future<User> createUser(CreateUserRequest request) async {
    final user = await _api.createUser(request);
    return user;
  }
}