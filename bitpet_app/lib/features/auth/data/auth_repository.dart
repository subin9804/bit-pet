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
    // API 응답: data 루트에 accessToken/refreshToken 직접 위치
    final tokenData = data.containsKey('accessToken')
        ? data
        : data['tokens'] as Map<String, dynamic>;
    final tokens = AuthTokens.fromJson(tokenData);
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    if (data.containsKey('user')) {
      return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    }
    // 로그인 응답에 user 정보 없을 경우 최소 프로필 반환 (/auth/me 연동 시 교체)
    return UserProfile(id: 0, email: request.email, name: '', userType: 'GENERAL');
  }

  Future<UserProfile> signup(SignupRequest request) async {
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
    final data = apiRes.data!;
    final tokenData = data.containsKey('accessToken')
        ? data
        : data['tokens'] as Map<String, dynamic>;
    final tokens = AuthTokens.fromJson(tokenData);
    await _tokenStorage.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    if (data.containsKey('user')) {
      return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    }
    return UserProfile(id: 0, email: request.email, name: request.name, userType: 'GENERAL');
  }

  Future<void> logout() async {
    try {
      await _dio.delete('/auth/logout');
    } finally {
      await _tokenStorage.clearTokens();
    }
  }

  Future<void> withdraw() async {
    await _dio.delete('/auth/withdraw');
    await _tokenStorage.clearTokens();
  }

  Future<bool> get isLoggedIn => _tokenStorage.hasToken;
}
