import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import 'models/notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

class NotificationRepository {
  final Dio _dio;
  NotificationRepository(this._dio);

  Future<List<NotificationLog>> getNotifications() async {
    final res = await _dio.get('/notifications');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List)
          .map((e) => NotificationLog.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return apiRes.data ?? [];
  }

  Future<NotificationLog> markRead(int notificationId) async {
    final res = await _dio.patch('/notifications/$notificationId/read');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => NotificationLog.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(statusCode: res.statusCode ?? 0, message: '읽음 처리 실패');
    }
    return apiRes.data!;
  }
}
