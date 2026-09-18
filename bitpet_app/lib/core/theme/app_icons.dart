import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'app_colors.dart';

/// assets/icons 의 커스텀 SVG 아이콘 세트.
///
/// 모든 파일은 24×24 viewBox 에 stroke-width 2 로 그려져 있고, 색은 전부
/// `currentColor` 라서 [AppIcon] 이 넘기는 색이 그대로 먹는다.
///
/// 선(line)은 비활성·기본, 채움(fill)은 활성 상태용이다. 탭바처럼 두 상태를
/// 오가는 자리는 [AppIcons.tab] 으로 한 번에 고른다.
///
/// **채움 파일은 선 파일을 지우고 다시 그린 것이 아니라, 선 파일 위에 채움 레이어를
/// 한 장 깐 것이다.** 구조가 항상 두 겹이다:
///
/// 1. `fill="currentColor" stroke="none"` 인 같은 path — 안쪽을 채운다
/// 2. 선 버전과 **한 글자도 다르지 않은** stroke path — 테두리를 그대로 얹는다
///
/// 이렇게 해야 바깥 실루엣이 선 버전과 정확히 같아진다(stroke 가 path 양쪽으로 1씩
/// 번지는 몫이 두 버전에 똑같이 붙는다). 채우기만 하면 채움 쪽이 사방 1씩 작아져
/// 활성 상태가 비활성보다 작아 보이는 거꾸로 된 결과가 나온다.
///
/// 구멍(집 문, 말풍선 점 셋, 달력 구분선·체크)은 **1번 레이어에만** `fill-rule="evenodd"`
/// 로 뚫는다. 2번의 stroke 는 바깥 테두리에만 걸리므로 구멍이 깎이지 않는다.
/// 한 path 에 fill 과 stroke 를 같이 주는 건 하트처럼 구멍이 없는 아이콘뿐이다.
///
/// ⛔ 채움을 만들려고 좌표를 키우거나 `scale()` 로 감싸지 말 것 — 아이콘마다 배율이
/// 갈려 세트가 흐트러지고, 발바닥처럼 형태가 복잡한 그림은 뭉개진다.
abstract final class AppIcons {
  static const _d = 'assets/icons/';

  // ── 탭바 5종 (선 = 비활성 / 채움 = 활성) ──────────────────
  static const homeLine      = '${_d}ic_home_line.svg';
  static const homeFill      = '${_d}ic_home_fill.svg';
  static const petLine       = '${_d}ic_pet_line.svg';
  static const petFill       = '${_d}ic_pet_fill.svg';
  static const routineLine   = '${_d}ic_routine_line.svg';
  static const routineFill   = '${_d}ic_routine_fill.svg';
  static const communityLine = '${_d}ic_community_line.svg';
  static const communityFill = '${_d}ic_community_fill.svg';
  static const myLine        = '${_d}ic_my_line.svg';
  static const myFill        = '${_d}ic_my_fill.svg';

  // ── 기록 6종 ────────────────────────────────────────────
  static const feeding  = '${_d}ic_feeding_line.svg';
  static const weight   = '${_d}ic_weight_line.svg';
  static const cleaning = '${_d}ic_cleaning_line.svg';
  static const memo     = '${_d}ic_memo_line.svg';
  static const mating   = '${_d}ic_mating_line.svg';
  static const laying   = '${_d}ic_laying_line.svg';

  // ── 청소 상세 3종 ───────────────────────────────────────
  // 전체 청소는 기록 카테고리의 '청소'와 같은 그림이다 (같은 내용의 별칭 파일).
  static const cleanFull    = '${_d}ic_clean_full_line.svg';
  static const cleanPartial = '${_d}ic_clean_partial_line.svg';
  static const cleanWater   = '${_d}ic_clean_water_line.svg';

  // ── 메모 태그 5종 ───────────────────────────────────────
  static const shed = '${_d}ic_shed_line.svg';
  static const poop = '${_d}ic_poop_line.svg';
  static const vet  = '${_d}ic_vet_line.svg';

  /// 행동 특이사항. 관찰하는 눈이다 — '무엇을 했다'가 아니라 '무엇을 봤다'는 기록이라서.
  static const behavior = '${_d}ic_behavior_line.svg';

  /// 어디에도 안 들어가는 나머지. 가로 점 셋(…)은 '기타'의 관용 표기다.
  static const etc = '${_d}ic_etc_line.svg';

  // ── 커뮤니티 ────────────────────────────────────────────
  /// 좋아요는 채움 하트, 메이팅은 선 하트다. 같은 외곽선을 채움 여부로만 가른다.
  static const like = '${_d}ic_like_fill.svg';

  /// 누르지 않은 좋아요. 메이팅과 같은 선 하트를 쓴다 — 쓰이는 자리가 겹치지 않는다.
  static const likeLine = mating;

  /// 댓글 수. 커뮤니티 탭(모서리 둥근 말풍선 + 점 셋)과 일부러 모양을 갈랐다 —
  /// 게시판은 사각 말풍선, 대화 한 건은 타원 말풍선.
  static const comment = '${_d}ic_comment_line.svg';

  // ── 공통 ────────────────────────────────────────────────
  static const chevronRight = '${_d}ic_chevron_right_line.svg';

