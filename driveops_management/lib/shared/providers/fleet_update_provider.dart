import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/signalr_service.dart';
import 'package:driveops_management/services/auth_service.dart';
import 'package:driveops_management/shared/providers/auth_provider.dart';
import 'package:driveops_management/features/drivers/presentation/providers/drivers_providers.dart';
import 'package:driveops_management/features/vehicles/presentation/providers/vehicles_providers.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';

final signalrServiceProvider = Provider<SignalrService>((ref) {
  final service = SignalrService();
  ref.onDispose(() {
    service.disconnect();
    service.dispose();
  });
  return service;
});

final fleetUpdateConnectionProvider = Provider<void>((ref) {
  final signalr = ref.watch(signalrServiceProvider);
  final authState = ref.watch(authProvider);

  if (authState.value?.isAuthenticated == true) {
    final authService = AuthService();
    authService.getAccessToken().then((t) {
      if (t != null) {
        signalr.connect(t).catchError((e) {
          if (kDebugMode) {
            print('[SignalR] Fleet connection failed: $e');
          }
        });
      }
    });
  } else {
    signalr.disconnect();
  }

  return;
});

final fleetUpdateListenerProvider = Provider<void>((ref) {
  final signalr = ref.watch(signalrServiceProvider);

  signalr.on('FleetUpdate', (args) {
    if (args == null || args.isEmpty) return;
    try {
      final dto = args.first as Map<String, dynamic>;
      final updateType = dto['updateType'] as String?;

      switch (updateType) {
        case 'VehicleAssigned':
        case 'VehicleUnassigned':
        case 'VehicleStatusChanged':
          ref.invalidate(vehiclesAsyncProvider);
          ref.invalidate(filteredVehiclesProvider);
          ref.invalidate(allVehiclesProvider);
          ref.invalidate(vehiclesNeedingServiceProvider);
          break;

        case 'DriverStatusChanged':
          ref.invalidate(driversAsyncProvider);
          ref.invalidate(filteredDriversProvider);
          ref.invalidate(allDriversProvider);
          // Keep the messagable/assignable lists in sync when a driver is
          // approved, suspended or toggles online from another client.
          ref.invalidate(activeDriversProvider);
          break;
      }
    } catch (_) {
      // Ignore malformed fleet updates
    }
  });

  return;
});
