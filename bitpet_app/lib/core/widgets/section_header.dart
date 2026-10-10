import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';

/// 섹션 제목 한 줄. 제목 + (선택) 오른쪽 동작 하나.
///
/// 지금까지는 화면마다 `Row(Text(..., style: paleSectionTitle), Spacer(), TextButton(...))`
/// 를 직접 짜서 **제목과 '더 보기' 사이 간격이 화면마다 달랐다.** 여기로 모은다.
///
/// ⛔ 오른쪽에 동작을 두 개 두지 말 것. 섹션 제목은 길잡이지 도구 모음이 아니다.
class SectionHeader extends StatelessWidget {
  final String title;

  /// 제목 옆 작은 수 (`3/5`, `12마리`). 제목과 같은 무게로 읽히면 안 되므로 흐리게 둔다.
  final String? count;

  /// 오른쪽 동작. 라벨만 주면 글자 버튼, [actionIcon] 까지 주면 아이콘이 뒤에 붙는다.
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.titleGap),
      child: Row(
        children: [
          Flexible(
            child: Text(title,
                style: AppTextStyles.subheading, overflow: TextOverflow.ellipsis),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpacing.sm),
            Text(count!, style: AppTextStyles.caption),
          ],
          const Spacer(),
          if (actionLabel != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: AppRadius.brSm,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(actionLabel!,
                        style: AppTextStyles.caption.copyWith(
                            color: AppColors.brandAction,
                            fontWeight: FontWeight.w600)),
                    if (actionIcon != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Icon(actionIcon,
                          size: AppIconSize.sm, color: AppColors.brandAction),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
