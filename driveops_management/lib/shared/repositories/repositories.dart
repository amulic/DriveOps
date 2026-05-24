import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/models/user.dart';
import 'package:driveops_management/shared/dtos/requests/driver_requests.dart';
import 'package:driveops_management/shared/dtos/requests/user_requests.dart';

abstract class DriverRepository {
  Future<List<Driver>> getAllDrivers();
  Future<List<Driver>> getActiveDrivers();
  Future<List<Driver>> getAvailableDrivers();
  Future<Driver?> getDriverById(String id);
  Future<List<Driver>> getNearbyDrivers(double latitude, double longitude, double radiusKm);
  Future<Driver> createDriver(CreateDriverRequest request);
  Future<Driver> updateDriver(String id, UpdateDriverRequest request);
  Future<void> suspendDriver(String id);
  Future<void> activateDriver(String id);
  Future<void> setDriverStatus(String id, bool isOnline);
}

abstract class TripRepository {
  Future<List<Trip>> getAllTrips();
  Future<Trip?> getTripById(String id);
  Future<List<Trip>> getTripsByCustomer(String customerId);
  Future<List<Trip>> getTripsByDriver(String driverId);
  Future<List<Trip>> getActiveTripsByDriver(String driverId);
}

abstract class VehicleRepository {
  Future<List<Vehicle>> getAllVehicles();
  Future<List<Vehicle>> getAvailableVehicles();
  Future<Vehicle?> getVehicleById(String id);
  Future<List<Vehicle>> getVehiclesNeedingService();
  Future<Vehicle> assignVehicle(String vehicleId, String driverId);
  Future<void> unassignVehicle(String vehicleId);
}

abstract class UserRepository {
  Future<User?> getCurrentUser();
  Future<User?> getUserById(String id);
  Future<User> createUser(CreateUserRequest request);
}