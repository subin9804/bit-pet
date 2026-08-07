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

  /// 태그 스캔 (v2) — 상태 + 개체 카드를 한 번에 받는다.
  /// 없는 코드는 404(TAG_NOT_FOUND), 차단된 코드는 status=REVOKED로 내려온다.
  Future<NfcScanResult> scan(String tagCd) async {
    try {
      final res = await _dio.get('/nfc/tags/$tagCd/resolve');
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => NfcScanResult.fromJson(d as Map<String, dynamic>),
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

  /// 태그 바인딩.
  ///
  /// [rebind]가 false인데 태그가 내 다른 개체에 붙어 있으면
  /// 409 `TAG_REBIND_CONFIRM_REQUIRED`가 온다. 그때 어느 개체인지는 에러 메시지에 담겨 있으니
  /// 사용자에게 확인받고 rebind=true로 다시 부른다. 남의 개체에 붙은 태그는
  /// 409 `TAG_ALREADY_LINKED` — 이건 확인으로 넘길 수 없다.
  Future<NfcScanResult> bind({
    required String tagCd,
    required int petId,
    bool rebind = false,
  }) async {
    try {
      final res = await _dio.post('/nfc/bindings',
          data: {'tagCd': tagCd, 'petId': petId, 'rebind': rebind});
      final apiRes = ApiResponse.fromJson(
        res.data as Map<String, dynamic>,
        (d) => NfcScanResult.fromJson(d as Map<String, dynamic>),
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

  /// 태그를 개체에 연결. 남이 쓰는 태그면 409(TAG_ALREADY_LINKED)
  Future<TagResolveResult> link({
    required String tagCd,
    required int petId,
  }) async {
    try {
      final res = await _dio.post('/tags/$tagCd/link', data: {'petId': petId});
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
