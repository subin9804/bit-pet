import 'package:dio/dio.dart';

/// 서버가 내려준 사람이 읽을 문구를 꺼낸다. 못 꺼내면 null.
///
/// 4xx 는 대부분 **사용자가 고칠 수 있는 상황**(중복 신고, 어린이 게시판 제한,
/// 자녀 계정 개수 초과)이라 서버 문장이 가장 정확하다. `e.toString()` 을 그대로
/// 띄우면 `DioException [bad response]...` 가 사용자 앞에 뜬다.
String? serverMessageOf(Object e) {
  if (e is ApiException) return e.message;
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final error = data['error'];
      if (error is Map<String, dynamic>) return error['message'] as String?;
    }
  }
  return null;
}

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
