import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/db/ui_prefs.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_text_styles.dart';

/// 소개 3장. **처음 켰을 때 한 번만** 뜬다.
///
/// 세 장인 이유는 이 앱이 하는 일이 세 개이기 때문이다 — 기록을 쌓고, 오늘 할
/// 일을 챙기고, 이름표로 바로 연다. ⛔ 장을 늘리지 말 것. 넷째 장이 생기는
/// 순간 사람들은 전부 '건너뛰기'를 누르고, 그러면 세 장도 못 읽힌다.
///
/// ⛔ **여기서 권한을 요청하지 말 것** (알림·카메라·NFC). 왜 필요한지 모르는
///    시점에 묻는 권한은 거절된다. 알림은 루틴을 처음 만들 때, 나머지는 쓰는
///    자리에서 묻는다.
class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  final _pages = PageController();
  int _index = 0;

  static const _slides = <_Slide>[
    _Slide(
      icon: Icons.menu_book_outlined,
      title: '개체마다 기록이 쌓여요',
      body: '급여·체중·탈피를 개체별로 모읍니다.\n'
          '흩어진 메모 대신 한 줄로 이어진 이력이 남아요.',
    ),
    _Slide(
      icon: Icons.task_alt,
      title: '오늘 챙길 것만 보여줘요',
      body: '홈에 오늘의 루틴만 올라옵니다.\n'
          '한 번 누르면 완료 기록까지 같이 남아요.',
    ),
    _Slide(
      icon: Icons.nfc,
      title: '이름표를 찍으면 바로 열려요',
      body: '사육장에 붙인 tailog 이름표를 폰에 대면\n'
          '그 개체의 화면이 바로 열립니다.',
    ),
  ];

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _isLast => _index == _slides.length - 1;

  /// 소개를 봤다고 적고 로그인으로 보낸다.
  ///
  /// 저장 실패는 무시한다 — 최악이 "다음에 소개를 한 번 더 본다"이고,
  /// 그걸 막겠다고 여기서 에러를 띄우면 앱의 첫 화면이 에러가 된다.
  Future<void> _finish() async {
    await ref.read(uiPrefsProvider).writeBool(UiPrefKeys.introSeen, true);
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _pages.nextPage(
          duration: const Duration(milliseconds: 240), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            // 건너뛰기는 **첫 장부터 늘 같은 자리**에 있다. 마지막 장에서만
            // 사라지게 하면 그 순간 아래 버튼이 한 칸 올라와 덜컥인다.
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    0, AppSpacing.sm, AppSpacing.sm, 0),
                child: TextButton(
                  onPressed: _isLast ? null : _finish,
                  child: Text(
                    _isLast ? '' : '건너뛰기',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
              ),
            ),
            _Dots(count: _slides.length, index: _index),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_isLast ? '시작하기' : '다음'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Slide {
  final IconData icon;
  final String title;
  final String body;

  const _Slide({required this.icon, required this.title, required this.body});
}

class _SlideView extends StatelessWidget {
  final _Slide slide;

  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 장식이라 [AppColors.brandIllust] 를 쓴다 (대비 2.76 — 글씨·의미
          // 전달 아이콘에는 쓸 수 없는 색이다). 뜻은 아래 제목이 전달한다.
          Container(
            width: 132,
            height: 132,
            decoration: const BoxDecoration(
              color: AppColors.brandTintSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(slide.icon, size: 56, color: AppColors.brandIllust),
          ),
          const SizedBox(height: AppSpacing.x32),
          Text(slide.title,
              style: AppTextStyles.screenTitle, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(slide.body,
              style: AppTextStyles.sub, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int index;

  const _Dots({required this.count, required this.index});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: i == index ? 20 : 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              // 현재 장만 알약으로 늘인다. 색만 다르게 하면 작은 점 두 개의
              // 명도 차이라 밝은 데서 안 보인다.
              color: i == index ? AppColors.brandAction : AppColors.border,
              borderRadius: AppRadius.brPill,
            ),
          ),
      ],
    );
  }
}
