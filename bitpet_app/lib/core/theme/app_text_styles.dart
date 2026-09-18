import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 글자 스타일.
///
/// ## 숫자에 monospace 를 쓰지 않는다
///
/// 예전엔 체중·날짜 같은 숫자를 전부 `fontFamily: 'monospace'` 로 찍었다. 자리가
/// 흔들리지 않게 하려던 것인데, 안드로이드의 monospace 는 한글을 갖고 있지 않아서
/// `2.4kg` 의 숫자와 `kg` 이 다른 글꼴로 나오고 `2일 전` 은 아예 글꼴이 바뀌어버린다.
/// 지금은 본문 글꼴 그대로 두고 [FontFeature.tabularFigures] 만 켠다 — 숫자 폭은
/// 고정되고 한글은 본문과 같아진다.
///
/// ## 11px 이하를 쓰지 않는다
///
/// 9~11px 지정이 110곳 있었다. 파충류 사육은 사육장 앞에 쪼그려 앉아 한 손으로 하는
/// 일이라 작은 글씨가 특히 안 읽힌다. 본문은 15, 보조 설명 14, 도움말 13에서 멈춘다.
abstract final class AppTextStyles {
  /// 본문 글꼴 — Pretendard (`assets/fonts/`, pubspec 의 `fonts:` 에 등록).
  ///
  /// 기기 기본 글꼴에 맡기지 않는 이유는 **안드로이드 제조사마다 한글 글꼴이 다르기
  /// 때문**이다. 같은 화면이 삼성에선 넉넉하고 픽셀에선 빽빽해 보이는데, 간격을 아무리
  /// 맞춰도 글꼴이 다르면 맞지 않는다. 글꼴을 들고 다니면 그 변수가 사라진다.
  ///
  /// `null` 로 되돌리면 기기 기본 글꼴로 떨어진다 (글꼴 문제를 격리할 때 쓸 것).
  static const String? fontFamily = 'Pretendard';

  /// 숫자 폭을 고정한다. 값이 바뀔 때 뒤 글자가 덜컥이지 않는다.
  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  static const _base = TextStyle(
    fontFamily: fontFamily,
    color: AppColors.ink,
    letterSpacing: 0,
    height: 1.5,
  );

  // ══════════════════════════════════════════════════════════
  // 스케일 10단계
  // ══════════════════════════════════════════════════════════

  /// 24 / 800 — 개체 상세 헤더. (구 `h1`)
  static final display = _base.copyWith(
      fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.4, height: 1.3);

  /// 20 / 700 — 화면 제목. (구 `h2`)
  static final screenTitle = _base.copyWith(
      fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.35);

  /// 18 / 700 — 앱바, 섹션 대제목. (구 `title`)
  static final heading = _base.copyWith(
      fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.4);

  /// 16 / 600 — 섹션 제목, 카드 제목. (구 `h3`)
  static final subheading = _base.copyWith(
      fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2, height: 1.4);

  /// 15 / 400 — 기본 본문.
  static final body = _base.copyWith(fontSize: 15);

  /// 15 / 600 — 리스트 제목.
  static final bodyBold = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600);

  /// 14 / 400 — 보조 설명.
  static final sub = _base.copyWith(fontSize: 14, color: AppColors.ink2);

  /// 13 / 400 — 도움말, 메타 정보.
  static final caption = _base.copyWith(fontSize: 13, color: AppColors.ink2);

  /// 12 / 600 — 대문자 라벨. 여기가 하한이다.
  static final label = _base.copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
      color: AppColors.ink3);

  /// 34 / 700 — 체중 히어로 숫자. 본문 글꼴 + 폭 고정.
  static final numHero = _base.copyWith(
      fontSize: 34,
      fontWeight: FontWeight.w700,
      letterSpacing: -1.0,
      height: 1.1,
      fontFeatures: _tabular);

  static final button = _base.copyWith(
      fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0, height: 1.2);

  // ══════════════════════════════════════════════════════════
  // 구 이름 — 위를 가리킨다 (호출부가 400곳 넘어 이름은 유지한다)
  // ══════════════════════════════════════════════════════════

  static final h1    = display;
  static final h2    = screenTitle;
  static final title = heading;
  static final h3    = subheading;

  // ══════════════════════════════════════════════════════════
  // 숫자 — 구 `mono*`. 이름만 남고 monospace 는 빠졌다
  // ══════════════════════════════════════════════════════════

  /// 숫자용 스타일. 글꼴은 본문과 같고 [FontFeature.tabularFigures] 만 켠다.
  ///
  /// ⚠️ 11 이하를 넘겨도 12 로 올린다 — 작게 쓰라고 만든 함수가 아니다.
  static TextStyle mono(double size, FontWeight weight,
          {Color color = AppColors.ink}) =>
      _base.copyWith(
        fontSize: size < 12 ? 12 : size,
        fontWeight: weight,
        color: color,
        fontFeatures: _tabular,
      );

  static TextStyle get monoHero => numHero;
  static TextStyle get monoLg   => mono(28, FontWeight.w700);
  static TextStyle get monoMd   => mono(18, FontWeight.w700);
  static TextStyle get monoBody => mono(15, FontWeight.w600);
  static TextStyle get monoSm   => mono(13, FontWeight.w600, color: AppColors.ink2);
  static TextStyle get monoXs   => mono(12, FontWeight.w600, color: AppColors.ink3);
  static TextStyle get monoXxs  => mono(12, FontWeight.w600, color: AppColors.ink3);

  // ══════════════════════════════════════════════════════════
  // PALE — 개체 카드/그리드 전용
  // ══════════════════════════════════════════════════════════

  static TextStyle paleHero(Color color) => display.copyWith(color: color);

  static TextStyle paleSpecies(Color color) =>
      mono(12, FontWeight.w700, color: color).copyWith(letterSpacing: 0.4);

  static TextStyle get paleCatLabel =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink2);

  static TextStyle get paleValue => _base.copyWith(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      fontFeatures: _tabular);

  static TextStyle get paleMeta =>
      _base.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.ink3);

  static TextStyle get paleGridLabel =>
      _base.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink3);

  static TextStyle get paleGridValue => _base.copyWith(
      fontSize: 14, fontWeight: FontWeight.w600, fontFeatures: _tabular);

  static TextStyle get paleSectionTitle => subheading;
}
