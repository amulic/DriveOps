import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/trip.dart';
import '../../../../shared/models/driver.dart';
import '../../../../shared/providers/repository_providers.dart';

final tripsAsyncProvider = FutureProvider<List<Trip>>((ref) async {
  final repo = ref.watch(tripRepositoryProvider);
  return repo.getAllTrips();
});

final tripsDriversAsyncProvider = FutureProvider<List<Driver>>((ref) async {
  final repo = ref.watch(driverRepositoryProvider);
  return repo.getAllDrivers();
});

final driversMapProvider = Provider<AsyncValue<Map<String, Driver>>>((ref) {
  final driversAsync = ref.watch(tripsDriversAsyncProvider);
  return driversAsync.when(
    data: (drivers) => AsyncValue.data({for (final d in drivers) d.id: d}),
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

final ridesSearchQueryProvider = StateProvider<String>((ref) => '');
final ridesStatusFilterProvider = StateProvider<TripStatus?>((ref) => null);

final filteredTripsProvider = Provider<AsyncValue<List<Trip>>>((ref) {
  final tripsAsync = ref.watch(tripsAsyncProvider);
  final query = ref.watch(ridesSearchQueryProvider).toLowerCase();
  final statusFilter = ref.watch(ridesStatusFilterProvider);

  return tripsAsync.when(
    data: (trips) {
      var result = trips;

      if (statusFilter != null) {
        result = result.where((t) => t.tripStatus == statusFilter).toList();
      }

      if (query.isNotEmpty) {
        result = result.where((t) {
          return t.pickupAddress.toLowerCase().contains(query) ||
              t.dropoffAddress.toLowerCase().contains(query) ||
              (t.driverName?.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      return AsyncValue.data(result);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});