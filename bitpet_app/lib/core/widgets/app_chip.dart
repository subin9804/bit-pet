import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 공용 선택 칩 — 직사각형(라운드 없음), 필터·옵션 선택에 사용.
/// 앱 전체 칩은 이 위젯만 사용한다 (스타일 변경 시 여기 한 곳만 수정).
///
/// 기본: 선택 시 primary 배경 + 흰 글자, 미선택 시 card 배경 + paleLine 테두리.
/// 화면 톤에 따라 selectedColor/selectedTextColor/selectedBorderColor만 덮어쓴다.
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
    final bg = selected ? (selectedColor ?? AppColors.primary) : AppColors.card;
    final fg = selected
        ? (selectedTextColor ?? Colors.white)
        : AppColors.paleInk2;
    final borderColor = selected
        ? (selectedBorderColor ?? Colors.transparent)
        : AppColors.paleLine;

    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: padding,
      margin: margin,
      alignment: centered ? Alignment.center : null,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.zero,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: fg,
              )),
          if (count != null) ...[
            const SizedBox(width: 5),
            Text('$count',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? fg.withValues(alpha: 0.6)
                      : AppColors.paleInk3,
                )),
          ],
        ],
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}
