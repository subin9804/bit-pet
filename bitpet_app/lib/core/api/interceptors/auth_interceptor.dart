import 'package:dio/dio.dart';
import '../../auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthInterceptor(this._dio, this._tokenStorage);

  /// 진행 중인 토큰 갱신. 401 이 여러 개 동시에 나도 갱신은 **한 번만** 보내고 나머지는 이걸 기다린다.
  ///
  /// 서버는 갱신할 때마다 refresh 토큰을 새로 바꾼다(이전 것은 무효). 예전엔 요청마다 따로 갱신해서
  /// 첫 갱신이 토큰을 바꾸고 → 둘째가 옛 토큰으로 갱신하다 거부당해 → [TokenStorage.expireSession]
  /// 으로 **방금 받은 새 토큰까지 지우고 로그아웃**됐다. 배경에 있던 앱을 NFC 태그로 깨우면
  /// 태그 조회와 다른 화면 요청이 함께 401 을 받아 그대로 재현됐다 (2026-11-23 사용자 지적).
  Future<bool>? _refreshing;

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains('/auth/login') ||
        path.contains('/auth/signup') ||
        path.contains('/auth/refresh');

    if (err.response?.statusCode == 401 && !isAuthEndpoint) {
      try {
        if (await _ensureFreshToken(err.requestOptions)) {
          final token = await _tokenStorage.getAccessToken();
          err.requestOptions.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(err.requestOptions);
          return handler.resolve(response);
        }
      } catch (_) {}
      // 갱신도 실패 = 세션이 끝났다. 지우기만 하면 화면이 그대로 남아
      // "로그인은 되어 있는데 아무것도 안 되는" 상태가 되므로 앱에 알린다.
      await _tokenStorage.expireSession();
    }
    handler.next(err);
  }

  /// 이 요청이 실어 보낸 토큰보다 새 토큰이 이미 있으면(다른 요청이 갱신을 끝냄) 그걸로 다시 보내고,
  /// 아니면 갱신을 하나로 묶어 기다린다.
  Future<bool> _ensureFreshToken(RequestOptions options) async {
    final current = await _tokenStorage.getAccessToken();
    if (current != null &&
        options.headers['Authorization'] != 'Bearer $current') {
      return true;
    }
    final inFlight = _refreshing ??=
        _refreshToken().whenComplete(() => _refreshing = null);
    return inFlight;
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) return false;

    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    if (response.statusCode == 200) {
      final data = response.data['data'] as Map<String, dynamic>;
      await _tokenStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    }
    return false;
  }
}
