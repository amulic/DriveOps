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
      if (t != null) signalr.connect(t);
    });
  } else {
    signalr.disconnect();
  }
});
