import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_buttons.dart';

/// 만 14세 미만으로 판정됐을 때 가입 대신 보여주는 안내.
///
/// 가입은 보호자 계정의 '자녀 계정 만들기'로만 할 수 있다 (법정대리인 동의).
class UnderAgeNotice extends StatelessWidget {
  final String buttonLabel;
  final VoidCallback onPressed;

  const UnderAgeNotice({
    super.key,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenH),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Icon(Icons.family_restroom_outlined,
              size: 56, color: AppColors.brandAction),
          const SizedBox(height: AppSpacing.xxl),
          Text('보호자와 함께 가입해 주세요',
              style: AppTextStyles.display, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(
            '만 14세 미만은 혼자 가입할 수 없어요.\n'
            '보호자가 tailog 에 가입한 뒤\n'
            '마이페이지 > 자녀 계정에서 계정을 만들어 줄 수 있어요.',
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          AppActionButton(buttonLabel, onPressed: onPressed),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
