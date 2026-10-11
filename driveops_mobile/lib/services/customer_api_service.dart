import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/services/api_service.dart';
import 'package:driveops_mobile/shared/models/customer.dart';
import 'package:driveops_mobile/shared/dtos/requests/customer_requests.dart';
import 'package:driveops_mobile/config/api_config.dart';

final customerApiServiceProvider = Provider<CustomerApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CustomerApiService(apiService);
});

class CustomerApiService {
  final ApiService _api;

  CustomerApiService(this._api);

  Future<Customer?> getCustomerByKeycloakId(String keycloakId) async {
    try {
      final response = await _api.get('${ApiConfig.customerEndpoint}/keycloak/$keycloakId');
      return Customer.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<Customer> getCustomer(String id) async {
    final response = await _api.get('${ApiConfig.customerEndpoint}/$id');
    return Customer.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Customer> createCustomer(CreateCustomerRequest request) async {
    final response = await _api.post(
      ApiConfig.customerEndpoint,
      data: request.toJson(),
    );
    return Customer.fromJson(response.data as Map<String, dynamic>);
  }
}
