import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// 접이식 선택 섹션 — 다이얼로그를 컴팩트하게 유지하고 탭 시 펼침.
/// 01c 일괄 완료 / 01d 개별 완료 확인 시트에서 공유한다.
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
      margin: const EdgeInsets.only(top: 10),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
              child: Row(
                children: [
                  if (label.isNotEmpty) ...[
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary, letterSpacing: -0.2)),
                    if (optional) ...[
                      const SizedBox(width: 7),
                      Text('OPTIONAL',
                          style: AppTextStyles.mono(9, FontWeight.w700,
                              color: AppColors.textDisabled)),
                    ],
                  ],
                  const Spacer(),
                  if (summary != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 9),
                      child: Text(
                        summary!,
                        style: TextStyle(
                            fontSize: 11.5, fontWeight: FontWeight.w700,
                            color: summaryActive
                                ? AppColors.textPrimary
                                : AppColors.textDisabled),
                      ),
                    ),
                  AnimatedRotation(
                    turns: open ? 0.25 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textDisabled),
                  ),
                ],
              ),
            ),
          ),
          if (open)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: child,
            ),
        ],
      ),
    );
  }
}
