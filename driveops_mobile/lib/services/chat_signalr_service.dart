import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:driveops_mobile/config/api_config.dart';

class ChatSignalrService {
  HubConnection? _connection;
  final _handlers = <String, List<void Function(List<dynamic>?)>>{};
  final _connectionStateController = StreamController<HubConnectionState>.broadcast();

  Stream<HubConnectionState> get connectionState => _connectionStateController.stream;

  Future<void> connect(String accessToken) async {
    if (_connection?.state == HubConnectionState.Connected) {
      return;
    }

    final url = '${ApiConfig.realtimeBaseUrl}${ApiConfig.chatHubPath}';

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

    _connection!.onreconnected(({connectionId}) {
      _connectionStateController.add(HubConnectionState.Connected);
    });

    await _connection!.start();
    _connectionStateController.add(HubConnectionState.Connected);
  }

  Future<void> disconnect() async {
    await _connection?.stop();
    _connection = null;
  }

  Future<void> sendMessage(String conversationId, String content) async {
    await _connection?.invoke('SendMessage', args: [conversationId, content]);
  }

  Future<void> sendTripMessage(String tripId, String content) async {
    await _connection?.invoke('SendTripMessage', args: [tripId, content]);
  }

  Future<void> joinConversationGroup(String conversationId) async {
    await _connection?.invoke('JoinConversation', args: [conversationId]);
  }

  Future<void> leaveConversationGroup(String conversationId) async {
    await _connection?.invoke('LeaveConversation', args: [conversationId]);
  }

  Future<void> markAsRead(String conversationId) async {
    await _connection?.invoke('MarkAsRead', args: [conversationId]);
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