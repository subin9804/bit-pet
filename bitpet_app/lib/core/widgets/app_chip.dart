import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 공용 선택 칩 — **알약**. 필터·옵션 선택에 쓴다.
/// 앱 전체 칩은 이 위젯만 사용한다 (스타일 변경 시 여기 한 곳만 수정).
///
/// 기본: 선택 시 **브랜드 틴트 배경 + 진초록 글자 + 초록 테두리**,
/// 미선택 시 흰 배경 + 연한 테두리.
/// 화면 톤에 따라 selectedColor/selectedTextColor/selectedBorderColor만 덮어쓴다.
///
/// ⚠️ 기본값이 `primary`(= 초록이 아니라 **먹색**) 채움 + 흰 글자였다. 필터 바에서
/// 고른 칩이 검게 찍혀 "이 칩이 비활성"처럼도 보였고, 앱의 다른 선택 표시
/// (급여 시트의 칩·토글)와 색 체계가 아예 달랐다. 선택은 한 가지 색으로 말한다.
///
/// ⚠️ 모서리는 brMd(12) 직각에 가까운 사각이었다. 카드·시트·버튼·알림 배지까지
/// 전부 둥근 화면에서 칩만 각이 서 있어 옛 테마의 잔재로 보였다.
class AppChip extends StatelessWidget {
  /// 가로 스크롤 필터칩 바(row)의 표준 높이.
  /// 칩을 `SizedBox(height: ...)` + 좌우 스크롤 ListView로 배치할 때 이 값을 쓴다.
  /// (부모 높이가 칩 내용보다 작으면 글자가 잘리므로, 화면마다 값을 두지 말고 여기서 관리.)
  static const double barHeight = 52;

  final String label;
  final bool selected;

  /// null이면 GestureDetector를 만들지 않는다 (외부에서 탭 처리하는 경우).
  final VoidCallback? onTap;

  /// 라벨 우측에 표시할 카운트 (필터칩 용도).
  final int? count;

  final Color? selectedColor;       // 선택 시 배경 (기본 primary)
  final Color? selectedTextColor;   // 선택 시 글자색 (기본 white)
  final Color? selectedBorderColor; // 선택 시 테두리 (기본 없음)

  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// true면 가로로 주어진 공간을 채우고 라벨을 중앙 정렬 (Expanded 안에서 사용).
  final bool centered;

  const AppChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.count,
    this.selectedColor,
    this.selectedTextColor,
    this.selectedBorderColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.margin,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg =
        selected ? (selectedColor ?? AppColors.brandTint) : AppColors.surface;
    final fg = selected
        ? (selectedTextColor ?? AppColors.brandTintInk)
        : AppColors.ink2;
    // 틴트는 흰 칩과 명도 차가 작아, 테두리까지 초록으로 가야 한 줄에
    // 늘어선 칩들 사이에서 고른 것이 바로 잡힌다.
    final borderColor = selected
        ? (selectedBorderColor ?? AppColors.brandAction)
        : AppColors.line;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding,
      margin: margin,
      alignment: centered ? Alignment.center : null,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor),
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: AppTextStyles.caption.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              )),
          if (count != null) ...[
            const SizedBox(width: 4),
            Text('$count',
                style: AppTextStyles.mono(12, FontWeight.w700,
                    color: selected
                        ? fg.withValues(alpha: 0.6)
                        : AppColors.ink3)),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}
