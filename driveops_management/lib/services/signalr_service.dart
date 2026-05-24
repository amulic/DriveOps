import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:driveops_management/config/api_config.dart';

class SignalrService {
  HubConnection? _connection;
  final _handlers = <String, List<void Function(List<dynamic>?)>>{};
  final _connectionStateController = StreamController<HubConnectionState>.broadcast();

  Stream<HubConnectionState> get connectionState => _connectionStateController.stream;

  Future<void> connect(String accessToken) async {
    if (_connection?.state == HubConnectionState.Connected) {
      return;
    }

    final url = '${ApiConfig.realtimeBaseUrl}${ApiConfig.notificationHubPath}';

    _connection = HubConnectionBuilder()
        .withUrl(
          url,
          options: HttpConnectionOptions(
            accessTokenFactory: () async => accessToken,
            transport: HttpTransportType.WebSockets,
            skipNegotiation: false,
          ),
        )
        .withAutomaticReconnect()
        .build();

    // Re-register all existing handlers
    for (final entry in _handlers.entries) {
      for (final callback in entry.value) {
        _connection!.on(entry.key, callback);
      }
    }

    _connection!.onclose(({error}) {
      _connectionStateController.add(HubConnectionState.Disconnected);
    });

    _connection!.onreconnecting(({error}) {
      _connectionStateController.add(HubConnectionState.Reconnecting);
    });

    _connection!.onreconnected(({connectionId}) {
      _connectionStateController.add(HubConnectionState.Connected);
    });

    await _connection!.start();
    _connectionStateController.add(HubConnectionState.Connected);

    // Join admin dashboard group
    try {
      await _connection!.invoke('JoinAdminDashboard');
    } catch (e) {
      if (kDebugMode) {
        print('[SignalR] Failed to join admin dashboard: $e');
      }
    }
  }

  Future<void> disconnect() async {
    if (_connection?.state == HubConnectionState.Connected) {
      try {
        await _connection!.invoke('LeaveAdminDashboard');
      } catch (_) {
        // Ignore errors during disconnect
      }
    }
    await _connection?.stop();
    _connection = null;
  }

  void on(String method, void Function(List<dynamic>?) callback) {
    _handlers.putIfAbsent(method, () => []);
    _handlers[method]!.add(callback);

    _connection?.on(method, callback);
  }

  void off(String method) {
    _handlers.remove(method);
    _connection?.off(method);
  }

  void dispose() {
    _connectionStateController.close();
  }
}
