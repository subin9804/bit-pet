import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/token_storage.dart';
import 'interceptors/auth_interceptor.dart';

/// API 서버 주소 — **빌드 시점에** 주입한다.
///
/// ```bash
/// flutter run                                   # 기본값(localhost) — 개발
/// flutter build appbundle \
///     --dart-define=API_BASE_URL=https://tailog.me/api/v1
/// ```
///
/// `kReleaseMode` 로 분기하지 않는 이유: 그러면 **실기기에서 릴리즈 빌드로
/// 테스트할 방법이 사라진다**. NFC 딥링크처럼 릴리즈에서만 확인되는 것들이 있어
/// `flutter run --release` + `adb reverse` 조합을 계속 쓸 수 있어야 한다.
/// 주소는 빌드 환경의 문제이지 빌드 모드의 문제가 아니다.
///
/// ⚠️ 배포 빌드에 `--dart-define` 을 빠뜨리면 앱이 폰 자기 자신(`localhost`)을
/// 찾다가 **모든 요청이 실패**한다. 조용히 죽는 게 아니라 통째로 안 돈다.
///
/// 로컬 개발은 `adb reverse tcp:8080 tcp:8080` 을 먼저 실행할 것.
/// (`10.0.2.2` 는 Windows 방화벽에 막히는 경우가 있어 adb reverse 가 더 안정적)
const String kBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8080/api/v1',
);

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(dio, tokenStorage));
  return dio;
});
