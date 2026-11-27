import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/api_service.dart';
import 'package:driveops_management/shared/dtos/requests/admin_requests.dart';
import 'package:driveops_management/shared/models/admin_account.dart';

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  return AdminApiService(ref.watch(apiServiceProvider));
});

class AdminApiService {
  final ApiService _api;

  AdminApiService(this._api);

  Future<List<AdminAccount>> getAccounts({String? search}) async {
    final response = await _api.get(
      '/api/admin/accounts',
      queryParameters: {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        'pageSize': 50,
      },
    );
    final items = response.data as List<dynamic>;
    return items
        .map((json) => AdminAccount.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<AdminAccount> createAccount(CreateAccountPayload payload) async {
    final response = await _api.post('/api/admin/accounts', data: payload.toJson());
    return AdminAccount.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminAccount> updateAccount(String id, UpdateAccountPayload payload) async {
    final response = await _api.put('/api/admin/accounts/$id', data: payload.toJson());
    return AdminAccount.fromJson(response.data as Map<String, dynamic>);
  }

  Future<AdminAccount> setRoles(String id, List<String> roles) async {
    final response = await _api.put(
      '/api/admin/accounts/$id/roles',
      data: {'roles': roles},
    );
    return AdminAccount.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> resetPassword(String id, String temporaryPassword) async {
    await _api.post(
      '/api/admin/accounts/$id/reset-password',
      data: {'temporaryPassword': temporaryPassword},
    );
  }

  Future<FareSettings> getFareSettings() async {
    final response = await _api.get('/api/admin/settings/fare');
    return FareSettings.fromJson(response.data as Map<String, dynamic>);
  }

  Future<FareSettings> updateFareSettings(UpdateFareSettingsPayload payload) async {
    final response = await _api.put(
      '/api/admin/settings/fare',
      data: payload.toJson(),
    );
    return FareSettings.fromJson(response.data as Map<String, dynamic>);
  }
}
