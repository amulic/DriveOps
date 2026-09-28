import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Compile-time override for the backend/Keycloak host.
///
/// - Physical device + `adb reverse` tunnels: run with
///   `--dart-define=API_HOST=localhost` (localhost on the phone is forwarded to
///   the laptop over USB).
/// - Android emulator (no override): defaults to `10.0.2.2`, the emulator's
///   alias for the host machine's loopback.
/// - Desktop/web: `localhost`.
const String _hostOverride = String.fromEnvironment('API_HOST');

String get _backendHost => _hostOverride.isNotEmpty
    ? _hostOverride
    : ((!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost');

/// Backend + Keycloak configuration for the mobile app.
class ApiConfig {
  static String get apiBaseUrl => 'http://$_backendHost:5032';
  static String get realtimeBaseUrl => 'http://$_backendHost:5033';

  static const String driverEndpoint = '/api/driver';
  static const String tripEndpoint = '/api/trip';
  static const String vehicleEndpoint = '/api/vehicle';
  static const String customerEndpoint = '/api/customer';

  static const String notificationHubPath = '/hubs/notification';
  static const String chatHubPath = '/hubs/chat';
}

class KeycloakConfig {
  static String get authority => 'http://$_backendHost:8081/realms/driveops-dev';
  static const String realm = 'driveops-dev';
  static const String clientId = 'driveops-mobile';
  static String get tokenUrl => '$authority/protocol/openid-connect/token';
  static String get authUrl => '$authority/protocol/openid-connect/auth';
  static String get endSessionUrl => '$authority/protocol/openid-connect/logout';

  /// Custom-scheme redirect registered on the driveops-mobile Keycloak client.
  static const String redirectUri = 'com.driveops.mobile://oauth2redirect';
  static const String postLogoutRedirectUri = 'com.driveops.mobile://logout';
  static const String scopes = 'openid profile email roles offline_access';
}
