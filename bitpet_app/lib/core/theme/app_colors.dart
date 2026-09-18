import 'package:flutter/material.dart';

/// 앱 전체 색.
///
/// ## 한 가지 색은 한 곳에서만 정의한다
///
/// 예전엔 같은 값이 두 이름(`bg`/`paleBg`, `divider`/`paleLine`, `petColorMint`/`petSage`)
/// 으로 각각 하드코딩돼 있었다. 한쪽만 고치면 화면마다 색이 갈라지므로, 지금은 **아래
/// '원본 토큰' 구역에만 리터럴이 있고 나머지는 전부 그 별칭**이다.
/// ⛔ 별칭 자리에 새 `Color(0x...)` 를 적지 말 것.
///
/// ## 브랜드 초록
///
/// 로고색(#5FCFA0)은 흰 글씨 대비가 1.92:1 라 버튼에 쓸 수 없다. 그래서 **칠하는 색과
/// 누르는 색을 나눈다** — 일러스트·로고는 [brandIllust], 실제 조작 대상은 [brandAction]
/// (#1B7F59, 흰 글씨 4.97:1 통과).
abstract final class AppColors {
  // ══════════════════════════════════════════════════════════
  // 원본 토큰 — 리터럴은 여기에만 있다
  // ══════════════════════════════════════════════════════════

  // ── 브랜드 램프 10단계 ────────────────────────────────────
  static const brand50  = Color(0xFFF2FAF5);
  static const brand100 = Color(0xFFDBF2DF); // 지정색
  static const brand200 = Color(0xFFB5E3C8);
  static const brand300 = Color(0xFF86D2AC);
  static const brand400 = Color(0xFF5FCFA0); // 로고색
  static const brand500 = Color(0xFF2FAE7D);
  static const brand600 = Color(0xFF1B7F59); // 액션 (흰 글씨 통과선)
  static const brand700 = Color(0xFF146848);
  static const brand800 = Color(0xFF0F5138);
  static const brand900 = Color(0xFF0B3E2B);

  /// 기본 버튼·탭바 활성·FAB·링크·체크/토글 on. 글씨는 흰색.
  static const brandAction = brand600;

  /// 버튼 눌림 상태.
  static const brandPressed = brand700;

  /// 보조 버튼·선택 상태·칩 배경·아바타 바탕·오늘 날짜. 글씨는 [brandTintInk].
  static const brandTint = brand100;
  static const brandTintInk = Color(0xFF14503A);

  /// 섹션 배경·강조 영역·빈 상태 바탕. 글씨는 본문색 그대로.
  static const brandTintSoft = brand50;

  /// 로고·일러스트·그래프 선·스플래시. **버튼에 쓰지 말 것** (흰 글씨가 안 읽힌다).
  static const brandIllust = brand400;

  // ── 중립색 (초록 쪽으로 미세하게 기울인 회색) ──────────────
  static const bg    = Color(0xFFFFFFFF);
  static const bgAlt = Color(0xFFF4F7F5); // 보조 배경 / 버튼 배경
  static const line  = Color(0xFFE6EBE7); // 테두리 · 구분선
  static const ink   = Color(0xFF121A15); // 본문
  static const ink2  = Color(0xFF5B665F); // 보조 텍스트
  static const ink3  = Color(0xFF909A94); // 비활성 · 힌트

  // ── 의미색 ───────────────────────────────────────────────
  static const success = brand600;
  static const warning = Color(0xFFC77B12);
  static const error   = Color(0xFFC0392B);
  static const info    = Color(0xFF2B6FB8);

  // ── 성별 ─────────────────────────────────────────────────
  static const male    = Color(0xFF3E82D6);
  static const female  = Color(0xFFD95F8B);
  static const unknown = ink3;

  // ── 개체 식별색 6종 (pale 배경 / ink 텍스트) ────────────────
  // sage(연녹)는 브랜드 초록과 부딪혀 '선택됨'으로 잘못 읽혀서 clay(따뜻한 베이지)로 바꿨다.
  static const petClay   = Color(0xFFEDE7E0);
  static const petPeach  = Color(0xFFEEECE6);
  static const petSky    = Color(0xFFE6EEF5);
  static const petLilac  = Color(0xFFEDE9F5);
  static const petButter = Color(0xFFF0EFEA);
  static const petCoral  = Color(0xFFF0EAE7);

  static const petClayInk   = Color(0xFF5E4636);
  static const petPeachInk  = Color(0xFF6A5040);
  static const petSkyInk    = Color(0xFF3A5570);
  static const petLilacInk  = Color(0xFF5C4A72);
  static const petButterInk = Color(0xFF5C4E28);
  static const petCoralInk  = Color(0xFF703C3A);

