import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/api_response.dart';
import 'models/share_models.dart';

Never _mapDioError(DioException e, String fallback) {
  final data = e.response?.data as Map<String, dynamic>?;
  final error = data?['error'] as Map<String, dynamic>?;
  throw ApiException(
    statusCode: e.response?.statusCode ?? 0,
    message: error?['message'] as String? ?? fallback,
    errorCode: error?['code'] as String?,
  );
}

final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return ShareRepository(ref.watch(dioProvider));
});

/// 개체 공유·입분양 API (pet_keeper_rls 기반)
class ShareRepository {
  final Dio _dio;
  ShareRepository(this._dio);

  // ── 내 공유코드 ──────────────────────────────────────────────

  /// 내 공유코드 조회 (없으면 서버가 발급)
  Future<String> myShareCode() async {
    try {
      final res = await _dio.get('/pets/share/my-code');
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => (d as Map<String, dynamic>)['shareCode'] as String,
      );
      if (!apiRes.success || apiRes.data == null) {
        throw ApiException(
            statusCode: res.statusCode ?? 0, message: '공유코드 조회 실패');
      }
      return apiRes.data!;
    } on DioException catch (e) {
      _mapDioError(e, '공유코드 조회 실패');
    }
  }

  // ── 벌크 초대 (여러 개체 한 번에) ─────────────────────────────

  /// 여러 개체를 한 번에 공유·입분양 초대
  Future<ShareInvitationBatch> inviteBulk({
    required String shareCode,
    required ShareInviteType inviteType,
    required List<int> petIds,
  }) async {
    try {
      final res = await _dio.post('/pets/share/bulk', data: {
        'shareCode': shareCode,
        'inviteType': inviteType.serverValue,
        'petIds': petIds,
      });
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => ShareInvitationBatch.fromJson(d as Map<String, dynamic>),
      );
      if (!apiRes.success || apiRes.data == null) {
        throw ApiException(
            statusCode: res.statusCode ?? 0, message: '초대 전송 실패');
      }
      return apiRes.data!;
    } on DioException catch (e) {
      _mapDioError(e, '초대 전송 실패');
    }
  }

  // ── 받은 초대함 ──────────────────────────────────────────────

  /// 내가 받은 대기중 초대 — 배치(여러 개체)로 묶어 조회
  Future<List<ShareInvitationBatch>> receivedBatches() async {
    try {
      final res = await _dio.get('/pets/share/invitations/batches');
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => (d as List)
            .map((e) => ShareInvitationBatch.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return apiRes.data ?? [];
    } on DioException catch (e) {
      _mapDioError(e, '초대 목록 조회 실패');
    }
  }

  Future<void> acceptBatch(String batchId) async {
    try {
      await _dio.post('/pets/share/batches/$batchId/accept');
    } on DioException catch (e) {
      _mapDioError(e, '초대 수락 실패');
    }
  }

  Future<void> rejectBatch(String batchId) async {
    try {
      await _dio.post('/pets/share/batches/$batchId/reject');
    } on DioException catch (e) {
      _mapDioError(e, '초대 거절 실패');
    }
  }

  /// 내가 받은 대기중 초대 목록 (단건 flat — 하위 호환)
  Future<List<ShareInvitation>> received() async {
    try {
      final res = await _dio.get('/pets/share/invitations');
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => (d as List)
            .map((e) => ShareInvitation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return apiRes.data ?? [];
    } on DioException catch (e) {
      _mapDioError(e, '초대 목록 조회 실패');
    }
  }

  Future<void> accept(int invitationId) async {
    try {
      await _dio.post('/pets/share/invitations/$invitationId/accept');
    } on DioException catch (e) {
      _mapDioError(e, '초대 수락 실패');
    }
  }

  Future<void> reject(int invitationId) async {
    try {
      await _dio.post('/pets/share/invitations/$invitationId/reject');
    } on DioException catch (e) {
      _mapDioError(e, '초대 거절 실패');
    }
  }

  Future<void> cancel(int invitationId) async {
    try {
      await _dio.post('/pets/share/invitations/$invitationId/cancel');
    } on DioException catch (e) {
      _mapDioError(e, '초대 취소 실패');
    }
  }

  // ── 개체별 공유 관리 (소유자) ─────────────────────────────────

  /// 공유·입분양 초대 보내기 (대상은 공유코드로 지정)
  Future<ShareInvitation> invite(
    int petId, {
    required String shareCode,
    required ShareInviteType inviteType,
  }) async {
    try {
      final res = await _dio.post('/pets/$petId/share', data: {
        'shareCode': shareCode,
        'inviteType': inviteType.serverValue,
      });
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => ShareInvitation.fromJson(d as Map<String, dynamic>),
      );
      if (!apiRes.success || apiRes.data == null) {
        throw ApiException(
            statusCode: res.statusCode ?? 0, message: '초대 전송 실패');
      }
      return apiRes.data!;
    } on DioException catch (e) {
      _mapDioError(e, '초대 전송 실패');
    }
  }

  /// 개체에 대해 내가 보낸 대기중 초대 목록
  Future<List<ShareInvitation>> sent(int petId) async {
    try {
      final res = await _dio.get('/pets/$petId/share/invitations');
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => (d as List)
            .map((e) => ShareInvitation.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return apiRes.data ?? [];
    } on DioException catch (e) {
      _mapDioError(e, '보낸 초대 조회 실패');
    }
  }

  /// 개체 사육자(공유 멤버) 목록
  Future<List<Keeper>> keepers(int petId) async {
    try {
      final res = await _dio.get('/pets/$petId/keepers');
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => (d as List)
            .map((e) => Keeper.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return apiRes.data ?? [];
    } on DioException catch (e) {
      _mapDioError(e, '사육자 목록 조회 실패');
    }
  }

  /// 공유 해제 — 사육자 내보내기 (소유자)
  Future<void> revokeKeeper(int petId, int keeperUserId) async {
    try {
      await _dio.delete('/pets/$petId/keepers/$keeperUserId');
    } on DioException catch (e) {
      _mapDioError(e, '공유 해제 실패');
    }
  }

  /// 공유받은 개체에서 스스로 나가기 (KEEPER)
  Future<void> leave(int petId) async {
    try {
      await _dio.delete('/pets/$petId/keepers/me');
    } on DioException catch (e) {
      _mapDioError(e, '나가기 실패');
    }
  }
}
