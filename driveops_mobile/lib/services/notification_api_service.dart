import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:driveops_mobile/config/api_config.dart';
import 'package:driveops_mobile/services/auth_service.dart';
import 'package:driveops_mobile/shared/models/app_notification.dart';

final notificationApiServiceProvider = Provider<NotificationApiService>((ref) {
  final authService = AuthService();
  final dio = Dio(BaseOptions(
    baseUrl: ApiConfig.realtimeBaseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(_NotificationAuthInterceptor(authService, dio));

  return NotificationApiService(dio);
});

class _NotificationAuthInterceptor extends Interceptor {
  final AuthService _authService;
  final Dio _dio;

  _NotificationAuthInterceptor(this._authService, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _authService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 401) {
      final refreshed = await _authService.refreshToken();
      if (refreshed != null) {
        try {
          final retryResponse = await _retryRequest(error.requestOptions, refreshed.accessToken);
          return handler.resolve(retryResponse);
        } catch (_) {
          return handler.next(error);
        }
      }
    }
    return handler.next(error);
  }

  Future<Response> _retryRequest(RequestOptions requestOptions, String token) async {
    final options = Options(
      method: requestOptions.method,
      headers: {
        ...requestOptions.headers,
        'Authorization': 'Bearer $token',
      },
    );
    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
    );
  }
}

class NotificationApiService {
  final Dio _dio;

  NotificationApiService(this._dio);

  Future<PagedNotifications> getNotifications({int page = 1, int pageSize = 50}) async {
    final response = await _dio.get(
      '/api/notifications',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PagedNotifications.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> markAsRead(String id) async {
    await _dio.post('/api/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _dio.post('/api/notifications/read-all');
  }
}
