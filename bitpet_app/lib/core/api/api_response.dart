class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final String? errorCode;

  const ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errorCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    final error = json['error'] as Map<String, dynamic>?;
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      data: json['data'] != null && fromData != null
          ? fromData(json['data'])
          : json['data'] as T?,
      message: error?['message'] as String?,
      errorCode: error?['code'] as String?,
    );
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  final String? errorCode;

  const ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}
