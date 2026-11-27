import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/signalr_service.dart';
import 'package:driveops_management/services/auth_service.dart';
import 'package:driveops_management/shared/providers/auth_provider.dart';
import 'package:driveops_management/features/drivers/presentation/providers/drivers_providers.dart';
import 'package:driveops_management/features/vehicles/presentation/providers/vehicles_providers.dart';
import 'package:driveops_management/features/defects/presentation/providers/defects_providers.dart';
import 'package:driveops_management/shared/providers/repository_providers.dart';
import 'package:driveops_management/config/messenger.dart';

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
          ref.invalidate(vehicleServiceRemindersProvider);
          break;

        case 'DriverStatusChanged':
          ref.invalidate(driversAsyncProvider);
          ref.invalidate(filteredDriversProvider);
          ref.invalidate(allDriversProvider);
          // Keep the messagable/assignable lists in sync when a driver is
          // approved, suspended or toggles online from another client.
          ref.invalidate(activeDriversProvider);
          break;

        case 'VehicleDefectReported':
        case 'VehicleDefectResolved':
        case 'VehicleDefectReopened':
          // Keep the Defects screen, vehicle detail defects section, Vehicles
          // table badges and the sidebar badge in sync across clients.
          ref.invalidate(defectsProvider);
          ref.invalidate(vehicleDefectsProvider);
          ref.invalidate(openDefectCountsProvider);
          break;

        case 'VehicleServiceRecorded':
          ref.invalidate(vehiclesAsyncProvider);
          ref.invalidate(filteredVehiclesProvider);
          ref.invalidate(allVehiclesProvider);
          ref.invalidate(vehiclesNeedingServiceProvider);
          ref.invalidate(vehicleServiceRemindersProvider);
          break;

        case 'VehicleServiceDue':
        case 'VehicleInspectionDue':
          ref.invalidate(vehiclesAsyncProvider);
          ref.invalidate(filteredVehiclesProvider);
          ref.invalidate(allVehiclesProvider);
          ref.invalidate(vehiclesNeedingServiceProvider);
          ref.invalidate(vehicleServiceRemindersProvider);
          _showReminder(dto, isInspection: updateType == 'VehicleInspectionDue');
          break;
      }
    } catch (_) {
      // Ignore malformed fleet updates
    }
  });

  return;
});

void _showReminder(Map<String, dynamic> dto, {required bool isInspection}) {
  String plate = '';
  String reason = isInspection
      ? 'A vehicle requires an inspection.'
      : 'A vehicle requires service.';

  final payload = dto['payloadJson'];
  if (payload is String && payload.isNotEmpty) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        plate = decoded['licensePlate'] as String? ?? '';
        reason = decoded['reason'] as String? ?? reason;
      }
    } catch (_) {
      // Keep the generic reason when the payload cannot be parsed.
    }
  }

  final messenger = scaffoldMessengerKey.currentState;
  if (messenger == null) return;

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        plate.isEmpty ? reason : '$plate: $reason',
      ),
      backgroundColor:
          isInspection ? const Color(0xFFF59E0B) : const Color(0xFF3B82F6),
      duration: const Duration(seconds: 5),
    ),
  );
}
