import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';

// ════════════════════════════════════════════════════════════════
// 비밀번호 재설정 플로우 공통 위젯 — 로그인 화면과 같은 룩앤필
//
// 로그인 화면이 리뉴얼 테마로 넘어갈 때(2026-10-13) 여기도 같이 맞췄다.
// 전엔 "언더라인 입력 + 먹색 풀버튼" 이었다 — `AppColors.primary` 가 구 별칭이라
// 실제 값이 `ink` 였고, 그래서 이 플로우 전체에 브랜드 초록이 없었다.
//
// 지금: canvas 바탕 위 흰 카드([ResetCard]) + brMd 박스 입력(포커스만 브랜드색)
// + `brandAction` 풀버튼. ⛔ 구 별칭(primary/textPrimary/border/textDisabled)을
// 다시 끌어오지 말 것.
// ════════════════════════════════════════════════════════════════

/// 공통 AppBar — "비밀번호 재설정" 타이틀 + 뒤로가기
PreferredSizeWidget passwordResetAppBar(BuildContext context) {
  return AppBar(
    // ⛔ canvas 를 쓰지 말 것 — 앱바는 카드 쪽(흰색)이다.
    backgroundColor: AppColors.bg,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: true,
    leading: IconButton(
      tooltip: '뒤로',
      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.ink),
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: Text('비밀번호 재설정', style: AppTextStyles.subheading),
  );
}

/// 상단 안내 텍스트. 카드 **밖**에 놓는다 — 카드 안은 '입력하는 곳'으로 둔다.
class ResetGuideText extends StatelessWidget {
  final String text;

  const ResetGuideText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.body.copyWith(height: 1.5, fontWeight: FontWeight.w600),
    );
  }
}

/// 입력·버튼을 담는 흰 카드. 연회색 바탕에 입력만 떠 있으면 어디까지가 한 단계인지
/// 안 읽힌다 — 로그인 화면의 폼 카드와 같은 역할이다.
class ResetCard extends StatelessWidget {
  final List<Widget> children;

  const ResetCard({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecor.cardRaised,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
    );
  }
}

/// 박스 입력 필드 (로그인 화면 `_InputField` 와 동일 스타일)
class ResetInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
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
    this.label,
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

  static const _side = BorderSide(color: AppColors.line);
  static const _focusedSide =
      BorderSide(color: AppColors.brandAction, width: 1.5);

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      autofocus: autofocus,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      style: AppTextStyles.body,
      cursorColor: AppColors.brandAction,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTextStyles.body.copyWith(color: AppColors.ink3),
        counterText: '',
        errorText: errorText,
        filled: false,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 14),
        suffixIcon: suffixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: suffixIcon,
              )
            : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        enabledBorder: const OutlineInputBorder(
            borderRadius: AppRadius.brMd, borderSide: _side),
        focusedBorder: const OutlineInputBorder(
            borderRadius: AppRadius.brMd, borderSide: _focusedSide),
        disabledBorder: const OutlineInputBorder(
            borderRadius: AppRadius.brMd, borderSide: _side),
        errorBorder: const OutlineInputBorder(
            borderRadius: AppRadius.brMd,
            borderSide: BorderSide(color: AppColors.error)),
        focusedErrorBorder: const OutlineInputBorder(
            borderRadius: AppRadius.brMd,
            borderSide: BorderSide(color: AppColors.error, width: 1.5)),
        errorStyle: const TextStyle(fontSize: 12, color: AppColors.error),
      ),
    );

    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label!, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xs + 2),
        field,
      ],
    );
  }
}

/// 풀버튼 (로그인 화면 `_FullButton` 과 동일 스타일)
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
          backgroundColor: AppColors.brandAction,
          foregroundColor: Colors.white,
          // 아직 조건을 못 채운 상태(이메일 미입력 등)와 로딩 둘 다 여기로 온다.
          // 회색으로 내리면 '꺼진 버튼'처럼 보여서 연한 브랜드 톤을 쓴다.
          disabledBackgroundColor: AppColors.brandTint,
          disabledForegroundColor: AppColors.brandTintInk,
          overlayColor: AppColors.brandPressed,
          elevation: 0,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.brandTintInk,
                ),
              )
            : Text(label, style: AppTextStyles.button),
      ),
    );
  }
}
