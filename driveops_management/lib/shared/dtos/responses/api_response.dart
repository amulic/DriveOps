class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;

  const ApiResponse({
    this.data,
    this.message,
    required this.success,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json)? fromJsonT,
  ) {
    return ApiResponse(
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'] as T?,
      message: json['message'] as String?,
      success: json['success'] as bool? ?? true,
    );
  }
}

class PaginatedResponse<T> {
  final List<T> data;
  final int totalCount;
  final int page;
  final int pageSize;

  const PaginatedResponse({
    required this.data,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  int get totalPages => (totalCount / pageSize).ceil();

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return PaginatedResponse(
      data: (json['data'] as List<dynamic>?)
              ?.map((e) => fromJsonT(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalCount: json['totalCount'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      pageSize: json['pageSize'] as int? ?? 20,
    );
  }
}