import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 3단계 진행 바. 홈 화면 루틴카드 하단 페이지 인디케이터와 동일한 디자인
/// (직사각형 bar, 라운드 없음). 현재 단계(step)는 18×4 와이드 바, 완료=다크, 미도달=paleLine.
/// step: 1·2·3 (1=첫 단계)
class StepDots extends StatelessWidget {
  final int step;

  const StepDots({super.key, required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [1, 2, 3].map((i) {
        final active = i == step;
        final done   = i < step;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width:  active ? 18 : 6,
          height: 4,
          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
          color: (active || done) ? AppColors.primary : AppColors.paleLine,
        );
      }).toList(),
    );
  }
}
