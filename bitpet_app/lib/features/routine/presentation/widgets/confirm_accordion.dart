import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_icons.dart';

/// 접이식 선택 섹션 — 시트를 짧게 유지하고 탭 시 펼친다.
/// 루틴 '모두 완료' / '개체별 완료' 시트가 공유한다.
///
/// 연회색 시트 바탕 위의 **흰 카드**다. 화면의 카드와 같은 면 관계다.
///
/// ⚠️ 한때 `onCanvas` 플래그로 바탕색을 호출자가 정했다 — "흰 시트 위에서는
/// 회색, 회색 시트 위에서는 흰색"이라는 규칙이었는데, 시트마다 바탕이 달랐던
/// 그 시절의 잔재다. [AppSheet] 바탕이 전부 `canvas` 로 통일된 뒤로는 판단할
/// 게 없어져 플래그를 지웠다. ⛔ 되살리지 말 것 — 되살리는 순간 시트 바탕이
/// 다시 갈라진다.
class ConfirmAccordion extends StatelessWidget {
  final String label;
  final bool optional;
  final String? summary;
  final bool summaryActive;
  final bool open;
  final VoidCallback onToggle;
  final Widget child;

  const ConfirmAccordion({
    super.key,
    required this.label,
    this.optional = false,
    this.summary,
    this.summaryActive = false,
    required this.open,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: AppRadius.brMd,
        border: const Border.fromBorderSide(
            BorderSide(color: AppColors.line)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  if (label.isNotEmpty) ...[
                    Text(label, style: AppTextStyles.subheading),
                    if (optional) ...[
                      const SizedBox(width: AppSpacing.sm),
                      // 'OPTIONAL' 9px mono 였다. 9px 는 본문 최소(12px)에 한참
                      // 못 미치고, 한글 화면에 영문 라벨만 섞여 튀었다.
                      Text('선택', style: AppTextStyles.label),
                    ],
                  ],
                  const Spacer(),
                  if (summary != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        summary!,
                        style: AppTextStyles.label.copyWith(
                            color: summaryActive
                                ? AppColors.ink
                                : AppColors.ink3),
                      ),
                    ),
                  AnimatedRotation(
                    turns: open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const AppIcon(AppIcons.chevronRight,
                        size: AppIconSize.md, color: AppColors.ink3),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.xl),
              child: child,
            ),
        ],
      ),
    );
  }
}
