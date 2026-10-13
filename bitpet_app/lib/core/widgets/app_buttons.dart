import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';

/// 공용 좌우 이동(chevron) 버튼 — 32×32 직사각형 테두리.
/// 날짜·페이지 네비게이션에 사용. 스타일 변경 시 여기 한 곳만 수정.
class AppNavButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool forward;

  const AppNavButton({super.key, required this.onTap, this.forward = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        margin: EdgeInsets.only(right: forward ? 0 : 8, left: forward ? 8 : 0),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.paleLine),
          borderRadius: AppRadius.brMd,
        ),
        child: Icon(
          forward ? Icons.chevron_right : Icons.chevron_left,
          size: 20,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// 스테퍼(수량 증감) 버튼 스타일.
/// - [inline]: 테두리 컨테이너 안에서 좌우 끝에 배치 (중앙 방향 측면 테두리만)
/// - [boxed]: 사방 테두리 + card 배경의 소형 버튼
/// - [plain]: 테두리 없는 큰 터치 영역
enum AppStepperStyle { inline, boxed, plain }

/// 공용 스테퍼(수량 증감) 버튼. 스타일 변경 시 여기 한 곳만 수정.
class AppStepperButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppStepperStyle style;

  const AppStepperButton(
    this.label, {
    super.key,
    required this.onTap,
    this.style = AppStepperStyle.inline,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case AppStepperStyle.inline:
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 44,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                right: label == '−'
                    ? const BorderSide(color: AppColors.paleLine)
                    : BorderSide.none,
                left: label == '+'
                    ? const BorderSide(color: AppColors.paleLine)
                    : BorderSide.none,
              ),
            ),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
        );
      case AppStepperStyle.boxed:
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 36,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.paleLine),
              borderRadius: AppRadius.brMd,
            ),
            child: Text(label,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
        );
      case AppStepperStyle.plain:
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
          ),
        );
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// 공용 액션 버튼 — **누르는 자리의 색은 여기서만 정한다**
//
// 화면마다 `GestureDetector` + `Container(color: ...)` 로 버튼을 직접 그려서,
// 테마를 한 번 바꿀 때마다 수십 군데를 하나씩 찾아 고쳐야 했다. 스텝 폼 푸터만
// 먹색(`primary`)으로 남아 있던 것도 같은 이유다 — 규칙은 "누르는 자리는
// 브랜드색"인데 규칙을 담을 곳이 없었다.
//
// 그래서 **색·비활성색·눌림색·높이·반경·로딩 표시를 이 한 클래스가 갖는다.**
// 새 버튼은 여기서 만들고, 기존 수제 버튼은 보이는 대로 이걸로 바꾼다.
//
// ⛔ 호출처에서 색을 직접 넘기지 말 것. 톤이 모자라면 [AppButtonTone] 을 늘린다.
// ℹ️ 비활성은 회색이 아니라 **연한 브랜드색**(`brandTint`)이다 — '못 누른다'가
//   아니라 '아직 덜 채웠다'는 뜻이라서, 완성되면 같은 색이 진해지며 켜진다.
// ════════════════════════════════════════════════════════════════════════════

enum AppButtonTone {
  /// 화면의 주 행동 — 저장·다음·확인. 브랜드 초록.
  brand,

  /// 주 행동 옆에 서는 보조 행동 — 이전·취소. 흰 면 + 테두리.
  neutral,

  /// 되돌릴 수 없는 행동 — 삭제·탈퇴.
  danger,
}

class AppActionButton extends StatelessWidget {
  final String label;

  /// null 이면 비활성. (`enabled` 플래그를 따로 두지 않는다 — 두 군데서
  /// 관리하면 '눌리는데 아무 일도 없는' 버튼이 생긴다.)
  final VoidCallback? onPressed;

  final AppButtonTone tone;

  /// 처리 중 — 라벨 대신 스피너를 돌리고 입력을 막는다.
  final bool loading;

  /// 라벨 왼쪽 아이콘 (완료 버튼의 체크 등).
  final IconData? icon;

  final double height;
  final BorderRadius radius;

  const AppActionButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.tone = AppButtonTone.brand,
    this.loading = false,
    this.icon,
    this.height = 52,
    this.radius = AppRadius.brMd,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;

    final (Color bg, Color fg, Color? line) = switch (tone) {
      AppButtonTone.brand => enabled
          ? (AppColors.brandAction, Colors.white, null)
          : (AppColors.brandTint, AppColors.brandTintInk, null),
      AppButtonTone.neutral => (
          AppColors.card,
          enabled ? AppColors.ink : AppColors.ink3,
          AppColors.line,
        ),
      AppButtonTone.danger => enabled
          ? (AppColors.error, Colors.white, null)
          : (AppColors.card, AppColors.ink3, AppColors.line),
    };

    return SizedBox(
      height: height,
      child: Material(
        color: bg,
        borderRadius: radius,
        // 비활성·로딩 중엔 그림자도 뺀다 — 뜬 면은 '밟을 수 있다'는 뜻이다.
        elevation: 0,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: radius,
          overlayColor: WidgetStatePropertyAll(
            tone == AppButtonTone.brand
                ? AppColors.brandPressed.withValues(alpha: 0.35)
                : AppColors.line,
          ),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: line == null
                  ? null
                  : Border.fromBorderSide(BorderSide(color: line)),
            ),
            child: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: fg),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 16, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: fg),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
