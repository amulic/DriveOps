import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/models/route_point.dart';
import 'package:driveops_management/shared/models/recommended_driver.dart';
import 'package:driveops_management/shared/models/keycloak_candidate.dart';
import 'package:driveops_management/shared/models/defect_report.dart';
import 'package:driveops_management/shared/dtos/requests/driver_requests.dart';

abstract class DriverRepository {
  Future<List<Driver>> getAllDrivers();
  Future<List<Driver>> getActiveDrivers();
  Future<List<Driver>> getAvailableDrivers();
  Future<Driver?> getDriverById(String id);
  Future<Driver?> getDriverByKeycloakId(String keycloakId);
  Future<List<Driver>> getNearbyDrivers(double latitude, double longitude, double radiusKm);
  Future<Driver> createDriver(CreateDriverRequest request);
  Future<List<KeycloakCandidate>> getPromotionCandidates(String search);
  Future<Driver> promoteDriver(CreateDriverRequest request);
  Future<Driver> onboardDriver(OnboardDriverRequest request);
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
  Future<Trip> cancelTrip(String tripId, {String? reason});
  Future<List<RoutePoint>> getTripRoute(String tripId);
  Future<List<RecommendedDriver>> getRecommendedDrivers(String tripId, {int count = 5});
}

abstract class VehicleRepository {
  Future<List<Vehicle>> getAllVehicles();
  Future<List<Vehicle>> getAvailableVehicles();
  Future<Vehicle?> getVehicleById(String id);
  Future<List<Vehicle>> getVehiclesNeedingService();
  Future<Vehicle> assignVehicle(String vehicleId, String driverId);
  Future<void> unassignVehicle(String vehicleId);
}

abstract class DefectRepository {
  Future<List<DefectReport>> getDefects({
    String? status,
    DefectSeverity? severity,
    String? vehicleId,
    String? driverId,
  });
  Future<List<DefectReport>> getVehicleDefects(String vehicleId);
  Future<DefectReport> resolveDefect(String id, {String? resolutionNotes});
  Future<DefectReport> reopenDefect(String id);
}
