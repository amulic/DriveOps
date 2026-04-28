import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/dashboard_repository.dart';
import '../../../../shared/models/driver.dart';
import '../../../../shared/models/trip.dart';
import '../../../../shared/models/vehicle.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository();
});

final driversProvider = Provider<DriversData>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return DriversData(
    total: repo.getDrivers().length,
    active: repo.getActiveDrivers(),
    all: repo.getDrivers(),
  );
});

final vehiclesProvider = Provider<VehiclesData>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return VehiclesData(
    total: repo.getVehicles().length,
    needingService: repo.getVehiclesNeedingService(),
  );
});

final tripsProvider = Provider<TripsData>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return TripsData(
    recent: repo.getRecentTrips(),
    statistics: repo.getTripStatistics(),
  );
});

final revenueProvider = Provider<double>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getTotalRevenue();
});

final driverScoreboardProvider = Provider<List<Driver>>((ref) {
  final repo = ref.watch(dashboardRepositoryProvider);
  return repo.getDriverScoreboard();
});

class DriversData {
  final int total;
  final List<Driver> active;
  final List<Driver> all;

  DriversData({
    required this.total,
    required this.active,
    required this.all,
  });
}

class VehiclesData {
  final int total;
  final List<Vehicle> needingService;

  VehiclesData({
    required this.total,
    required this.needingService,
  });
}

class TripsData {
  final List<Trip> recent;
  final Map<String, int> statistics;

  TripsData({
    required this.recent,
    required this.statistics,
  });
}