  // ── 소셜 (브랜드 규정색이라 손대지 않는다) ──────────────────
  static const kakao = Color(0xFFFEE500);
  static const naver = Color(0xFF03C75A);

  // ── 토글 off ─────────────────────────────────────────────
  static const toggleOff = Color(0xFFDDE3DF);

  // ══════════════════════════════════════════════════════════
  // 별칭 — 위 값을 가리키기만 한다
  // ══════════════════════════════════════════════════════════

  static const bg2        = bgAlt;
  static const surface    = bg;
  static const card       = bg;
  static const border     = line;
  static const borderDark = ink;
  static const divider    = line;

  static const textPrimary   = ink;
  static const textSecondary = ink2;
  static const textDisabled  = ink3;

  /// ⚠️ **이건 브랜드색이 아니라 '강조된 먹색'이다.** 앱 전체에서 `hasValue ? primary :
  /// paleInk3` 처럼 **글자를 진하게 만드는 용도**로 400곳 넘게 쓰인다. 초록으로 바꾸면
  /// 본문이 통째로 초록이 된다. 눌리는 것(버튼·FAB·탭바 활성·토글)은 [brandAction] 을 쓸 것.
  static const primary   = ink;
  static const primaryDim = Color(0xFF3D453F);
  /// 쓰이는 자리가 '주의/미룸' 표시(기록 화면·오늘 루틴 시트)라 [warning] 을 가리킨다.
  /// 이름만 보고 브랜드 보조색으로 바꾸면 의미가 뒤집힌다.
  static const secondary = warning;
  static const toggleOn  = brandAction;

  /// @deprecated `success` 를 쓸 것. 예전 형광 초록(#39D353)은 브랜드 램프로 흡수됐다.
  static const accent = success;

  static const paleBg       = bg;
  static const paleBgAlt    = bgAlt;
  static const paleInk2     = ink2;
  static const paleInk3     = ink3;
  static const paleLine     = line;
  static const paleLineSoft = line;

  // 구 이름 (petSage 는 이제 clay 를 가리킨다)
  static const petSage    = petClay;
  static const petSageInk = petClayInk;

  static const petColorMint     = petClay;
  static const petColorPeach    = petPeach;
  static const petColorSky      = petSky;
  static const petColorLavender = petLilac;
  static const petColorButter   = petButter;
  static const petColorRose     = petCoral;

  static const List<Color> petColorPalette = [
    petClay, petPeach, petSky, petLilac, petButter, petCoral,
  ];

  // ── 카테고리 식별 (pale/ink) ───────────────────────────────
  static const catWeight = petSky;    static const catWeightInk = petSkyInk;
  static const catFeed   = petClay;   static const catFeedInk   = petClayInk;
  static const catClean  = petButter; static const catCleanInk  = petButterInk;
  static const catMemo   = petLilac;  static const catMemoInk   = petLilacInk;
  static const catMating = petCoral;  static const catMatingInk = petCoralInk;
  static const catLaying = petPeach;  static const catLayingInk = petPeachInk;

  // ── 급여 전용 ────────────────────────────────────────────
  static const feedBand = petPeach;
  static const feedDot  = Color(0xFFC16E2D);

  // ── 커뮤니티 카테고리 태그 ─────────────────────────────────
  static const commFreeBg   = petPeach;
  static const commFreeInk  = Color(0xFF7B5525);
  static const commQnaBg    = Color(0xFFDDEEF8);
  static const commQnaInk   = Color(0xFF1C4880);
  static const commInfoBg   = brandTint;
  static const commInfoInk  = brandTintInk;
  static const commSellBg   = Color(0xFFE8DDFA);
  static const commSellInk  = Color(0xFF5C2880);
  static const commShopBg   = petClay;
  static const commShopInk  = petClayInk;
  static const commKidsBg   = brandTint;
  static const commKidsInk  = brandTintInk;
  // 공지 — 운영자 글이라 '글 하나'가 아니라 알림처럼 읽혀야 해서 유일하게 어둡다
  static const commNoticeBg  = Color(0xFF12291E);
  static const commNoticeInk = brand100;

  // 커뮤니티 HOT/PINNED/좋아요
  static const commHot      = Color(0xFFC44030);
  static const commNotifDot = Color(0xFFE06035);
  static const commLikeInk  = Color(0xFFA03020);
  static const commLikeBg   = Color(0xFFFFE0D8);
  static const commPinnedBg = brandTintSoft;

  // ── 다크 테마 (추후 정의 예정) ─────────────────────────────
  static const darkBg          = Color(0xFF0F0F14);
  static const darkSurface     = Color(0xFF1A1A24);
  static const darkCard        = Color(0xFF232330);
  static const darkBorder      = Color(0xFF2E2E3E);
  static const darkTextPrimary = Color(0xFFE8E8E8);
}
