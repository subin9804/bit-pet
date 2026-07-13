import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

// ════════════════════════════════════════════════════════════════
// 비밀번호 재설정 플로우 공통 위젯 — 로그인 화면과 같은 룩앤필
// (언더라인 입력 필드 + 직각 풀버튼)
// ════════════════════════════════════════════════════════════════

/// 공통 AppBar — "비밀번호 재설정" 타이틀 + 뒤로가기
PreferredSizeWidget passwordResetAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: AppColors.bg,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new,
          size: 18, color: AppColors.textPrimary),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: const Text(
      '비밀번호 재설정',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    ),
  );
}

/// 상단 안내 텍스트
class ResetGuideText extends StatelessWidget {
  final String text;

  const ResetGuideText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        height: 1.5,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

/// 언더라인 입력 필드 (로그인 화면 _InputField와 동일 스타일)
class ResetInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const ResetInputField({
    super.key,
    required this.controller,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLength,
    this.inputFormatters,
    this.suffixIcon,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      autofocus: autofocus,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
      cursorColor: AppColors.textPrimary,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            const TextStyle(fontSize: 14, color: AppColors.textDisabled),
        counterText: '',
        errorText: errorText,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.textPrimary, width: 1.5),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 11, color: AppColors.error),
      ),
    );
  }
}

/// 직각 풀버튼 (로그인 화면 _FullButton과 동일 스타일)
class ResetFullButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const ResetFullButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.border,
          disabledForegroundColor: AppColors.textDisabled,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
