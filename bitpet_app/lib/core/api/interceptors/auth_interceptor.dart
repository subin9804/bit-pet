import 'package:dio/dio.dart';
import '../../auth/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthInterceptor(this._dio, this._tokenStorage);

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
        final refreshed = await _refreshToken();
        if (refreshed) {
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
