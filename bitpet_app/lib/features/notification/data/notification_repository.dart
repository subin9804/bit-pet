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

  Future<NotificationPref> getPref() async {
    final res = await _dio.get('/notifications/settings');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => NotificationPref.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(statusCode: res.statusCode ?? 0, message: '알림 설정을 불러오지 못했어요');
    }
    return apiRes.data!;
  }

  /// 바뀐 항목 하나만 보낸다. null 인 필드는 서버가 건드리지 않는다 —
  /// 전체를 보내면 다른 기기에서 방금 바꾼 설정을 덮어쓴다.
  Future<NotificationPref> updatePref({
    bool? routine,
    bool? comment,
    bool? postLike,
    bool? marketing,
  }) async {
    final res = await _dio.patch('/notifications/settings', data: {
      if (routine != null) 'routine': routine,
      if (comment != null) 'comment': comment,
      if (postLike != null) 'postLike': postLike,
      if (marketing != null) 'marketing': marketing,
    });
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => NotificationPref.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(statusCode: res.statusCode ?? 0, message: '알림 설정을 저장하지 못했어요');
    }
    return apiRes.data!;
  }
}
