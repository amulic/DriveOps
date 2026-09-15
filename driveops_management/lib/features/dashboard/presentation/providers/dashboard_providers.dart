import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';

final driversProvider = FutureProvider<DriversData>((ref) async {
  final allDrivers = await ref.watch(allDriversProvider.future);
  final active = allDrivers.where((d) => d.status == DriverStatus.active).toList();
  return DriversData(total: allDrivers.length, active: active, all: allDrivers);
});

final vehiclesProvider = FutureProvider<VehiclesData>((ref) async {
  final allVehicles = await ref.watch(allVehiclesProvider.future);
  final needingService = await ref.watch(vehiclesNeedingServiceProvider.future);
  return VehiclesData(total: allVehicles.length, needingService: needingService);
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
