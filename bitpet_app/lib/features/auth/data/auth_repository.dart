import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_response.dart';
import '../../../core/auth/token_storage.dart';
import 'models/auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    dio: ref.watch(dioProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthRepository({required Dio dio, required TokenStorage tokenStorage})
      : _dio = dio,
        _tokenStorage = tokenStorage;

  // ── 로그인 ────────────────────────────────────────────────
  // 서버 응답: { success, data: { accessToken, refreshToken, tokenType } }
  Future<UserProfile> login(LoginRequest request, {bool keepLoggedIn = true}) async {
    final res = await _dio.post('/auth/login', data: request.toJson());
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '로그인에 실패했습니다.');
    }
    final data = apiRes.data!;
    await _tokenStorage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
      persist: keepLoggedIn,
    );
    return getMe();
  }

  // ── 내 정보 조회 (앱 재시작 시 프로필 복원) ──────────────
  Future<UserProfile> getMe() async {
    final res = await _dio.get('/auth/me');
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '사용자 정보를 불러올 수 없습니다.');
    }
    return UserProfile.fromJson(apiRes.data!);
  }

  // ── 이메일 중복확인 ───────────────────────────────────────
  Future<bool> checkEmailAvailable(String email) async {
    final res = await _dio.get('/auth/check-email', queryParameters: {'email': email});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '이메일 확인에 실패했습니다.');
    }
    return apiRes.data!['available'] as bool;
  }

  // ── 회원가입 ──────────────────────────────────────────────
  // 서버 흐름:
  //   1) POST /auth/signup → UserResponse (토큰 없음)
  //   2) POST /auth/login  → TokenResponse → 토큰 저장
  Future<UserProfile> signup(SignupRequest request) async {
    // 1. 회원가입
    final res = await _dio.post('/auth/signup', data: request.toJson());
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '회원가입에 실패했습니다.');
    }
    final userData = apiRes.data!;

    // 2. 자동 로그인 → 토큰 발급
    await login(LoginRequest(email: request.email, password: request.password));

    // 3. 가입 응답(UserResponse)으로 프로필 반환
    return UserProfile.fromJson(userData);
  }

  // ── 비밀번호 재설정 ───────────────────────────────────────
  // 1단계: 인증 코드 발송 (미가입 이메일이어도 서버는 정상 응답)
  Future<void> requestPasswordReset(String email) async {
    final res = await _dio.post('/auth/password-reset/request',
        data: {'email': email});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '인증 코드 발송에 실패했습니다.',
          errorCode: apiRes.errorCode);
    }
  }

  // 2단계: 코드 인증 → 비밀번호 변경용 토큰 반환
  Future<String> verifyResetCode(String email, String code) async {
    final res = await _dio.post('/auth/password-reset/verify',
        data: {'email': email, 'code': code});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success || apiRes.data == null) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '인증 코드 확인에 실패했습니다.',
          errorCode: apiRes.errorCode);
    }
    return apiRes.data!['token'] as String;
  }

  // 3단계: 새 비밀번호 저장
  Future<void> confirmPasswordReset(String token, String newPassword) async {
    final res = await _dio.post('/auth/password-reset/confirm',
        data: {'token': token, 'newPassword': newPassword});
    final apiRes = ApiResponse.fromJson(
      res.data as Map<String, dynamic>,
      (d) => d as Map<String, dynamic>,
    );
    if (!apiRes.success) {
      throw ApiException(
          statusCode: res.statusCode ?? 0,
          message: apiRes.message ?? '비밀번호 변경에 실패했습니다.',
          errorCode: apiRes.errorCode);
    }
  }

  // ── 로그아웃 ──────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _dio.delete('/auth/logout');
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  // ── 회원탈퇴 ──────────────────────────────────────────────
  Future<void> withdraw() async {
    await _dio.delete('/auth/withdraw');
    await _tokenStorage.clearTokens();
  }

  Future<bool> get isLoggedIn => _tokenStorage.hasToken;
}
