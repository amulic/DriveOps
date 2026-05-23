class ApiConfig {
  static const String apiBaseUrl = 'http://localhost:5032';
  static const String signalrBaseUrl = 'http://localhost:5033';
  static const String realtimeBaseUrl = 'http://localhost:5033';

  static const String driverEndpoint = '/api/driver';
  static const String tripEndpoint = '/api/trip';
  static const String vehicleEndpoint = '/api/vehicle';
  static const String userEndpoint = '/api/user';
  static const String customerEndpoint = '/api/customer';
  static const String testEndpoint = '/api/test';

  static const String locationHubPath = '/hubs/location';
  static const String notificationHubPath = '/hubs/notification';
  static const String chatHubPath = '/hubs/chat';
}

class KeycloakConfig {
  static const String authority = 'http://localhost:8081/realms/driveops-dev';
  static const String realm = 'driveops-dev';
  static const String clientId = 'driveops-desktop';
  static const String audience = 'driveops-desktop';
  static const String tokenUrl = 'http://localhost:8081/realms/driveops-dev/protocol/openid-connect/token';
  static const String authUrl = 'http://localhost:8081/realms/driveops-dev/protocol/openid-connect/auth';
  static const String endSessionUrl = 'http://localhost:8081/realms/driveops-dev/protocol/openid-connect/logout';
  static const int redirectPort = 42069;
  static const String redirectHost = '127.0.0.1';
  static const String redirectUri = 'http://$redirectHost:$redirectPort/auth/callback';
  static const String postLogoutRedirectUri = 'http://$redirectHost:$redirectPort';
  static const String scopes = 'openid profile email roles';
}

class AppConstants {
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 60.0;
  static const double minWindowWidth = 1200.0;
  static const double minWindowHeight = 800.0;
}