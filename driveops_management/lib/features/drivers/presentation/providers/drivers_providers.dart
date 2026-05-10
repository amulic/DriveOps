import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/driver.dart';
import '../../../../shared/providers/repository_providers.dart';

final driversAsyncProvider = FutureProvider<List<Driver>>((ref) async {
  final repo = ref.watch(driverRepositoryProvider);
  return repo.getAllDrivers();
});

final driversSearchQueryProvider = StateProvider<String>((ref) => '');
final driversShowActiveOnlyProvider = StateProvider<bool>((ref) => false);

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