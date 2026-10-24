import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/shared/models/trip.dart';
import 'package:driveops_mobile/shared/providers/notification_signalr_provider.dart';
import 'package:driveops_mobile/shared/providers/repository_providers.dart';

/// Optimistic online/offline toggle for the driver home "Active" slider.
/// PATCHes the API, then refreshes the cached driver profile.
class DriverOnlineNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final driver = await ref.watch(currentDriverProvider.future);
    return driver?.isOnline ?? false;
  }

  Future<void> setOnline(bool online) async {
    final driver = ref.read(currentDriverProvider).value;
    if (driver == null) return;

    final previous = state.value ?? false;
    state = AsyncValue.data(online); // optimistic

    try {
      final repo = ref.read(driverRepositoryProvider);
      await repo.setDriverStatus(driver.id, online);
      ref.invalidate(currentDriverProvider);

      final signalr = ref.read(notificationSignalrServiceProvider);
      if (online) {
        await signalr.joinAvailableDrivers(driver.id);
      } else {
        await signalr.leaveAvailableDrivers(driver.id);
      }
    } catch (_) {
      state = AsyncValue.data(previous); // revert on failure
      rethrow;
    }
  }
}

final driverOnlineProvider =
    AsyncNotifierProvider<DriverOnlineNotifier, bool>(DriverOnlineNotifier.new);

/// Pie-chart data: per-status counts over the driver's trips.
class DriverTripStats {
  final int completed;
  final int cancelled;
  final int declined;

  const DriverTripStats({
    required this.completed,
    required this.cancelled,
    required this.declined,
  });

  int get total => completed + cancelled + declined;
}

final driverTripStatsProvider = FutureProvider<DriverTripStats>((ref) async {
  final trips = await ref.watch(driverTripsProvider.future);
  return DriverTripStats(
    completed: trips.where((t) => t.tripStatus == TripStatus.completed).length,
    cancelled: trips.where((t) => t.tripStatus == TripStatus.cancelled).length,
    declined: trips.where((t) => t.tripStatus == TripStatus.declined).length,
  );
});