  // ── 종 4종 ──────────────────────────────────────────────
  static const speciesLizardLine = '${_d}ic_species_lizard_line.svg';
  static const speciesLizardFill = '${_d}ic_species_lizard_fill.svg';
  static const speciesSnake      = '${_d}ic_species_snake_line.svg';
  static const speciesTurtle     = '${_d}ic_species_turtle_line.svg';
  static const speciesFrog       = '${_d}ic_species_frog_line.svg';

  /// 탭바처럼 선/채움을 오가는 자리에서 상태에 맞는 아이콘을 고른다.
  static String tab(String line, String fill, {required bool active}) =>
      active ? fill : line;

  /// 기록·루틴 종류 코드 → 아이콘. 세트에 없는 종류(루틴 `CUSTOM` 등)는 null 이고,
  /// 그 자리는 [RecordTypeIcon] 이 Material 아이콘으로 메운다.
  ///
  /// `RoutineType.name` 과 타임라인 카테고리 코드가 같은 문자열이라 한 표로 받는다.
  static String? forType(String? type) => switch (type?.toUpperCase()) {
        'FEEDING' => feeding,
        'WEIGHT' => weight,
        'CLEANING' => cleaning,
        'MEMO' => memo,
        'MATING' => mating,
        'LAYING' => laying,
        _ => null,
      };

  /// 메모 태그 코드(`memo_tag_cd.code`) → 아이콘. 다섯 개가 한 줄에 나란히 서는
  /// 자리라 하나라도 Material 로 떨어지면 그 칩만 그림체가 튄다 — 그래서 null 이 없다.
  static String memoTag(String? code) => switch (code?.toUpperCase()) {
        'VET' => vet,
        'SHED' => shed,
        'POOP' => poop,
        'BEHAVIOR' => behavior,
        _ => etc,
      };

  /// subcategory 코드 → 종 아이콘.
  ///
  /// 서버는 전체 단어(`GECKO`/`LIZARD`/…)를 주고 mock 은 첫 글자(`G`/`L`/…)를
  /// 주기 때문에 둘 다 받는다. 그린 적 없는 종(카멜레온·도롱뇽·소동물)과 모르는
  /// 코드는 도마뱀으로 떨어뜨린다 — 네 발 달린 실루엣이 가장 무난한 대타다.
  /// ⚠️ 첫 글자로 갈라서는 안 된다 — `SMALL_MAMMAL` 이 `SNAKE` 와 같은 `S` 다.
  /// 전체 단어를 먼저 맞춰보고, 한 글자짜리(mock)만 따로 받는다.
  static String species(String? subcategory) {
    switch (subcategory?.toUpperCase()) {
      case 'SNAKE':
      case 'S':
        return speciesSnake;
      case 'TURTLE':
      case 'T':
        return speciesTurtle;
      case 'FROG':
      case 'F':
        return speciesFrog;
      default:
        return speciesLizardLine; // GECKO / LIZARD / 카멜레온 / 소동물 / 모름
    }
  }
}

/// 커스텀 SVG 아이콘 한 개.
///
/// 크기와 색만 넘기면 되도록 [Icon] 과 최대한 비슷하게 맞췄다. 색을 주지 않으면
/// 감싸는 [IconTheme] 을 따라가므로, 기존 `Icon(...)` 자리에 그대로 바꿔 넣어도
/// 버튼·리스트타일의 색이 그대로 따라온다.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.asset, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  /// [AppIcons] 의 상수를 넘긴다.
  final String asset;

  /// 한 변의 길이. 생략하면 [IconTheme] 의 크기, 그것도 없으면 24.
  final double? size;

  /// 생략하면 [IconTheme] 의 색, 그것도 없으면 본문 색.
  final Color? color;

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 24;
    final c = color ?? theme.color ?? AppColors.textPrimary;
    return SvgPicture.asset(
      asset,
      width: s,
      height: s,
      colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      // 로딩 중에도 같은 자리를 차지해야 리스트가 한 번 덜컥이지 않는다
      placeholderBuilder: (_) => SizedBox(width: s, height: s),
    );
  }
}

/// 기록·루틴 종류 코드 하나로 아이콘을 그린다.
///
/// 같은 `switch` 가 루틴 목록·확인 시트·대시보드·타임라인에 여섯 벌 복제돼 있던 것을
/// 여기로 모았다. 종류가 늘 때 한 곳만 고치면 된다.
///
/// 세트에 없는 종류(루틴 `CUSTOM`)는 [fallback] 의 Material 아이콘으로 떨어진다.
class RecordTypeIcon extends StatelessWidget {
  const RecordTypeIcon(
    this.type, {
    super.key,
    this.size,
    this.color,
    this.fallback = Icons.star_outline,
  });

  /// `RoutineType.name` 또는 타임라인 카테고리 코드 (FEEDING / WEIGHT / …)
  final String? type;
  final double? size;
  final Color? color;
  final IconData fallback;

  @override
  Widget build(BuildContext context) {
    final asset = AppIcons.forType(type);
    if (asset == null) return Icon(fallback, size: size, color: color);
    return AppIcon(asset, size: size, color: color);
  }
}
