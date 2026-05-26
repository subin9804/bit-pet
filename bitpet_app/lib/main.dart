import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/db/app_database.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 폰트를 네트워크에서 다운로드하지 않음 — 오프라인/에뮬레이터 DNS 실패 방지
  // 앱 번들에 폰트 파일이 없으면 시스템 기본 폰트로 대체됨 (크래시 없음)
  GoogleFonts.config.allowRuntimeFetching = false;
  final db = AppDatabase();
  runApp(
    ProviderScope(
      overrides: [
        dbProvider.overrideWithValue(db),
      ],
      child: const BitPetApp(),
    ),
  );
}

class BitPetApp extends ConsumerWidget {
  const BitPetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'bit-pet',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
