import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 모서리 반경.
///
/// 예전엔 앱 전체가 각진 사각형(`BorderRadius.zero`)이었다. 각짐 자체가 문제가 아니라,
/// **모든 것이 같은 모양이라 무엇이 눌리는 것인지 형태로는 알 수 없었다.**
/// 지금은 역할마다 반경이 다르다 — 알약은 상태, 12는 누르는 것, 16은 덩어리다.
abstract final class AppRadius {
  /// 칩·배지·아바타·FAB·토글. 값이 아니라 '알약'이라는 형태가 의미다.
  static const pill = 999.0;

  /// 작은 버튼·태그·체크박스.
  static const sm = 10.0;

  /// 버튼·입력창·스낵바 — **누르거나 입력하는 것**.
  static const md = 12.0;

  /// 카드·이미지·사각 아바타 — **내용을 담는 덩어리**.
  static const lg = 16.0;

  /// 바텀시트 상단 (기존 값 유지).
  static const sheet = 20.0;

  static const brPill  = BorderRadius.all(Radius.circular(pill));
  static const brSm    = BorderRadius.all(Radius.circular(sm));
  static const brMd    = BorderRadius.all(Radius.circular(md));
  static const brLg    = BorderRadius.all(Radius.circular(lg));
  static const brSheet = BorderRadius.vertical(top: Radius.circular(sheet));
}

/// 4배수 간격 그리드.
///
/// 흡수 규칙: 2·3→4, 6·7·10→8, 14→16, 18·22→20, 28→32.
/// 어중간한 값(10, 14, 18)을 쓰면 옆 화면과 여백이 1~2px 어긋나는데, 그 어긋남은
/// 개별로는 안 보이고 화면을 오갈 때 '정리가 안 된 느낌'으로만 남는다.
abstract final class AppSpacing {
  static const xs  = 4.0;
  static const sm  = 8.0;
  static const md  = 12.0;
  static const lg  = 16.0;
  static const xl  = 20.0;
  static const xxl = 24.0;
  static const x32 = 32.0;
  static const x40 = 40.0;
  static const x56 = 56.0;

  /// 화면 좌우 여백. **모든 화면이 이 값 하나를 쓴다** (예전엔 10·12·14·16·20·22 여섯 종류였다).
  ///
  /// 2026-09-22: 20 → 24. 내용이 화면 가장자리에 붙어 답답하다는 판단.
  /// ⚠️ 이 값을 바꾸면 앱 전체가 움직인다 — 그게 이 토큰의 목적이다.
  /// 특정 화면만 좁히고 싶어도 여기에 예외를 만들지 말고 그 화면에서 명시할 것.
  static const screenH = 24.0;

  /// 섹션과 섹션 사이.
  ///
  /// ℹ️ [cardGap] 이 16으로 올라가면서 이 값과의 비율이 2배가 됐다 — 의도한 것이다.
  /// 섹션 경계가 카드 경계보다 확실히 크게 읽혀야 목록이 두 층으로 보인다.
  static const section = 32.0;

  /// 섹션 제목 → 내용.
  static const titleGap = 16.0;

  /// 카드 안쪽 여백.
  static const cardPad = 20.0;

  /// 카드와 카드 사이.
  static const cardGap = 16.0;

  /// 최소 터치 영역 한 변.
  static const minTouch = 44.0;

  static const screenPad = EdgeInsets.symmetric(horizontal: screenH);
  static const cardInset = EdgeInsets.all(cardPad);
}

/// 아이콘 크기 3종.
///
/// 예전엔 10가지가 섞여 있었다. 같은 줄에 18과 20이 나란히 서면 한쪽이 잘못 그려진
/// 것처럼 보인다. 선 굵기는 크기에 비례해야 밀도가 같아 보인다.
abstract final class AppIconSize {
  /// 탭바·앱바·FAB (선 2.0)
  static const lg = 24.0;

