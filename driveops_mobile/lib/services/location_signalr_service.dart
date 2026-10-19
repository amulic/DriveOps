import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:latlong2/latlong.dart';
import 'package:driveops_mobile/config/api_config.dart';

/// Client for the realtime LocationHub (`/hubs/location`).
///
/// Used by the driver to stream GPS fixes (`SendDriverLocation`) and by both
/// roles to subscribe to live trip tracking (`SubscribeToTripLocation` →
/// `ReceiveDriverLocation` / `ReceiveTripRoute` callbacks).
class LocationSignalrService {
  HubConnection? _connection;
  final _handlers = <String, List<void Function(List<dynamic>?)>>{};
  final _connectionStateController = StreamController<HubConnectionState>.broadcast();
  final _reconnectedController = StreamController<void>.broadcast();

  /// Trip-location groups joined on the current connection. Server-side group
  /// membership is per-connection, so it must be re-established on reconnect.
  final _subscribedTrips = <String>{};

  Stream<HubConnectionState> get connectionState => _connectionStateController.stream;

  /// Fires after a successful automatic reconnect (not on the initial connect).
  Stream<void> get onReconnected => _reconnectedController.stream;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> connect(String accessToken) async {
    if (_connection?.state == HubConnectionState.Connected) {
      return;
    }

    final url = '${ApiConfig.realtimeBaseUrl}${ApiConfig.locationHubPath}';

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

    _connection!.onreconnected(({connectionId}) async {
      _connectionStateController.add(HubConnectionState.Connected);
      for (final tripId in _subscribedTrips.toList()) {
        try {
          await _connection?.invoke('SubscribeToTripLocation', args: [tripId]);
        } catch (_) {
          // Best-effort; the next app-driven refetch restores state.
        }
      }
      _reconnectedController.add(null);
    });

    await _connection!.start();
    _connectionStateController.add(HubConnectionState.Connected);
    // Trips subscribed before the connection finished joining get their
    // groups now (invoke on a starting connection is a silent no-op).
    for (final tripId in _subscribedTrips.toList()) {
      try {
        await _connection?.invoke('SubscribeToTripLocation', args: [tripId]);
      } catch (_) {
        // Best-effort; a later reconnect retries.
      }
    }
  }

  Future<void> disconnect() async {
    _subscribedTrips.clear();
    await _connection?.stop();
    _connection = null;
  }

  /// Streams a driver GPS fix to the backend (fire-and-forget by the hub).
  Future<void> sendDriverLocation(LatLng position) async {
    if (!isConnected) return;
    try {
      await _connection?.invoke(
        'SendDriverLocation',
        args: [position.latitude, position.longitude],
      );
    } catch (_) {
      // Dropped fix — the next position update retries automatically.
    }
  }

  Future<void> subscribeToTripLocation(String tripId) async {
    _subscribedTrips.add(tripId);
    await _connection?.invoke('SubscribeToTripLocation', args: [tripId]);
  }

  Future<void> unsubscribeFromTripLocation(String tripId) async {
    _subscribedTrips.remove(tripId);
    await _connection?.invoke('UnsubscribeFromTripLocation', args: [tripId]);
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
    _reconnectedController.close();
  }
}
