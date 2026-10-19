import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_mobile/config/api_config.dart';
import 'package:driveops_mobile/services/api_service.dart';

final geocodingApiServiceProvider = Provider<GeocodingApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return GeocodingApiService(apiService);
});

/// A single address-search hit from `GET /api/geocode/search`.
class GeocodingResult {
  final String displayName;
  final double latitude;
  final double longitude;

  const GeocodingResult({
    required this.displayName,
    required this.latitude,
    required this.longitude,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) =>
      GeocodingResult(
        displayName: json['displayName'] as String? ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      );
}

/// Thin wrapper over the API's Nominatim-backed geocoding proxy.
class GeocodingApiService {
  final ApiService _api;

  GeocodingApiService(this._api);

  Future<List<GeocodingResult>> search(String query) async {
    final response = await _api.get(
      '${ApiConfig.geocodeEndpoint}/search',
      queryParameters: {'q': query},
    );
    final List<dynamic> data = response.data as List<dynamic>;
    return data
        .map((json) => GeocodingResult.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// The display name for a coordinate, or null when nothing resolves there.
  Future<String?> reverse(double lat, double lng) async {
    try {
      final response = await _api.get(
        '${ApiConfig.geocodeEndpoint}/reverse',
        queryParameters: {'lat': lat, 'lng': lng},
      );
      return (response.data as Map<String, dynamic>)['displayName'] as String?;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }
}
