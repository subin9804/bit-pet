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

  Future<bool> get hasToken async =>
      _memAccessToken != null ||
      await _storage.read(key: _kAccessToken) != null;
}
