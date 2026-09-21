import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/chat_signalr_service.dart';
import 'package:driveops_management/services/auth_service.dart';
import 'package:driveops_management/shared/providers/auth_provider.dart';

final chatSignalrServiceProvider = Provider<ChatSignalrService>((ref) {
  final service = ChatSignalrService();
  ref.onDispose(() {
    service.disconnect();
    service.dispose();
  });
  return service;
});

final chatSignalrConnectionProvider = Provider<void>((ref) {
  final chatSignalr = ref.watch(chatSignalrServiceProvider);
  final authState = ref.watch(authProvider);

  if (authState.value?.isAuthenticated == true) {
    final authService = AuthService();
    authService.getAccessToken().then((t) {
      if (t != null) {
        chatSignalr.connect(t).catchError((e) {
          if (kDebugMode) {
            print('[ChatSignalR] Connection failed: $e');
          }
        });
      }
    });
  } else {
    chatSignalr.disconnect();
  }
});