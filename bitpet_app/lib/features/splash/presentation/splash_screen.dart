import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/ui_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';

/// 앱을 켜고 **토큰을 확인하는 동안** 머무는 화면.
///
/// 이 화면이 없던 동안은 `/home` 으로 바로 들어갔고, 그 순간
/// `authStateProvider` 는 아직 `loading` 이라 라우터가 로그인 상태를 `false` 로
/// 읽었다. 그래서 **로그인해 둔 사람에게도 로그인 화면이 한 번 번쩍였다** —
/// 앱을 켤 때마다 "로그아웃됐나?" 하게 되는 종류의 깜빡임이다.
///
/// 행선지는 세 갈래다: 로그인되어 있으면 홈(라우터가 보낸다), 아니면
/// 소개를 본 적 있으면 로그인, 처음이면 소개.
///
/// ⛔ 여기에 네트워크 요청을 더 붙이지 말 것. 스플래시가 길어지는 건 그 자체로
///    "앱이 느리다"로 읽히고, 토큰 확인 외의 것은 다 홈에서 해도 된다.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  ProviderSubscription<AsyncValue<dynamic>>? _sub;

  /// 한 번만 떠난다. 토큰 확인이 빨리 끝나면 리스너가 즉시 두 번 불릴 수 있는데,
  /// 그때 `go` 를 두 번 하면 라우터 스택이 어긋난다.
  bool _left = false;

  /// **최소 노출 시간.** 토큰이 로컬에만 있으면 확인이 수십 ms 로 끝나서
  /// 로고가 한 프레임 번쩍이고 사라진다 — 깜빡임이 없는 것보다 나쁘다.
  late final Future<void> _minHold =
      Future.delayed(const Duration(milliseconds: 420));

  @override
  void initState() {
    super.initState();
    _sub = ref.listenManual<AsyncValue<dynamic>>(
      authStateProvider,
      (_, next) {
        if (!next.isLoading) _decide();
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }

  Future<void> _decide() async {
    if (_left) return;
    _left = true;

    await _minHold;
    if (!mounted) return;

    // 로그인 상태면 라우터의 redirect 가 이미 홈으로 보낸다. 여기서 또
    // `go('/home')` 하지 않는다 — 두 곳이 같은 판단을 하면 나중에 한쪽만 고쳐진다.
    if (ref.read(authStateProvider).valueOrNull != null) return;

    final seen =
        await ref.read(uiPrefsProvider).readBool(UiPrefKeys.introSeen) ?? false;
    if (!mounted) return;
    context.go(seen ? '/login' : '/intro');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로그인 화면과 **같은 로고·같은 크기**다. 다르면 스플래시에서
            // 로그인으로 넘어갈 때 로고가 한 번 튄다.
            Image.asset(
              'assets/branding/login_main.png',
              width: 180,
              filterQuality: FilterQuality.medium,
              semanticLabel: 'tailog',
            ),
            const SizedBox(height: 8),
            Text('기록이 쌓이는 사육 일지', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
