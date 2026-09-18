import 'package:flutter/material.dart';
import 'app_colors.dart';

/// 기록 **종류**의 색.
///
/// ⚠️ 이 파일에는 원래 개체별 지정색(`PetPaletteKey` 6종 + hex→키 추정)도 있었는데
/// **전부 걷어냈다.** 개체색은 만들 때 아무거나 고른 값이라 아무 정보도 나르지 않으면서
/// 히어로 카드·갤러리·기록 시트의 넓은 면을 칠하고 있었고, 브랜드색과 계속 서로 당겼다.
/// 개체의 정체성은 사진과 이름이 한다.
///
/// 여기 남은 카테고리 색은 **정보다** — 캘린더의 점 하나, 기록 목록의 배지가 무슨
/// 기록인지를 색으로만 구분한다. 지우면 캘린더가 회색 점 밭이 된다.
/// ⛔ 그러니 이 색들을 '개체를 구분하는 용도'로 되살려 쓰지 말 것.
///
/// 선택 상태(고른 개체·작성 중인 개체·오늘 할 일)에는 `AppColors.brandTint` /
/// `brandAction` 을 쓴다. 그건 '누구냐'가 아니라 '상태'라서 브랜드색이 맞다.
abstract final class PalePalette {
  /// 카테고리 코드 → 배경색
  static Color catPale(String cat) => switch (cat.toUpperCase()) {
        'WEIGHT'  => AppColors.catWeight,
        'FEEDING' => AppColors.catFeed,
        'CLEANING'=> AppColors.catClean,
        'MEMO'    => AppColors.catMemo,
        'MATING'  => AppColors.catMating,
        'LAYING'  => AppColors.catLaying,
        _         => AppColors.bgAlt,
      };

  /// 카테고리 코드 → 잉크색 (텍스트·아이콘·선)
  static Color catInk(String cat) => switch (cat.toUpperCase()) {
        'WEIGHT'  => AppColors.catWeightInk,
        'FEEDING' => AppColors.catFeedInk,
        'CLEANING'=> AppColors.catCleanInk,
        'MEMO'    => AppColors.catMemoInk,
        'MATING'  => AppColors.catMatingInk,
        'LAYING'  => AppColors.catLayingInk,
        _         => AppColors.ink2,
      };
}
