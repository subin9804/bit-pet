import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import 'models/group_models.dart';

Never _mapDioError(DioException e, String fallback) {
  final data = e.response?.data as Map<String, dynamic>?;
  final error = data?['error'] as Map<String, dynamic>?;
  throw ApiException(
    statusCode: e.response?.statusCode ?? 0,
    message: error?['message'] as String? ?? fallback,
    errorCode: error?['code'] as String?,
  );
}

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepository(ref.watch(dioProvider));
});

class GroupRepository {
  final Dio _dio;
  GroupRepository(this._dio);

  /// 내 그룹 조회. null이면 그룹 없음.
  Future<GroupInfo?> getMyGroup() async {
    final res = await _dio.get('/groups/me');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d != null ? GroupInfo.fromJson(d as Map<String, dynamic>) : null,
    );
    return apiRes.data;
  }

  Future<GroupInfo> createGroup(String name) async {
    final res = await _dio.post('/groups', data: {'name': name});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => GroupInfo.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '그룹 생성 실패');
    }
    return apiRes.data!;
  }

  /// OWNER 전용. 5분간 유효한 임시 초대코드 발급.
  Future<InviteCode> issueInviteCode() async {
    try {
      final res = await _dio.post('/groups/me/invite-code');
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => InviteCode.fromJson(d as Map<String, dynamic>),
      );
      if (!apiRes.success || apiRes.data == null) {
        throw ApiException(
            statusCode: res.statusCode ?? 0,
            message: apiRes.message ?? '초대코드 발급 실패',
            errorCode: apiRes.errorCode);
      }
      return apiRes.data!;
    } on DioException catch (e) {
      _mapDioError(e, '초대코드 발급 실패');
    }
  }

  Future<GroupInfo> joinGroup(String inviteCode) async {
    try {
      final res = await _dio.post('/groups/join', data: {'inviteCode': inviteCode});
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => GroupInfo.fromJson(d as Map<String, dynamic>),
      );
      if (!apiRes.success || apiRes.data == null) {
        throw ApiException(
            statusCode: res.statusCode ?? 0,
            message: apiRes.message ?? '그룹 참여 실패',
            errorCode: apiRes.errorCode);
      }
      return apiRes.data!;
    } on DioException catch (e) {
      _mapDioError(e, '그룹 참여 실패');
    }
  }

  Future<GroupInfo> updateGroupName(String name) async {
    final res = await _dio.patch('/groups/me/name', data: {'name': name});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => GroupInfo.fromJson(d as Map<String, dynamic>),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '이름 수정 실패');
    }
    return apiRes.data!;
  }

  Future<void> leaveOrDisband() async {
    await _dio.delete('/groups/me');
  }

  Future<void> kickMember(int userId) async {
    await _dio.delete('/groups/me/members/$userId');
  }
}
