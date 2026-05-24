import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/services/api_service.dart';
import 'package:driveops_management/shared/models/trip.dart';
import 'package:driveops_management/shared/dtos/requests/trip_requests.dart';
import 'package:driveops_management/config/api_config.dart';

final tripApiServiceProvider = Provider<TripApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TripApiService(apiService);
});

class TripApiService {
  final ApiService _api;

  TripApiService(this._api);

  Future<List<Trip>> getAllTrips() async {
    final response = await _api.get(ApiConfig.tripEndpoint, queryParameters: {'pageSize': 100});
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => Trip.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Trip> getTrip(String id) async {
    final response = await _api.get('${ApiConfig.tripEndpoint}/$id');
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Trip>> getTripsByCustomer(String customerId) async {
    final response = await _api.get('${ApiConfig.tripEndpoint}/customer/$customerId', queryParameters: {'pageSize': 100});
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => Trip.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Trip>> getTripsByDriver(String driverId) async {
    final response = await _api.get('${ApiConfig.tripEndpoint}/driver/$driverId', queryParameters: {'pageSize': 100});
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => Trip.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<List<Trip>> getActiveTripsByDriver(String driverId) async {
    final response = await _api.get('${ApiConfig.tripEndpoint}/driver/$driverId/active');
    final List<dynamic> data = response.data as List<dynamic>;
    return data.map((json) => Trip.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Trip> createTrip(CreateTripRequest request) async {
    final response = await _api.post(
      ApiConfig.tripEndpoint,
      data: request.toJson(),
    );
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TripEstimateResponse> estimateTrip(TripEstimateRequest request) async {
    final response = await _api.post(
      '${ApiConfig.tripEndpoint}/estimate',
      data: request.toJson(),
    );
    return TripEstimateResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Trip> assignDriver(String tripId, AssignDriverRequest request) async {
    final response = await _api.post(
      '${ApiConfig.tripEndpoint}/$tripId/assign',
      data: request.toJson(),
    );
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Trip> startTrip(String tripId) async {
    final response = await _api.post('${ApiConfig.tripEndpoint}/$tripId/start');
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Trip> completeTrip(String tripId, CompleteTripRequest request) async {
    final response = await _api.post(
      '${ApiConfig.tripEndpoint}/$tripId/complete',
      data: request.toJson(),
    );
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Trip> cancelTrip(String tripId, CancelTripRequest request) async {
    final response = await _api.post(
      '${ApiConfig.tripEndpoint}/$tripId/cancel',
      data: request.toJson(),
    );
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Trip> rateTrip(String tripId, RateTripRequest request) async {
    final response = await _api.post(
      '${ApiConfig.tripEndpoint}/$tripId/rate',
      data: request.toJson(),
    );
    return Trip.fromJson(response.data as Map<String, dynamic>);
  }
}