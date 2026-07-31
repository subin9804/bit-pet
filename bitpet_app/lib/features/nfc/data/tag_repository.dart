import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import 'models/tag_models.dart';

Never _mapDioError(DioException e, String fallback) {
  final data = e.response?.data as Map<String, dynamic>?;
  final error = data?['error'] as Map<String, dynamic>?;
  throw ApiException(
    statusCode: e.response?.statusCode ?? 0,
    message: error?['message'] as String? ?? fallback,
    errorCode: error?['code'] as String?,
  );
}

final tagRepositoryProvider = Provider<TagRepository>((ref) {
  return TagRepository(ref.watch(dioProvider));
});

/// NFC 태그 이름표 API (nfc_tag_mst 기반)
class TagRepository {
  final Dio _dio;
  TagRepository(this._dio);

  /// 태그 스캔 — 없는 코드는 404(TAG_NOT_FOUND)를 그대로 올려보낸다 (위조 태그 차단)
  Future<TagResolveResult> resolve(String tagCd) async {
    try {
      final res = await _dio.get('/tags/$tagCd');
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => TagResolveResult.fromJson(d as Map<String, dynamic>),
      );
      if (!apiRes.success || apiRes.data == null) {
        throw ApiException(
            statusCode: res.statusCode ?? 0, message: '태그 정보를 불러오지 못했습니다.');
      }
      return apiRes.data!;
    } on DioException catch (e) {
      _mapDioError(e, '태그 정보를 불러오지 못했습니다.');
    }
  }

  /// 태그를 개체에 연결. 남이 쓰는 태그면 409(TAG_ALREADY_LINKED)
  Future<TagResolveResult> link({
    required String tagCd,
    required int petId,
    TagAction action = TagAction.petDetail,
  }) async {
    try {
      final res = await _dio.post('/tags/$tagCd/link', data: {
        'petId': petId,
        'defaultActionCd': action.serverValue,
      });
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => TagResolveResult.fromJson(d as Map<String, dynamic>),
      );
      if (!apiRes.success || apiRes.data == null) {
        throw ApiException(
            statusCode: res.statusCode ?? 0, message: '태그 연결에 실패했습니다.');
      }
      return apiRes.data!;
    } on DioException catch (e) {
      _mapDioError(e, '태그 연결에 실패했습니다.');
    }
  }

  /// 연결 해제 — 레코드는 남고 연결만 끊긴다. 개체 양도 시 원 소유자가 먼저 호출.
  Future<void> unlink(String tagCd) async {
    try {
      await _dio.delete('/tags/$tagCd/link');
    } on DioException catch (e) {
      _mapDioError(e, '태그 연결 해제에 실패했습니다.');
    }
  }

  /// 기본 동작만 변경 (개체는 그대로)
  Future<MyTag> updateAction(String tagCd, TagAction action) async {
    try {
      final res = await _dio.patch('/tags/$tagCd/action',
          data: {'defaultActionCd': action.serverValue});
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => MyTag.fromJson(d as Map<String, dynamic>),
      );
      if (!apiRes.success || apiRes.data == null) {
        throw ApiException(
            statusCode: res.statusCode ?? 0, message: '태그 설정 변경에 실패했습니다.');
      }
      return apiRes.data!;
    } on DioException catch (e) {
      _mapDioError(e, '태그 설정 변경에 실패했습니다.');
    }
  }

  Future<List<MyTag>> myTags() async {
    try {
      final res = await _dio.get('/tags/my');
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => (d as List)
            .map((e) => MyTag.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      return apiRes.data ?? [];
    } on DioException catch (e) {
      _mapDioError(e, '태그 목록을 불러오지 못했습니다.');
    }
  }
}
