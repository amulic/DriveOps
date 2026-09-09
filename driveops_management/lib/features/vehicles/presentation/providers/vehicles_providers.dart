import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/vehicle.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';

final vehiclesAsyncProvider = FutureProvider<List<Vehicle>>((ref) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getAllVehicles();
});

class VehiclesSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

class VehiclesStatusFilterNotifier extends Notifier<VehicleStatus?> {
  @override
  VehicleStatus? build() => null;

  void update(VehicleStatus? value) => state = value;
}

class VehiclesShowNeedsServiceNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void update(bool value) => state = value;
}

final vehiclesSearchQueryProvider = NotifierProvider<VehiclesSearchQueryNotifier, String>(VehiclesSearchQueryNotifier.new);
final vehiclesStatusFilterProvider = NotifierProvider<VehiclesStatusFilterNotifier, VehicleStatus?>(VehiclesStatusFilterNotifier.new);
final vehiclesShowNeedsServiceProvider = NotifierProvider<VehiclesShowNeedsServiceNotifier, bool>(VehiclesShowNeedsServiceNotifier.new);

bool _needsService(Vehicle v) {
  if (v.status == VehicleStatus.maintenance) return true;
  final now = DateTime.now();
  final thirtyDays = now.add(const Duration(days: 30));
  if (v.insuranceExpiryDate.isBefore(thirtyDays)) return true;
  if (v.registrationExpiryDate.isBefore(thirtyDays)) return true;
  return false;
}

final filteredVehiclesProvider = Provider<AsyncValue<List<Vehicle>>>((ref) {
  final vehiclesAsync = ref.watch(vehiclesAsyncProvider);
  final query = ref.watch(vehiclesSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(vehiclesStatusFilterProvider);
  final needsService = ref.watch(vehiclesShowNeedsServiceProvider);

  return vehiclesAsync.when(
    data: (vehicles) {
      var result = vehicles;

      if (needsService) {
        result = result.where(_needsService).toList();
      }

      if (statusFilter != null) {
        result = result.where((v) => v.status == statusFilter).toList();
      }

      if (query.isNotEmpty) {
        result = result.where((v) {
          final search = '${v.make} ${v.model} ${v.licensePlate} ${v.color} ${v.vin}';
          return search.toLowerCase().contains(query);
        }).toList();
      }

      return AsyncValue.data(result);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});