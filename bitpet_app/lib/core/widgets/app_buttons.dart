import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
          borderRadius: BorderRadius.zero,
        ),
        child: Icon(
          forward ? Icons.chevron_right : Icons.chevron_left,
          size: 18,
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
              borderRadius: BorderRadius.zero,
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
