class ApiConfig {
  static const String apiBaseUrl = 'http://localhost:5032';
  static const String signalrBaseUrl = 'http://localhost:5033';

  static const String driverEndpoint = '/api/driver';
  static const String tripEndpoint = '/api/trip';
  static const String vehicleEndpoint = '/api/vehicle';
  static const String userEndpoint = '/api/user';

  static const String locationHubPath = '/hubs/location';
  static const String notificationHubPath = '/hubs/notification';
  static const String chatHubPath = '/hubs/chat';
}

class AppConstants {
  static const double sidebarWidth = 260.0;
  static const double sidebarCollapsedWidth = 60.0;
  static const double minWindowWidth = 1200.0;
  static const double minWindowHeight = 800.0;
}
