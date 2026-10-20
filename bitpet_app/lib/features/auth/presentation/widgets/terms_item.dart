import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_icons.dart';

// 약관 동의 행. 회원가입 3단계와 소셜 가입 직후 동의 화면이 같이 쓴다 —
// 두 화면에서 체크 모양이 다르면 같은 약관을 다른 걸로 읽는다.

class TermsItem extends StatelessWidget {
  final String label;
  final bool checked;
  final String? badge;
  final bool isBold;
  final bool hasBorder;
  final bool isLast;
  final VoidCallback onTap;

  /// 전문 보기. null 이면 화살표를 아예 그리지 않는다 ('전체 동의'가 그렇다).
  final VoidCallback? onView;

  const TermsItem({
    super.key,
    required this.label,
    required this.checked,
    required this.onTap,
    this.onView,
    this.badge,
    this.isBold = false,
    this.hasBorder = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.brMd,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          // 전엔 두 갈래가 `paleLine`/`paleLineSoft` 로 나뉘어 있었는데 두 별칭이
          // 같은 값(`line`)이라 결과가 똑같았다. 조건만 남겼다 — 마지막 줄만 선이 없다.
          border: (hasBorder || !isLast)
              ? const Border(bottom: BorderSide(color: AppColors.line))
              : null,
        ),
        child: Row(
          children: [
            TermsCheckbox(checked: checked, large: isBold),
            const SizedBox(width: 8),
            Expanded(
              child: Row(
                children: [
                  if (badge != null) ...[
                    Text(
                      '[$badge]',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: badge == '필수'
                            ? AppColors.error
                            : AppColors.ink3,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 화살표는 행과 별개의 탭 타겟이다 — 여기를 누르면 체크가 아니라 전문이 열린다.
            // 손가락으로 닿을 만한 크기를 주려고 아이콘 주변에 패딩을 깐다.
            if (onView != null)
              InkWell(
                onTap: onView,
                borderRadius: AppRadius.brMd,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '보기',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink2,
                          decoration: TextDecoration.underline,
                          decorationColor: AppColors.ink3,
                        ),
                      ),
                      SizedBox(width: 4),
                      AppIcon(AppIcons.chevronRight,
                          size: 16, color: AppColors.ink3),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class TermsCheckbox extends StatelessWidget {
  final bool checked;
  final bool large;
  const TermsCheckbox({super.key, required this.checked, this.large = false});

  @override
  Widget build(BuildContext context) {
    final size = large ? 22.0 : 18.0;
    final radius = large ? 6.0 : 9.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: checked ? AppColors.brandAction : AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: checked ? AppColors.brandAction : AppColors.line,
          width: 1.5,
        ),
      ),
      child: checked
          ? Icon(Icons.check, size: size * 0.65, color: Colors.white)
          : null,
    );
  }
}
