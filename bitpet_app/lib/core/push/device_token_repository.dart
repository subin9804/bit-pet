import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';

final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return DeviceTokenRepository(ref.watch(dioProvider));
});

/// 서버(device_token_rls)에 FCM 디바이스 토큰을 등록/해제한다.
class DeviceTokenRepository {
  final Dio _dio;
  DeviceTokenRepository(this._dio);

  Future<void> register({
    required String deviceToken,
    required String platform, // ANDROID / IOS
    String? deviceInfo,
  }) async {
    await _dio.post('/device-tokens', data: {
      'deviceToken': deviceToken,
      'platform': platform,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
    });
  }

  Future<void> unregister(String deviceToken) async {
    await _dio.delete(
      '/device-tokens',
      queryParameters: {'deviceToken': deviceToken},
    );
  }
}
