import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_input_styles.dart';
import '../theme/app_text_styles.dart';

/// 기록·루틴·개체의 메모(여러 줄) 입력칸. 앱 전체가 이것 하나를 쓴다.
///
/// 3줄 높이로 시작해 입력이 길어지면 [maxLines] 까지 늘어나고, 그 뒤로는 칸 안에서 스크롤된다.
/// 전엔 화면마다 2~6줄 고정·밑줄/박스/옅은 박스·글자 13~15 가 섞여 있었다 (2026-11-13 통일).
/// ⛔ 화면에서 메모용 TextField 를 새로 짜지 말 것 — 줄 수만 다르면 [minLines]/[maxLines] 로 넘긴다.
class AppMemoField extends StatelessWidget {
  const AppMemoField({
    super.key,
    this.controller,
    this.hintText,
    this.onChanged,
    this.validator,
    this.autofocus = false,
    this.maxLength,
    this.minLines = 3,
    this.maxLines = 6,
  });

  final TextEditingController? controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final bool autofocus;

  /// 글자 수 제한. 카운터는 표시하지 않는다.
  final int? maxLength;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      validator: validator,
      autofocus: autofocus,
      maxLength: maxLength,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      style: AppTextStyles.body.copyWith(
          fontSize: 14, height: 1.5, color: AppColors.ink),
      cursorColor: AppColors.brandAction,
      decoration: AppInputStyles.textarea(
        hintText: hintText,
        hintStyle: AppTextStyles.body.copyWith(
            fontSize: 14, height: 1.5, color: AppColors.ink3),
      ).copyWith(
        filled: true,
        fillColor: AppColors.card,
        counterText: '',
        alignLabelWithHint: true,
      ),
    );
  }
}
