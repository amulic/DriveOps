import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../shared/models/driver.dart';
import '../shared/dtos/requests/driver_requests.dart';
import '../config/api_config.dart';

final driverApiServiceProvider = Provider<DriverApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DriverApiService(apiService);
});

class DriverApiService {
  final ApiService _api;

  DriverApiService(this._api);

  Future<List<Driver>> getAllDrivers() async {
    final response = await _api.get(ApiConfig.driverEndpoint);
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => Driver.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Driver> getDriver(String id) async {
    final response = await _api.get('${ApiConfig.driverEndpoint}/$id');
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Driver>> getAvailableDrivers() async {
    final response = await _api.get('${ApiConfig.driverEndpoint}/available');
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => Driver.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Driver>> getNearbyDrivers({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
  }) async {
    final response = await _api.get(
      '${ApiConfig.driverEndpoint}/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
      },
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => Driver.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Driver> createDriver(CreateDriverRequest request) async {
    final response = await _api.post(
      ApiConfig.driverEndpoint,
      data: request.toJson(),
    );
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Driver> updateDriver(String id, UpdateDriverRequest request) async {
    final response = await _api.put(
      '${ApiConfig.driverEndpoint}/$id',
      data: request.toJson(),
    );
    return Driver.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateDriverLocation(String id, UpdateDriverLocationRequest request) async {
    await _api.patch(
      '${ApiConfig.driverEndpoint}/$id/location',
      data: request.toJson(),
    );
  }

  Future<void> setDriverStatus(String id, SetDriverStatusRequest request) async {
    await _api.patch(
      '${ApiConfig.driverEndpoint}/$id/status',
      data: request.toJson(),
    );
  }

  Future<void> suspendDriver(String id) async {
    await _api.post('${ApiConfig.driverEndpoint}/$id/suspend');
  }

  Future<void> activateDriver(String id) async {
    await _api.post('${ApiConfig.driverEndpoint}/$id/activate');
  }
}