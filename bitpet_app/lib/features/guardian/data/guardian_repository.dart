import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';

Never _mapDioError(DioException e, String fallback) {
  final data = e.response?.data as Map<String, dynamic>?;
  final error = data?['error'] as Map<String, dynamic>?;
  throw ApiException(
    statusCode: e.response?.statusCode ?? 0,
    message: error?['message'] as String? ?? fallback,
  );
}

/// 보호자가 보는 자녀 계정. 서버 `ChildResponse` 의 거울이다.
///
/// ⛔ 자녀의 비밀번호나 토큰은 여기에 없다 — 보호자는 자녀 계정으로 로그인하지 않는다.
class ChildAccount {
  final int id;
  final String email;
  final String nickname;
  final String? profileImageUrl;
  final String profileColor;
  final DateTime? birthDate;

  /// 지금도 만 14세 미만인가. 서버가 조회 시점에 계산해 내려준다 —
  /// 생일이 지나 만 14세가 되면 그날부터 일반 회원과 같아진다.
  final bool isChild;

  const ChildAccount({
    required this.id,
    required this.email,
    required this.nickname,
    required this.profileImageUrl,
    required this.profileColor,
    required this.birthDate,
    required this.isChild,
  });

  factory ChildAccount.fromJson(Map<String, dynamic> json) => ChildAccount(
        id: json['id'] as int,
        email: json['email'] as String,
        nickname: json['nickname'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
        profileColor: json['profileColor'] as String? ?? 'peach',
        birthDate: json['birthDate'] == null
            ? null
            : DateTime.parse(json['birthDate'] as String),
        isChild: json['isChild'] as bool? ?? false,
      );
}

final guardianRepositoryProvider = Provider<GuardianRepository>((ref) {
  return GuardianRepository(dio: ref.watch(dioProvider));
});

class GuardianRepository {
  final Dio _dio;

  GuardianRepository({required Dio dio}) : _dio = dio;

  Future<List<ChildAccount>> getChildren() async {
    final res = await _dio.get('/guardian/children');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => (d as List).cast<Map<String, dynamic>>(),
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '자녀 계정을 불러올 수 없습니다.');
    }
    return apiRes.data!.map(ChildAccount.fromJson).toList();
  }

  /// 자녀 계정 생성. 법정대리인 동의가 이 요청에 함께 담긴다 —
  /// 계정만 먼저 만들고 동의를 나중에 받는 경로를 만들지 말 것.
  Future<ChildAccount> createChild({
    required String email,
    required String password,
    required String nickname,
    required DateTime birthDate,
    String? profileColor,
    bool agreeMarketing = false,
  }) async {
    final Response<dynamic> res;
    try {
      res = await _dio.post('/guardian/children', data: {
        'email': email,
        'password': password,
        'nickname': nickname,
        'birthDate': _yyyyMMdd(birthDate),
        if (profileColor != null) 'profileColor': profileColor,
        'agreeGuardian': true,
        'agreeMarketing': agreeMarketing,
      });
    } on DioException catch (e) {
      // 서버 문구를 그대로 올린다 — 이메일 중복·나이 초과·개수 제한이 전부
      // 사용자가 고칠 수 있는 종류라 "실패했습니다"로 뭉개면 무엇을 고칠지 알 수 없다.
      _mapDioError(e, '자녀 계정을 만들지 못했습니다.');
    }
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '자녀 계정을 만들지 못했습니다.');
    }
    return ChildAccount.fromJson(apiRes.data!);
  }

  Future<void> deleteChild(int childId) async {
    try {
      await _dio.delete('/guardian/children/$childId');
    } on DioException catch (e) {
      _mapDioError(e, '자녀 계정을 삭제하지 못했습니다.');
    }
  }

  static String _yyyyMMdd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

/// 자녀 계정 목록. 생성·삭제 후 `ref.invalidate` 로 다시 읽는다.
final childrenProvider =
    FutureProvider.autoDispose<List<ChildAccount>>((ref) async {
  return ref.watch(guardianRepositoryProvider).getChildren();
});
