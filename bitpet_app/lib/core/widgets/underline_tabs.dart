// 지금 보고 있는 페이지를 가리키는 탭.
//
// 알약(세그먼트)은 **설정**의 모양이다 — 개체 목록의 1열/2열 토글처럼 "무엇을
// 고를까"를 묻는 자리에 쓴다. 화면을 갈아타는 탭은 글자 폭만큼 밑줄 3px 이다
// (개체 상세의 기록/통계 탭과 같은 문법).

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

class AppUnderlineTabs extends StatelessWidget {
  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  /// 화면 거터. **바깥에서 Padding 으로 감싸지 말 것** — 그러면 아래 구분선도
  /// 같이 들여써져 선이 화면을 가로지르지 못하고 공중에 뜬 토막이 된다.
  /// 거터를 빼먹고 감싸지도 않으면 탭이 화면 왼쪽 끝에 달라붙는다(실제로 그랬다).
  final double horizontalPadding;

  const AppUnderlineTabs({
    super.key,
    required this.labels,
    required this.index,
    required this.onChanged,
    this.horizontalPadding = AppSpacing.xl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: EdgeInsets.only(
                  right: i == labels.length - 1 ? 0 : AppSpacing.xl),
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: IntrinsicWidth(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                        child: Text(
                          labels[i],
                          style: AppTextStyles.subheading.copyWith(
                            fontWeight: i == index
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: i == index
                                ? AppColors.ink
                                : AppColors.ink3,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        height: 3,
                        decoration: BoxDecoration(
                          color: i == index
                              ? AppColors.brandAction
                              : Colors.transparent,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(2)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
