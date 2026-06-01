import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── 라이트 테마 (HTML 디자인 기준) ─────────────────────────
  static const bg          = Color(0xFFF5F5F0); // 크림 배경
  static const bg2         = Color(0xFFECEAE2); // 보조 배경
  static const surface     = Color(0xFFFFFFFF); // 카드/입력창
  static const card        = Color(0xFFFFFFFF);
  static const border      = Color(0xFFD2CFC3); // 얇은 선
  static const borderDark  = Color(0xFF14140F); // 굵은 선

  // Text
  static const textPrimary   = Color(0xFF14140F); // 메인 텍스트
  static const textSecondary = Color(0xFF5B5A52); // 보조 텍스트
  static const textDisabled  = Color(0xFF8A887E); // 비활성 텍스트

  // Primary — 다크 브라운 (메인 액션 버튼)
  static const primary    = Color(0xFF3A332B);
  static const primaryDim = Color(0xFF5B5148);
  static const secondary  = warning; // 0xFFF4A42A — 이전 버전 호환용 앰버

  // Accent — 레트로 그린 (성공, 강조)
  static const accent = Color(0xFF39D353);

  // Social
  static const kakao  = Color(0xFFFEE500);
  static const naver  = Color(0xFF03C75A);

  // Status
  static const error   = Color(0xFFE53935);
  static const success = Color(0xFF39D353);
  static const warning = Color(0xFFF4A42A);
  static const info    = Color(0xFF4A9EFF);

  // 성별 색상
  static const male    = Color(0xFF4A9EFF);
  static const female  = Color(0xFFFF7BAC);
  static const unknown = Color(0xFF8A887E);

  // 개체 식별 컬러 (사용자 선택용 팔레트)
  static const petColorMint    = Color(0xFFE2F5ED);
  static const petColorPeach   = Color(0xFFFBE4D8);
  static const petColorSky     = Color(0xFFD8F3FF);
  static const petColorLavender = Color(0xFFEAE2FF);
  static const petColorButter  = Color(0xFFFFF7D8);
  static const petColorRose    = Color(0xFFFFD8D8);

  static const List<Color> petColorPalette = [
    petColorMint,
    petColorPeach,
    petColorSky,
    petColorLavender,
    petColorButter,
    petColorRose,
  ];

  // ── PALE 디자인 시스템 토큰 (개체 상세 화면 기준) ──────────────
  static const paleBg       = Color(0xFFFBF7EE); // 아이보리 배경
  static const paleBgAlt    = Color(0xFFF5EFE2); // 칩/선택 배경
  static const paleInk2     = Color(0xFF8A8073); // 보조 텍스트
  static const paleInk3     = Color(0xFFBFB6A8); // 비활성/힌트
  static const paleLine     = Color(0xFFE6DFD0); // 테두리/구분선
  static const paleLineSoft = Color(0xFFEFEADC); // 인라인 구분선

  // Pet 식별색 (pale 배경) — oklch pale ≈ sRGB 근사
  static const petSage   = Color(0xFFE8F2DC);
  static const petPeach  = Color(0xFFFFE3CE);
  static const petSky    = Color(0xFFD5F0FF);
  static const petLilac  = Color(0xFFF1E5FF);
  static const petButter = Color(0xFFFCF2CD);
  static const petCoral  = Color(0xFFFFD8D4);

  // Pet 식별색 (ink — pale 위 텍스트/점) — oklch ink ≈ sRGB 근사
  static const petSageInk   = Color(0xFF39553E);
  static const petPeachInk  = Color(0xFF6A442C);
  static const petSkyInk    = Color(0xFF315265);
  static const petLilacInk  = Color(0xFF554568);
  static const petButterInk = Color(0xFF5C4B1A);
  static const petCoralInk  = Color(0xFF733A36);

  // 카테고리 식별 (pale/ink)
  static const catWeight  = petSky;    static const catWeightInk  = petSkyInk;
  static const catFeed    = petSage;   static const catFeedInk    = petSageInk;
  static const catClean   = petButter; static const catCleanInk   = petButterInk;
  static const catMemo    = petLilac;  static const catMemoInk    = petLilacInk;
  static const catMating  = petCoral;  static const catMatingInk  = petCoralInk;
  static const catLaying  = petPeach;  static const catLayingInk  = petPeachInk;

  // ── 다크 테마 (추후 정의 예정) ─────────────────────────────
  static const darkBg          = Color(0xFF0F0F14);
  static const darkSurface     = Color(0xFF1A1A24);
  static const darkCard        = Color(0xFF232330);
  static const darkBorder      = Color(0xFF2E2E3E);
  static const darkTextPrimary = Color(0xFFE8E8E8);
}
