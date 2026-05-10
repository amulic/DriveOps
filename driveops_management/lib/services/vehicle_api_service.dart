import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../shared/models/vehicle.dart';
import '../shared/dtos/requests/vehicle_requests.dart';
import '../config/api_config.dart';

final vehicleApiServiceProvider = Provider<VehicleApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VehicleApiService(apiService);
});

class VehicleApiService {
  final ApiService _api;

  VehicleApiService(this._api);

  Future<List<Vehicle>> getAllVehicles() async {
    final response = await _api.get(ApiConfig.vehicleEndpoint);
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => Vehicle.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Vehicle>> getAvailableVehicles() async {
    final response = await _api.get('${ApiConfig.vehicleEndpoint}/available');
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => Vehicle.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Vehicle> getVehicle(String id) async {
    final response = await _api.get('${ApiConfig.vehicleEndpoint}/$id');
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Vehicle> createVehicle(CreateVehicleRequest request) async {
    final response = await _api.post(
      ApiConfig.vehicleEndpoint,
      data: request.toJson(),
    );
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Vehicle> updateVehicle(String id, UpdateVehicleRequest request) async {
    final response = await _api.put(
      '${ApiConfig.vehicleEndpoint}/$id',
      data: request.toJson(),
    );
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Vehicle> assignVehicle(String id, AssignVehicleRequest request) async {
    final response = await _api.post(
      '${ApiConfig.vehicleEndpoint}/$id/assign',
      data: request.toJson(),
    );
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Vehicle> unassignVehicle(String id) async {
    final response = await _api.post('${ApiConfig.vehicleEndpoint}/$id/unassign');
    return Vehicle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteVehicle(String id) async {
    await _api.delete('${ApiConfig.vehicleEndpoint}/$id');
  }
}