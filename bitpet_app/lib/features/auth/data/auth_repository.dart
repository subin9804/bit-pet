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
  Future<UserProfile> login(LoginRequest request) async {
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
    );
    // TokenResponse에 유저 정보 없음 → 최소 프로필 반환 (추후 /auth/me 연동)
    return UserProfile(
      id: 0,
      email: request.email,
      name: '',
      userType: 'GENERAL',
    );
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
