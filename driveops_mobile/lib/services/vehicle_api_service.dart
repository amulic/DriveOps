import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/services/api_service.dart';
import 'package:driveops_mobile/shared/models/vehicle.dart';
import 'package:driveops_mobile/shared/models/defect_report.dart';
import 'package:driveops_mobile/shared/dtos/requests/vehicle_requests.dart';
import 'package:driveops_mobile/config/api_config.dart';

final vehicleApiServiceProvider = Provider<VehicleApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VehicleApiService(apiService);
});

class VehicleApiService {
  final ApiService _api;

  VehicleApiService(this._api);

  Future<List<Vehicle>> getAllVehicles() async {
    final response = await _api.get(ApiConfig.vehicleEndpoint, queryParameters: {'pageSize': 100});
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => Vehicle.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Vehicle>> getAvailableVehicles() async {
    final response = await _api.get('${ApiConfig.vehicleEndpoint}/available', queryParameters: {'pageSize': 100});
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => Vehicle.fromJson(json as Map<String, dynamic>)).toList();
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

  Future<void> reportDefect(String vehicleId, ReportVehicleDefectRequest request) async {
    await _api.post(
      '${ApiConfig.vehicleEndpoint}/$vehicleId/defects',
      data: request.toJson(),
    );
  }

  Future<List<DefectReport>> getVehicleDefects(String vehicleId) async {
    final response = await _api.get(
      '${ApiConfig.vehicleEndpoint}/$vehicleId/defects',
      queryParameters: {'pageSize': 100},
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => DefectReport.fromJson(json as Map<String, dynamic>)).toList();
  }
}