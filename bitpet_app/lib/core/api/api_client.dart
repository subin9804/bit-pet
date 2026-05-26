import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/token_storage.dart';
import 'interceptors/auth_interceptor.dart';

// 로컬 개발: adb reverse tcp:8080 tcp:8080 실행 후 localhost 사용
// (10.0.2.2는 Windows 방화벽에 막히는 경우 있음 → adb reverse가 더 안정적)
const String kBaseUrl = 'http://localhost:8080/api/v1';

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(dio, tokenStorage));
  return dio;
});
