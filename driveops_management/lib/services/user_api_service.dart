import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/api_service.dart';
import 'package:driveops_management/shared/models/user.dart';
import 'package:driveops_management/shared/dtos/requests/user_requests.dart';
import 'package:driveops_management/config/api_config.dart';

final userApiServiceProvider = Provider<UserApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return UserApiService(apiService);
});

class UserApiService {
  final ApiService _api;

  UserApiService(this._api);

  Future<User> syncUser() async {
    final response = await _api.post('${ApiConfig.userEndpoint}/sync');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> getCurrentUser() async {
    final response = await _api.get('${ApiConfig.userEndpoint}/me');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> getUser(String id) async {
    final response = await _api.get('${ApiConfig.userEndpoint}/$id');
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> createUser(CreateUserRequest request) async {
    final response = await _api.post(
      ApiConfig.userEndpoint,
      data: request.toJson(),
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }

  Future<User> updateUser(String id, UpdateUserRequest request) async {
    final response = await _api.put(
      '${ApiConfig.userEndpoint}/$id',
      data: request.toJson(),
    );
    return User.fromJson(response.data as Map<String, dynamic>);
  }
}