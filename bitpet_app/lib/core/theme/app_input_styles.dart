import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 단순 단일행 입력은 전역 테마(InputDecorationTheme)의 밑줄(border-bottom)을 그대로 쓰고,
/// 여러 줄(textarea) 입력만 이 데코레이션으로 전체 테두리를 표시한다.
abstract final class AppInputStyles {
  static const _side = BorderSide(color: AppColors.border);
  static const _focusedSide =
      BorderSide(color: AppColors.textPrimary, width: 1.5);
  static const _errorSide = BorderSide(color: AppColors.error);

  static InputDecoration textarea({
    String? hintText,
    TextStyle? hintStyle,
    EdgeInsetsGeometry contentPadding =
        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: hintStyle,
      filled: false,
      isDense: true,
      contentPadding: contentPadding,
      border: const OutlineInputBorder(
          borderRadius: BorderRadius.zero, borderSide: _side),
      enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero, borderSide: _side),
      focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero, borderSide: _focusedSide),
      errorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero, borderSide: _errorSide),
      focusedErrorBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero, borderSide: _errorSide),
    );
  }
}
