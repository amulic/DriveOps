import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/shared/models/customer.dart';
import 'package:driveops_mobile/shared/models/driver.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'package:driveops_mobile/shared/models/vehicle.dart';
import 'package:driveops_mobile/shared/models/defect_report.dart';
import 'package:driveops_mobile/shared/repositories/repositories.dart';
import 'package:driveops_mobile/shared/repositories/api_repositories.dart';
import 'package:driveops_mobile/services/cache_service.dart';
import 'package:driveops_mobile/services/customer_api_service.dart';
import 'package:driveops_mobile/services/driver_api_service.dart';
import 'package:driveops_mobile/services/trip_api_service.dart';
import 'package:driveops_mobile/services/vehicle_api_service.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';

final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});

final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return ApiDriverRepository(
    ref.watch(driverApiServiceProvider),
    cache,
  );
});

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return ApiTripRepository(
    ref.watch(tripApiServiceProvider),
    cache,
  );
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return ApiVehicleRepository(
    ref.watch(vehicleApiServiceProvider),
    cache,
  );
});

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return ApiCustomerRepository(ref.watch(customerApiServiceProvider));
});

/// Resolves the domain [Driver] record for the logged-in user via their
/// Keycloak sub. This doubles as the driver-role probe when the JWT carries
/// no explicit driver role (older sessions).
final currentDriverProvider = FutureProvider<Driver?>((ref) async {
  final sub = ref.watch(keycloakSubProvider);
  if (sub == null) return null;
  final repo = ref.watch(driverRepositoryProvider);
  return repo.getDriverByKeycloakId(sub);
});

/// Resolves the domain [Customer] record for the logged-in user.
final currentCustomerProvider = FutureProvider<Customer?>((ref) async {
  final sub = ref.watch(keycloakSubProvider);
  if (sub == null) return null;
  final repo = ref.watch(customerRepositoryProvider);
  return repo.getCustomerByKeycloakId(sub);
});

/// All trips for the logged-in driver (trip history source).
final driverTripsProvider = FutureProvider<List<Trip>>((ref) async {
  final driverAsync = ref.watch(currentDriverProvider);
  final driver = driverAsync.value;
  if (driver == null) return [];
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getTripsByDriver(driver.id);
});

/// The vehicle currently assigned to the logged-in driver.
final driverVehicleProvider = FutureProvider<Vehicle?>((ref) async {
  final driverAsync = ref.watch(currentDriverProvider);
  final driver = driverAsync.value;
  if (driver == null) return null;
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getVehicleByDriverId(driver.id);
});

/// Defect reports for a vehicle (driver Vehicle tab "My reports" section).
/// autoDispose so it refetches on every tab visit — reports are resolved
/// out-of-band from the management app.
final vehicleDefectsProvider =
    FutureProvider.autoDispose.family<List<DefectReport>, String>((ref, vehicleId) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getVehicleDefects(vehicleId);
});
