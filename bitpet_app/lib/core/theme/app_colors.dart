import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── 라이트 테마 (Toss/당근 스타일 모던 미니멀) ──────────────
  static const bg          = Color(0xFFFFFFFF); // 순백 배경
  static const bg2         = Color(0xFFF7F7F8); // 보조 배경 / 버튼 배경
  static const surface     = Color(0xFFFFFFFF);
  static const card        = Color(0xFFFFFFFF);
  static const border      = Color(0xFFE8E8E8); // 얇은 선 테두리
  static const borderDark  = Color(0xFF191919); // 굵은 선

  // Divider
  static const divider     = Color(0xFFEBEBEB); // 리스트 구분선

  // Text
  static const textPrimary   = Color(0xFF191919); // 메인 텍스트 (near-black)
  static const textSecondary = Color(0xFF5C5C5C); // 보조 텍스트
  static const textDisabled  = Color(0xFF9B9B9B); // 비활성 텍스트

  // Primary — near-black (메인 액션 버튼, 토글 on)
  static const primary    = Color(0xFF191919);
  static const primaryDim = Color(0xFF3D3D3D);
  static const secondary  = warning;

  // Accent
  static const accent = Color(0xFF39D353);

  // Toggle / Checkbox
  static const toggleOff = Color(0xFFDEDEDE);
  static const toggleOn  = primary;

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
  static const unknown = Color(0xFF9B9B9B);

  // 개체 식별 컬러 (muted oklch 파스텔 — 채도 낮춤)
  static const petColorMint    = Color(0xFFEAEEEA);
  static const petColorPeach   = Color(0xFFEEECE6);
  static const petColorSky     = Color(0xFFE6EEF5);
  static const petColorLavender = Color(0xFFEDE9F5);
  static const petColorButter  = Color(0xFFF0EFEA);
  static const petColorRose    = Color(0xFFF0EAE7);

  static const List<Color> petColorPalette = [
    petColorMint,
    petColorPeach,
    petColorSky,
    petColorLavender,
    petColorButter,
    petColorRose,
  ];

  // ── 급여(피딩) 전용 토큰 ───────────────────────────────────────
  static const feedBand = petPeach;
  static const feedDot  = Color(0xFFC16E2D);

  // ── PALE 디자인 시스템 토큰 (모던 미니멀 기준) ──────────────────
  static const paleBg       = Color(0xFFFFFFFF); // 순백
  static const paleBgAlt    = Color(0xFFF7F7F8); // 보조 배경
  static const paleInk2     = Color(0xFF6B6B6B); // 보조 텍스트
  static const paleInk3     = Color(0xFFA0A0A0); // 비활성/힌트
  static const paleLine     = Color(0xFFEBEBEB); // 테두리/구분선
  static const paleLineSoft = Color(0xFFEBEBEB); // 인라인 구분선

  // Pet 식별색 (muted pastel oklch 저채도) ─ 앱 전체 동일하게 사용
  static const petSage   = Color(0xFFEAEEEA);
  static const petPeach  = Color(0xFFEEECE6);
  static const petSky    = Color(0xFFE6EEF5);
  static const petLilac  = Color(0xFFEDE9F5);
  static const petButter = Color(0xFFF0EFEA);
  static const petCoral  = Color(0xFFF0EAE7);

  // Pet 식별색 (ink — pale 위 텍스트/점)
  static const petSageInk   = Color(0xFF3D5C42);
  static const petPeachInk  = Color(0xFF6A5040);
  static const petSkyInk    = Color(0xFF3A5570);
  static const petLilacInk  = Color(0xFF5C4A72);
  static const petButterInk = Color(0xFF5C4E28);
  static const petCoralInk  = Color(0xFF703C3A);

  // 카테고리 식별 (pale/ink)
  static const catWeight  = petSky;    static const catWeightInk  = petSkyInk;
  static const catFeed    = petSage;   static const catFeedInk    = petSageInk;
  static const catClean   = petButter; static const catCleanInk   = petButterInk;
  static const catMemo    = petLilac;  static const catMemoInk    = petLilacInk;
  static const catMating  = petCoral;  static const catMatingInk  = petCoralInk;
  static const catLaying  = petPeach;  static const catLayingInk  = petPeachInk;

  // ── 커뮤니티 카테고리 태그 색 ──────────────────────────────
  static const commFreeBg   = petPeach;
  static const commFreeInk  = Color(0xFF7B5525);
  static const commQnaBg    = Color(0xFFDDEEF8);
  static const commQnaInk   = Color(0xFF1C4880);
  static const commInfoBg   = petSage;
  static const commInfoInk  = Color(0xFF2A5438);
  static const commSellBg   = Color(0xFFE8DDFA);
  static const commSellInk  = Color(0xFF5C2880);

  // 커뮤니티 HOT/PINNED/좋아요
  static const commHot      = Color(0xFFC44030);
  static const commNotifDot = Color(0xFFE06035);
  static const commLikeInk  = Color(0xFFA03020);
  static const commLikeBg   = Color(0xFFFFE0D8);
  static const commPinnedBg = Color(0xFFF5F0E8);

  // ── 다크 테마 (추후 정의 예정) ─────────────────────────────
  static const darkBg          = Color(0xFF0F0F14);
  static const darkSurface     = Color(0xFF1A1A24);
  static const darkCard        = Color(0xFF232330);
  static const darkBorder      = Color(0xFF2E2E3E);
  static const darkTextPrimary = Color(0xFFE8E8E8);
}
