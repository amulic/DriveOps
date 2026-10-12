import 'package:driveops_mobile/shared/models/driver.dart';
import 'package:driveops_mobile/shared/models/customer.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'package:driveops_mobile/shared/models/vehicle.dart';
import 'package:driveops_mobile/shared/models/route_point.dart';
import 'package:driveops_mobile/shared/models/recommended_driver.dart';
import 'package:driveops_mobile/shared/dtos/requests/driver_requests.dart';
import 'package:driveops_mobile/shared/dtos/requests/vehicle_requests.dart';
import 'package:driveops_mobile/shared/dtos/requests/customer_requests.dart';
import 'package:driveops_mobile/shared/dtos/requests/trip_requests.dart';

abstract class DriverRepository {
  Future<List<Driver>> getAllDrivers();
  Future<List<Driver>> getActiveDrivers();
  Future<List<Driver>> getAvailableDrivers();
  Future<Driver?> getDriverById(String id);
  Future<Driver?> getDriverByKeycloakId(String keycloakId);
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
  Future<Trip> assignDriver(String tripId, String driverId, String vehicleId);
  Future<Trip> startTrip(String tripId);
  Future<Trip> completeTrip(String tripId, double actualDistanceKm);
  Future<Trip> cancelTrip(String tripId, {String? reason});
  Future<Trip> declineTrip(String tripId, String driverId, {String? reason});

  /// A→B route estimate (distance/duration/fare + polyline points) without
  /// creating a trip — used by the driver map to draw the current leg.
  Future<TripEstimateResponse> estimateTrip(TripEstimateRequest request);
  Future<List<RoutePoint>> getTripRoute(String tripId);
  Future<List<RecommendedDriver>> getRecommendedDrivers(String tripId, {int count = 5});
}

abstract class VehicleRepository {
  Future<List<Vehicle>> getAllVehicles();
  Future<List<Vehicle>> getAvailableVehicles();
  Future<Vehicle?> getVehicleById(String id);
  Future<Vehicle?> getVehicleByDriverId(String driverId);
  Future<List<Vehicle>> getVehiclesNeedingService();
  Future<Vehicle> assignVehicle(String vehicleId, String driverId);
  Future<void> unassignVehicle(String vehicleId);
  Future<void> reportDefect(String vehicleId, ReportVehicleDefectRequest request);
}

abstract class CustomerRepository {
  Future<Customer?> getCustomerByKeycloakId(String keycloakId);
  Future<Customer> createCustomer(CreateCustomerRequest request);
}
