// 화면이 깨졌을 때 빨간·회색 오류 화면 대신 안내 창 (2026-11-18).
//
// 위젯 빌드 중 예외(ErrorWidget)와 없는 경로(GoRouter errorBuilder) 두 곳에서 부른다.
// 깨진 자리는 빈 칸으로 그리고, 안내 창의 '확인'을 누르면 이전 화면으로 돌아간다.
// 예외 자체는 그대로 FlutterError.onError → Crashlytics 로 간다 — 여기서 삼키지 않는다.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 라우터의 루트 Navigator. 깨진 위젯의 context 는 곧 사라질 수 있어 안내 창은 여기에 띄운다.
final rootNavigatorKey = GlobalKey<NavigatorState>();

bool _showing = false;

/// 깨진 화면 대신 그릴 것. 빌드 중에 창을 띄울 수 없어 다음 프레임에 띄운다.
Widget appErrorPlaceholder() {
  showAppErrorDialog();
  return const SizedBox.shrink();
}

/// 한 번에 한 창만 — 깨진 화면은 여러 위젯이 연달아 예외를 던진다.
void showAppErrorDialog() {
  if (_showing) return;
  _showing = true;
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null) {
      _showing = false;
      return;
    }
    await showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        title: const Text('문제가 생겼어요'),
        content: const Text(
            '화면을 표시하는 중 오류가 발생했어요.\n'
            '마이페이지 > 개발자에게 문의하기 메뉴로 오류 내용을 전달해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
    _showing = false;
    if (!ctx.mounted) return;
    final router = GoRouter.of(ctx);
    if (router.canPop()) {
      router.pop();
    } else if (router.routeInformationProvider.value.uri.path != '/home') {
      // 돌아갈 화면이 없으면 홈으로. 홈 자체가 깨졌으면 그대로 둔다(무한 반복 방지)
      router.go('/home');
    }
  });
}
