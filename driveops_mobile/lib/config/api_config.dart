import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Backend + Keycloak configuration for the mobile app.
///
/// The Android emulator reaches the host machine's localhost via 10.0.2.2.
/// Physical devices must use the host machine's LAN IP instead (or run
/// `adb reverse tcp:5032 tcp:5032` etc.).
class ApiConfig {
  static String get _host => (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';

  static String get apiBaseUrl => 'http://$_host:5032';
  static String get realtimeBaseUrl => 'http://$_host:5033';

  static const String driverEndpoint = '/api/driver';
  static const String tripEndpoint = '/api/trip';
  static const String vehicleEndpoint = '/api/vehicle';
  static const String customerEndpoint = '/api/customer';

  static const String notificationHubPath = '/hubs/notification';
  static const String chatHubPath = '/hubs/chat';
}

class KeycloakConfig {
  static String get _host => (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : 'localhost';

  static String get authority => 'http://$_host:8081/realms/driveops-dev';
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
