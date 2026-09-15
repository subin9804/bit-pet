import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/db/app_database.dart';
import 'core/mock/mock_config.dart';
import 'core/mock/mock_repositories.dart';
import 'core/push/push_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  // Firebase 초기화 실패(설정 누락 등)가 앱 기동 자체를 막지 않도록 격리한다.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
