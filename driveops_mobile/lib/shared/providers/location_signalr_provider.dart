import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/services/auth_service.dart';
import 'package:driveops_mobile/services/location_signalr_service.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';

final locationSignalrServiceProvider = Provider<LocationSignalrService>((ref) {
  final service = LocationSignalrService();
  ref.onDispose(() {
    service.disconnect();
    service.dispose();
  });
  return service;
});

/// Connects the location hub while the user is authenticated.
final locationSignalrConnectionProvider = Provider<void>((ref) {
  final signalr = ref.watch(locationSignalrServiceProvider);
  final authState = ref.watch(authProvider);

  if (authState.value?.isAuthenticated == true) {
    AuthService().getAccessToken().then((t) {
      if (t != null) {
        // Error-safe: a failed hub connect must never surface as an
        // unhandled exception (SignalR reconnects on its own schedule).
        unawaited(signalr.connect(t).catchError((Object e) {
          debugPrint('[SignalR] Location hub connect failed: $e');
        }));
      }
    });
  } else {
    signalr.disconnect();
  }
});
