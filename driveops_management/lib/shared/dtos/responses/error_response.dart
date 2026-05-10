class ErrorResponse {
  final String error;
  final String? code;
  final List<Map<String, dynamic>>? details;

  const ErrorResponse({
    required this.error,
    this.code,
    this.details,
  });

  factory ErrorResponse.fromJson(Map<String, dynamic> json) {
    return ErrorResponse(
      error: json['error'] as String? ?? json['message'] as String? ?? 'Unknown error',
      code: json['code'] as String?,
      details: json['details'] != null
          ? (json['details'] as List<dynamic>)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList()
          : null,
    );
  }
}