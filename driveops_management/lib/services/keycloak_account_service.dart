import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:driveops_management/config/api_config.dart';
import 'package:driveops_management/services/auth_service.dart';
import 'package:driveops_management/services/exceptions.dart';

/// Profile data returned by the Keycloak Account REST API.
class KeycloakAccountProfile {
  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final bool emailVerified;

  const KeycloakAccountProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.emailVerified,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory KeycloakAccountProfile.fromJson(Map<String, dynamic> json) {
    return KeycloakAccountProfile(
      id: (json['id'] ?? '') as String,
      username: (json['username'] ?? '') as String,
      firstName: (json['firstName'] ?? '') as String,
      lastName: (json['lastName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      emailVerified: json['emailVerified'] as bool? ?? false,
    );
  }
}

final keycloakAccountServiceProvider = Provider<KeycloakAccountService>((ref) {
  return KeycloakAccountService();
});

/// Wraps the Keycloak Account REST API ({realm}/account/), which lets the
/// signed-in user manage their own identity: profile fields, credentials,
/// sessions. Authenticated with the app's existing access token — the
/// driveops-desktop client has fullScopeAllowed, so the token carries the
/// required `account` client roles (view-profile / manage-account).
class KeycloakAccountService {
  final Dio _dio;
  final AuthService _authService;

  KeycloakAccountService({AuthService? authService})
      : _authService = authService ?? AuthService(),
        _dio = Dio(
          BaseOptions(
            baseUrl: KeycloakConfig.accountUrl,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: {'Content-Type': 'application/json'},
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _authService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Fetches the current user's Keycloak profile.
  Future<KeycloakAccountProfile> getProfile() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('');
      return KeycloakAccountProfile.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to load profile');
    }
  }

  /// Updates the user's first name, last name and email in Keycloak.
  /// Returns the updated profile.
  Future<KeycloakAccountProfile> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    try {
      await _dio.post<dynamic>(
        '',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
        },
      );
      return getProfile();
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to update profile');
    }
  }

  /// Changes the user's password. Requires the current password.
  /// Returns normally on success, throws [ApiException] otherwise.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _dio.put<dynamic>(
        'credentials/password',
        data: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmation': newPassword,
        },
      );
    } on DioException catch (e) {
      throw _mapError(e, 'Failed to change password');
    }
  }

  ApiException _mapError(DioException error, String fallback) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return ApiException.networkError();
    }

    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String? keycloakMessage;
    if (data is Map<String, dynamic>) {
      keycloakMessage =
          (data['errorMessage'] ?? data['error_description'] ?? data['error'])
              as String?;
    } else if (data is String && data.isNotEmpty) {
      keycloakMessage = data;
    }

    if (statusCode == 401 || statusCode == 403) {
      return ApiException.unauthorized(
        'Your session does not have permission to manage this account. '
        'Try signing out and back in, or use the Keycloak Account Console.',
      );
    }
    if (statusCode == 400) {
      return ApiException.validationError(keycloakMessage ?? fallback);
    }

    return ApiException(
      code: ApiErrorCode.serverError,
      message: keycloakMessage ?? fallback,
      statusCode: statusCode,
    );
  }
}
