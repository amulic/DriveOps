import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/api_service.dart';
import 'package:driveops_management/shared/models/defect_report.dart';
import 'package:driveops_management/config/api_config.dart';

final defectApiServiceProvider = Provider<DefectApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return DefectApiService(apiService);
});

class DefectApiService {
  final ApiService _api;

  DefectApiService(this._api);

  Future<List<DefectReport>> getDefects({
    String? status,
    int? severity,
    String? vehicleId,
    String? driverId,
  }) async {
    final response = await _api.get(
      ApiConfig.defectEndpoint,
      queryParameters: {
        'status': ?status,
        'severity': ?severity,
        'vehicleId': ?vehicleId,
        'driverId': ?driverId,
        'pageSize': 100,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => DefectReport.fromJson(json as Map<String, dynamic>)).toList();
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

  Future<DefectReport> resolveDefect(String id, {String? resolutionNotes}) async {
    final response = await _api.post(
      '${ApiConfig.defectEndpoint}/$id/resolve',
      data: {'resolutionNotes': resolutionNotes},
    );
    return DefectReport.fromJson(response.data as Map<String, dynamic>);
  }

  Future<DefectReport> reopenDefect(String id) async {
    final response = await _api.post('${ApiConfig.defectEndpoint}/$id/reopen');
    return DefectReport.fromJson(response.data as Map<String, dynamic>);
  }
}
