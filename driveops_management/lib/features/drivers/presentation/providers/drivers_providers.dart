import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/shared/models/driver.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';

final driversAsyncProvider = FutureProvider<List<Driver>>((ref) async {
  final repo = ref.watch(driverRepositoryProvider);
  return repo.getAllDrivers();
});

class DriversSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void update(String value) => state = value;
}

class DriversShowActiveOnlyNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void update(bool value) => state = value;
}

final driversSearchQueryProvider = NotifierProvider<DriversSearchQueryNotifier, String>(DriversSearchQueryNotifier.new);
final driversShowActiveOnlyProvider = NotifierProvider<DriversShowActiveOnlyNotifier, bool>(DriversShowActiveOnlyNotifier.new);

final filteredDriversProvider = Provider<AsyncValue<List<Driver>>>((ref) {
  final driversAsync = ref.watch(driversAsyncProvider);
  final query = ref.watch(driversSearchQueryProvider).toLowerCase();
  final activeOnly = ref.watch(driversShowActiveOnlyProvider);

  return driversAsync.when(
    data: (drivers) {
      var result = drivers;

      if (activeOnly) {
        result = result.where((d) => d.status == DriverStatus.active).toList();
      }

      if (query.isNotEmpty) {
        result = result.where((d) => d.driverName.toLowerCase().contains(query)).toList();
      }

      return AsyncValue.data(result);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});