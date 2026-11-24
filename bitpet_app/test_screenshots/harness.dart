// 화면 스크린샷 검수 하네스 — 기기·APK 없이 PC 에서 화면을 그려 PNG 로 남긴다.
//
// 실행: flutter test test_screenshots --update-goldens
//   → test_screenshots/out/*.png (gitignore). 비교용 골든이 아니라 **눈으로 보는 용도**라
//     항상 --update-goldens 로 돌린다. 그래서 일반 `flutter test`(test/)와 폴더를 나눴다.
//
// 기본 크기는 390×844 논리 픽셀 · DPR 3 (= 1170×2532, 스토어 스크린샷 비율에 가깝다).
//
// 스토어·랜딩 후보 (기능이 한눈에 드러나는 컷): community_feed, pet_list, nfc_profile_owner,
// pet_list_selecting. 지금 표본엔 사진이 없어 자리만 회색으로 나온다 — 게시용으로 쓸 땐
// 실제 사진 URL 대신 에셋 이미지를 넣는 표본을 따로 만들 것.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bitpet_app/core/theme/app_theme.dart';

const kPhone = Size(390, 844);

bool _fontsLoaded = false;

/// 테스트 기본 글꼴(Ahem)은 글자를 네모로 그린다 — 앱 글꼴과 아이콘 글꼴을 직접 올린다.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) return;
  final pretendard = FontLoader('Pretendard');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    pretendard.addFont(rootBundle.load('assets/fonts/Pretendard-$w.otf'));
  }
  await pretendard.load();
  _mockPlatform();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
  _fontsLoaded = true;
}

/// 기기 플러그인 대역. 보안 저장소는 비어 있고(토큰 없음), 사진 캐시는 임시 폴더를 쓴다.
/// 네트워크 사진은 테스트 환경에서 400 으로 떨어져 각 화면의 대체 그림이 나온다.
void _mockPlatform() {
  final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  m.setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (_) async => null);
  final tmp = Directory.systemTemp.createTempSync('shots').path;
  m.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'), (_) async => tmp);
}

/// [child] 를 앱 테마로 감싸 폰 크기로 그리고 out/[name].png 로 저장한다.
/// [pushed] 면 앞에 빈 화면을 하나 깔아 뒤로가기 버튼이 나오게 한다.
Future<void> shot(
  WidgetTester tester,
  String name,
  Widget child, {
  List<Override> overrides = const [],
  Size size = kPhone,
  bool pushed = false,
  Future<void> Function(WidgetTester)? before,
}) async {
  await loadAppFonts();
  tester.view.physicalSize = size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      // pushed: 앞 화면 위에 띄운 상태 — 뒤로가기 버튼이 실제처럼 보인다
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => child),
      onGenerateInitialRoutes: (_) => [
        if (pushed) MaterialPageRoute(builder: (_) => const SizedBox()),
        MaterialPageRoute(builder: (_) => child),
      ],
    ),
  ));
  // 무한 애니메이션(스켈레톤 등)이 있으면 pumpAndSettle 이 안 끝난다 — 고정 시간만 흘린다
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (before != null) await before(tester);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('out/$name.png'),
  );
}