  /// **기본** — 리스트·버튼·메뉴 (선 1.8)
  static const md = 20.0;

  /// 인라인 보조 (선 1.6)
  static const sm = 16.0;

  /// ⚠️ **3종 체계 밖이다.** 아바타 위 카메라 표시, 사진의 대표 별표처럼 **작은 원 안에
  /// 들어가는 글리프**용. 원 지름이 18~20 이라 [sm] 을 넣으면 테두리를 뚫는다.
  /// 줄에 그냥 놓이는 아이콘에는 쓰지 말 것 — 그건 [sm] 이다.
  static const badge = 12.0;
}

/// 그림자 3단계.
///
/// ⛔ **모든 카드에 뿌리지 말 것.** 기본은 [elev0](그림자 없음, 선으로 구분)이다.
/// 전부 떠 있으면 아무것도 떠 있지 않은 것과 같다 — 진짜로 위에 올라온 것
/// (시트·FAB·다이얼로그)만 [elev2] 를 쓴다.
abstract final class AppShadows {
  /// 그림자 색. 중립 회색이 아니라 **바탕의 초록기를 머금은 먹색**이다 — 순회색 그림자는
  /// 따뜻한 흰 바탕 위에서 먼지처럼 탁해 보인다.
  static const tint = Color(0xFF0F1512);

  /// 머티리얼 위젯(시트·다이얼로그·FAB·스낵바)의 `shadowColor` 로 넘기는 값.
  ///
  /// ℹ️ 이것들은 [elev2] 를 쓰지 않는다. 그림자를 머티리얼이 elevation 으로 직접
  /// 그리기 때문에 `BoxShadow` 를 끼워 넣을 자리가 없다 — 대신 `app_theme.dart` 에서
  /// elevation 과 이 색으로 같은 무게를 낸다. **두 체계가 따로 노는 게 아니라
  /// 같은 값을 두 방식으로 표현한 것**이므로 한쪽을 고치면 다른 쪽도 같이 볼 것.
  static const material = Color(0x330F1512);

  static const List<BoxShadow> elev0 = [];

  /// 강조가 필요한 카드.
  static const List<BoxShadow> elev1 = [
    BoxShadow(color: Color(0x0D0F1512), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0A0F1512), blurRadius: 10, offset: Offset(0, 2)),
  ];

  /// 바텀시트·FAB·다이얼로그·스낵바 — 실제로 떠 있는 것.
  static const List<BoxShadow> elev2 = [
    BoxShadow(color: Color(0x1A0F1512), blurRadius: 24, offset: Offset(0, 6)),
  ];
}

/// 자주 쓰는 카드 모양. `Container(decoration: AppDecor.card)` 로 쓴다.
abstract final class AppDecor {
  static const card = BoxDecoration(
    color: AppColors.card,
    borderRadius: AppRadius.brLg,
    border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
  );

  /// 목록에서 **한 장씩 떠 있는** 카드. 선으로만 나누면 카드가 몇 장인지가
  /// 안 읽히는 자리(루틴 목록처럼 한 장 안에 여러 행이 들어가는 것)에 쓴다.
  /// 그림자는 [AppShadows.elev1] — 있는 줄 모를 만큼 옅고, 없으면 허전한 정도다.
  static const cardRaised = BoxDecoration(
    color: AppColors.card,
    borderRadius: AppRadius.brLg,
    border: Border.fromBorderSide(BorderSide(color: AppColors.line)),
    boxShadow: AppShadows.elev1,
  );

  /// 선택된 카드·칩. 테두리만 1.5로 굵어지고 바탕이 옅은 브랜드색으로 바뀐다.
  static const cardSelected = BoxDecoration(
    color: AppColors.brandTintSoft,
    borderRadius: AppRadius.brLg,
    border: Border.fromBorderSide(
        BorderSide(color: AppColors.brandAction, width: 1.5)),
  );
}
