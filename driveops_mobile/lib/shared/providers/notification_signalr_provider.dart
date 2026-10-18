import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/services/auth_service.dart';
import 'package:driveops_mobile/services/signalr_service.dart';
import 'package:driveops_mobile/shared/providers/auth_provider.dart';

final notificationSignalrServiceProvider = Provider<SignalrService>((ref) {
  final service = SignalrService();
  ref.onDispose(() {
    service.disconnect();
    service.dispose();
  });
  return service;
});

/// Connects the notification hub while the user is authenticated.
final notificationSignalrConnectionProvider = Provider<void>((ref) {
  final signalr = ref.watch(notificationSignalrServiceProvider);
  final authState = ref.watch(authProvider);

  if (authState.value?.isAuthenticated == true) {
    AuthService().getAccessToken().then((t) {
      if (t != null) signalr.connect(t);
    });
  } else {
    signalr.disconnect();
  }
});
