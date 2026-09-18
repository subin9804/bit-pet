import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kAccessToken = 'access_token';
const _kRefreshToken = 'refresh_token';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

class TokenStorage {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // 로그인 유지 OFF 시 메모리에만 보관 (앱 종료 시 사라짐)
  String? _memAccessToken;
  String? _memRefreshToken;
  bool _persistEnabled = true;

  /// [persist] = true  → secure storage 저장 (로그인 유지 ON)
  /// [persist] = false → 메모리에만 보관 (로그인 유지 OFF, 앱 종료 시 소멸)
  /// [persist] = null  → 기존 모드 유지 (토큰 자동 갱신 시 사용)
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    bool? persist,
  }) async {
    final shouldPersist = persist ?? _persistEnabled;
    _persistEnabled = shouldPersist;

    if (shouldPersist) {
      _memAccessToken = null;
      _memRefreshToken = null;
      await Future.wait([
        _storage.write(key: _kAccessToken, value: accessToken),
        _storage.write(key: _kRefreshToken, value: refreshToken),
      ]);
    } else {
      _memAccessToken = accessToken;
      _memRefreshToken = refreshToken;
    }
  }

  Future<String?> getAccessToken() async =>
      _memAccessToken ?? await _storage.read(key: _kAccessToken);

  Future<String?> getRefreshToken() async =>
      _memRefreshToken ?? await _storage.read(key: _kRefreshToken);

  Future<void> clearTokens() async {
    _memAccessToken = null;
    _memRefreshToken = null;
    _persistEnabled = true;
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
    ]);
  }

  /// 토큰 갱신까지 실패해 **세션이 끝났을 때** 부른다.
  ///
  /// [clearTokens] 와 갈라 둔 이유: 저장소를 비우는 것만으로는 화면이 따라오지
  /// 않는다. 라우터는 `authStateProvider` 를 보고 있는데 인터셉터는 Riverpod 을
  /// 모르기 때문에, 토큰이 사라진 뒤에도 앱은 로그인된 줄 알고 그 화면에 그대로
  /// 머문다 — 모든 요청이 401 로 조용히 실패하는 상태. 그래서 지우는 김에 알린다.
  ///
  /// 사용자가 직접 누른 로그아웃은 [AuthNotifier] 가 상태를 직접 바꾸므로
  /// 이 경로를 타지 않는다.
  Future<void> expireSession() async {
    await clearTokens();
    if (!_sessionExpired.isClosed) _sessionExpired.add(null);
  }

  final _sessionExpired = StreamController<void>.broadcast();

  /// 세션 만료 신호. 앱이 사는 동안 유지되는 스트림이라 닫지 않는다.
  Stream<void> get onSessionExpired => _sessionExpired.stream;

  Future<bool> get hasToken async =>
      _memAccessToken != null ||
      await _storage.read(key: _kAccessToken) != null;
}
