import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  static const _base = TextStyle(
    color: AppColors.textPrimary,
    letterSpacing: 0.3,
  );

  static final h1       = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700);
  static final h2       = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w700);
  static final h3       = _base.copyWith(fontSize: 16, fontWeight: FontWeight.w600);
  static final body     = _base.copyWith(fontSize: 14);
  static final bodyBold = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w600);
  static final caption  = _base.copyWith(fontSize: 12, color: AppColors.textSecondary);
  static final label    = _base.copyWith(
    fontSize: 11,
    color: AppColors.textDisabled,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w500,
  );
  static final button = _base.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );
  static final title = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w700);

  // ── JetBrains Mono (숫자/날짜/통계) ────────────────────────
  static TextStyle mono(double size, FontWeight weight, {Color color = AppColors.textPrimary}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);

  static TextStyle get monoHero =>
      mono(44, FontWeight.w700); // 체중 히어로 숫자
  static TextStyle get monoLg =>
      mono(28, FontWeight.w700); // 인라인 체중 입력
  static TextStyle get monoMd =>
      mono(18, FontWeight.w700); // 통계 값
  static TextStyle get monoBody =>
      mono(14, FontWeight.w700); // 일반 숫자
  static TextStyle get monoSm =>
      mono(12, FontWeight.w700, color: AppColors.paleInk2); // 날짜/시각
  static TextStyle get monoXs =>
      mono(10, FontWeight.w600, color: AppColors.paleInk3); // 서브라벨
  static TextStyle get monoXxs =>
      mono(9, FontWeight.w600, color: AppColors.paleInk3); // tiny 라벨

  // ── PALE 텍스트 스타일 (핸드오프 사양) ────────────────────
  static TextStyle paleHero(Color color) =>
      _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700,
          color: color, letterSpacing: -0.5, height: 1.1);
  static TextStyle paleSpecies(Color color) =>
      GoogleFonts.jetBrainsMono(fontSize: 10, fontWeight: FontWeight.w700,
          color: color, letterSpacing: 0.4);
  static TextStyle get paleCatLabel =>
      _base.copyWith(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.paleInk2);
  static TextStyle get paleValue =>
      _base.copyWith(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static TextStyle get paleMeta =>
      _base.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.paleInk3);
  static TextStyle get paleGridLabel =>
      _base.copyWith(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.paleInk3);
  static TextStyle get paleGridValue =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w600);
  static TextStyle get paleSectionTitle =>
      _base.copyWith(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2);
}
