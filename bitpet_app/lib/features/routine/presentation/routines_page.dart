import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'routine_screen.dart';
import '../../../core/theme/app_dimens.dart';

/// 루틴 탭 최상위 페이지 — BottomAppBar 탭에서 진입.
class RoutinesPage extends StatelessWidget {
  const RoutinesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        // ⚠️ 여기만 **흰 AppBar + 연회색 본문**이었다. 머리만 다른 색으로 떠서
        // 한 화면이 두 장으로 쪼개져 보인다 — '내 개체' 탭에서 같은 이유로
        // 이미 걷어낸 것이고, 이 화면이 마지막으로 남아 있었다.
        backgroundColor: AppColors.canvas,
        // 제목 위에 영문 소제목('routine', 12px/자간 1.5)이 얹혀 있었다.
        // 홈·내 개체에서 걷어낸 것과 같은 종류의 장식이다 — 두 줄짜리 제목이 되어
        // AppBar 만 높아지고 읽을 정보는 아래 한 줄뿐이다. 내비 라벨과 같은 말로.
        title: const Text('루틴 관리'),
        titleSpacing: AppSpacing.xl,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xl),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/routines/new'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('루틴 추가'),
              // 배경을 `AppColors.primary` 로 덮어써서 **검정 버튼**이 돼 있었다.
              // primary 는 브랜드색이 아니라 먹색 별칭이다 — 테마 기본값이 이미
              // brandAction 이므로 색·모양 지정을 지워 '내 개체'의 '추가'와 맞춘다.
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                textStyle:
                    AppTextStyles.caption.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      body: const RoutineScreen(),
    );
  }
}
