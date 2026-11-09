import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/db/app_database.dart';
import 'core/mock/mock_config.dart';
import 'core/mock/mock_repositories.dart';
import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/update/force_update.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 실패(설정 누락 등)가 앱 기동 자체를 막지 않도록 격리한다.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    _setUpCrashlytics();
  } catch (e) {
    debugPrint('[FCM] Firebase 초기화 실패 — 푸시 없이 실행: $e');
  }

  final db = AppDatabase();
  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
        if (kMockMode) ...buildMockOverrides(),
      ],
      child: const TailogApp(),
    ),
  );
}

class TailogApp extends ConsumerWidget {
  const TailogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'tailog',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      // 최소 버전 미만이면 라우터 화면 대신 업데이트 안내만 보인다 (core/update)
      builder: (context, child) =>
          ForceUpdateGate(child: child ?? const SizedBox.shrink()),
      debugShowCheckedModeBanner: false,
      // 기기 언어가 한국어면 한국어, 영어면 영어. 둘 다 아니면 첫 항목(한국어)으로 떨어진다 —
      // 앱 본문 문구가 전부 한국어라 모달만 제3언어로 뜨는 것보다 낫다.
      supportedLocales: const [Locale('ko', 'KR'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

/// 크래시 수집 (2026-11-09). Firebase 가 뜬 뒤에만 부른다 — iOS 처럼 Firebase 설정이 없는
/// 플랫폼에서는 초기화가 실패해 여기까지 오지 않는다.
///
/// 디버그 빌드는 보내지 않는다. 개발 중 핫리로드 예외가 콘솔을 덮으면 진짜 크래시가 묻힌다.
void _setUpCrashlytics() {
  final crashlytics = FirebaseCrashlytics.instance;
  crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

  // 위젯 빌드·레이아웃 중 예외 — 화면은 살아 있는 경우가 많아 non-fatal 로 남긴다
  FlutterError.onError = crashlytics.recordFlutterError;
  // 비동기 콜백 등 프레임워크 밖에서 새어 나온 예외
  PlatformDispatcher.instance.onError = (error, stack) {
    crashlytics.recordError(error, stack, fatal: true);
    return true;
  };
}
