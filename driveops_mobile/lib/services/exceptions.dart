import 'package:dio/dio.dart';

enum ApiErrorCode {
  networkError,
  serverError,
  unauthorized,
  notFound,
  validationError,
  unknown,
}

class ApiException implements Exception {
  final ApiErrorCode code;
  final String message;
  final int? statusCode;
  final dynamic details;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.details,
  });

  factory ApiException.networkError([String? message]) {
    return ApiException(
      code: ApiErrorCode.networkError,
      message: message ?? 'Network connection failed. Please check your internet.',
      statusCode: null,
    );
  }

  factory ApiException.serverError([String? message, int? statusCode]) {
    return ApiException(
      code: ApiErrorCode.serverError,
      message: message ?? 'Server error occurred. Please try again later.',
      statusCode: statusCode,
    );
  }

  factory ApiException.unauthorized([String? message]) {
    return ApiException(
      code: ApiErrorCode.unauthorized,
      message: message ?? 'Session expired. Please log in again.',
      statusCode: 401,
    );
  }

  factory ApiException.notFound([String? message]) {
    return ApiException(
      code: ApiErrorCode.notFound,
      message: message ?? 'Requested resource not found.',
      statusCode: 404,
    );
  }

  factory ApiException.validationError(String message, [dynamic details]) {
    return ApiException(
      code: ApiErrorCode.validationError,
      message: message,
      statusCode: 400,
      details: details,
    );
  }

  factory ApiException.unknown([String? message]) {
    return ApiException(
      code: ApiErrorCode.unknown,
      message: message ?? 'An unexpected error occurred.',
      statusCode: null,
    );
  }

  factory ApiException.fromDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return ApiException.networkError(
          'Connection timed out. Please check your internet.',
        );
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final data = error.response?.data;
        String message = 'Server error occurred.';
        if (data is Map<String, dynamic>) {
          message = data['message'] ?? data['error'] ?? message;
        }
        if (statusCode == 401) {
          return ApiException.unauthorized(message);
        } else if (statusCode == 404) {
          return ApiException.notFound(message);
        } else if (statusCode == 400 || statusCode == 422) {
          return ApiException.validationError(message, data);
        } else if (statusCode != null && statusCode >= 500) {
          return ApiException.serverError(message, statusCode);
        }
        return ApiException(
          code: ApiErrorCode.serverError,
          message: message,
          statusCode: statusCode,
          details: data,
        );
      case DioExceptionType.cancel:
        return ApiException.unknown('Request cancelled.');
      case DioExceptionType.unknown:
      default:
        if (error.message?.contains('SocketException') == true ||
            error.message?.contains('Connection refused') == true) {
          return ApiException.networkError();
        }
        return ApiException.unknown(error.message);
    }
  }

  @override
  String toString() => 'ApiException($code): $message';
}