// 월간 캘린더 — 흰 카드 한 장 안에 타일 격자를 담는다.
//
// 리뉴얼 전에는 화면을 꽉 채우는 **선 격자**였다. 7×5 칸을 선으로 나눠 놓으니
// 떠 있는 면이 하나도 없어 전부 같은 깊이로 보이고, 선택한 칸은 카테고리색으로
// 통째 칠해져 그 날 기록이 되레 안 읽혔다.
//
// 지금 구조는 세 덩어리다 (기록 상세 확정 시안):
//   ① 월 이동 줄 + 요약 **글줄** — 면도 카드도 주지 않는다. 숫자만 먹색 700.
//      (개체 상세의 '밴드 + 걸친 통계 카드'를 여기서 또 쓰면 히어로카드와 겹쳐 보인다)
//   ② 흰 카드([AppDecor.cardRaised]) 안의 타일 격자 — 기록 있는 날만 면이 생겨
//      한 달의 밀도가 덩어리로 보인다. 선 격자는 쓰지 않는다.
//   ③ 고른 날 기록은 호출부가 이 아래에 [SelectedDayCard] 로 둔다 — 시트로 받지 않는다.
//
// 세로를 꽉 채우지 않으므로(타일 높이 고정) 호출부에서 스크롤에 넣어야 한다.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_text_styles.dart';
import 'app_buttons.dart';

const _weekKo = ['일', '월', '화', '수', '목', '금', '토'];

/// 타일 한 칸 높이.
///
/// 본문에 쓸 수 있는 높이는 `_tileH - 날짜줄(16) - 위아래 패딩(3+2)` = **41** 이다.
/// [CalendarCellLine] 한 줄이 약 11.8px 이므로 세 줄(35.4)까지 들어간다.
/// ⛔ **호출부에서 네 줄째를 넣지 말 것** — 넘치면 조용히 잘린다([ClipRect]).
/// `+N` 더보기도 한 줄을 차지하므로 **줄 + 더보기 합이 3줄**이어야 한다.
const double _tileH = 62;
const double _gap = 4;

/// 본문 한 줄 높이 — 호출부가 몇 줄까지 넣을 수 있는지 계산할 때 쓴다.
const double calendarCellLineH = 11.8;

/// 타일 본문에 들어갈 수 있는 최대 줄 수 (`+N` 더보기 포함).
const int calendarCellMaxLines = 3;

/// DateTime → 'YYYY-MM-DD'
String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 오늘 날짜 'YYYY-MM-DD'
String todayIso() => isoDate(DateTime.now());

/// 월 요약 글줄의 한 항목 — '급여 **12회**'.
/// 라벨은 보조색, 값은 먹색 700 tabular 로 찍힌다.
class MonthSummaryItem {
  final String label;
  final String value;
  const MonthSummaryItem(this.label, this.value);
}

class MonthGridCalendar extends StatelessWidget {
  /// 표시 중인 달 (일(day)은 무시)
  final DateTime month;

  /// 강조할 날짜 'YYYY-MM-DD'. null이면 강조 없음.
  final String? selectedDate;

  /// 월 이동 줄 아래 한 줄로 찍히는 요약. 빈 리스트면 줄 자체가 빠진다.
  final List<MonthSummaryItem> summary;

  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<String> onDayTap;

  /// 셀 본문. 기록이 없으면 null 을 돌려준다.
  final Widget? Function(String date) cellBuilder;

  /// '오늘' 바로가기. null이면 버튼이 빠진다.
  final VoidCallback? onToday;

  const MonthGridCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.summary,
    required this.onMonthChanged,
    required this.onDayTap,
    required this.cellBuilder,
    this.onToday,
  });

  @override
  Widget build(BuildContext context) {
    final firstWD = DateTime(month.year, month.month, 1).weekday % 7;
    final dim = DateTime(month.year, month.month + 1, 0).day;
    final ym = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final today = todayIso();

    // 앞뒤를 null 로 채워 항상 7의 배수로 만든다 (마지막 주가 잘리지 않게)
    final cells = <int?>[
      ...List<int?>.filled(firstWD, null),
      ...List<int?>.generate(dim, (i) => i + 1),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    final rowCount = cells.length ~/ 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── ① 월 이동 ────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, 0, AppSpacing.xl, 0),
          child: Row(
            children: [
              AppNavButton(
                onTap: () =>
                    onMonthChanged(DateTime(month.year, month.month - 1)),
              ),
              Text('${month.year}. ${month.month.toString().padLeft(2, '0')}',
                  style: AppTextStyles.mono(18, FontWeight.w700)),
              AppNavButton(
                forward: true,
                onTap: () =>
                    onMonthChanged(DateTime(month.year, month.month + 1)),
              ),
              const Spacer(),
              if (onToday != null)
                GestureDetector(
                  onTap: onToday,
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 2),
                    child: Text('오늘',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandAction)),
                  ),
                ),
            ],
          ),
        ),

        // ── 요약 글줄 — 카드도 면도 없이 캡션으로 받는다 ──────
        if (summary.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl, AppSpacing.xs, AppSpacing.xxl, 0),
            child: Wrap(
              spacing: 4,
              runSpacing: 2,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (var i = 0; i < summary.length; i++) ...[
                  if (i > 0)
                    const Text('·',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.toggleOff)),
                  Text(summary[i].label,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.ink2)),
                  Text(summary[i].value,
                      style: AppTextStyles.mono(13, FontWeight.w700)),
                ],
              ],
            ),
          ),

        // ── ② 캘린더 카드 ───────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 11, AppSpacing.lg, 0),
          child: Container(
            decoration: AppDecor.cardRaised,
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 요일 — 선도 바탕도 없다. 글씨만으로 머리말이 된다
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Row(
                    children: List.generate(7, (i) {
                      return Expanded(
                        child: Text(
                          _weekKo[i],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: i == 0
                                ? AppColors.petCoralInk
                                : i == 6
                                    ? AppColors.petSkyInk
                                    : AppColors.ink3,
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                // 날짜 타일
                for (var r = 0; r < rowCount; r++)
                  Padding(
                    padding: EdgeInsets.only(top: r == 0 ? 0 : _gap),
                    child: Row(
                      children: [
                        for (var c = 0; c < 7; c++) ...[
                          if (c > 0) const SizedBox(width: _gap),
                          Expanded(
                            child: Builder(builder: (_) {
                              final day = cells[r * 7 + c];
                              if (day == null) {
                                return const SizedBox(height: _tileH);
                              }
                              final ds =
                                  '$ym-${day.toString().padLeft(2, '0')}';
                              return _DayTile(
                                day: day,
                                weekday: c,
                                selected: ds == selectedDate,
                                isToday: ds == today,
                                content: cellBuilder(ds),
                                onTap: () => onDayTap(ds),
                              );
                            }),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DayTile extends StatelessWidget {
  final int day;
  final int weekday; // 0=일 … 6=토
  final bool selected;
  final bool isToday;
  final Widget? content;
  final VoidCallback onTap;

  const _DayTile({
    required this.day,
    required this.weekday,
    required this.selected,
    required this.isToday,
    required this.content,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final numColor = weekday == 0
        ? AppColors.petCoralInk
        : weekday == 6
            ? AppColors.petSkyInk
            : AppColors.primary;
    final hasContent = content != null;

    return GestureDetector(
      // 빈 날짜도 눌러서 기록을 추가할 수 있어야 한다
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: _tileH,
        decoration: BoxDecoration(
          // 기록이 있는 날만 면이 생긴다 — 한 달의 밀도가 덩어리로 보이는 이유
          color: selected
              ? AppColors.brandTintSoft
              : hasContent
                  ? AppColors.bgAlt
                  : Colors.transparent,
          borderRadius: AppRadius.brSm,
        ),
        // 선택 표시는 **덧그린 테두리**다. 진짜 border 면 그 칸만 내용이 1.5px
        // 밀려서 날짜를 옮길 때마다 숫자가 움찔한다.
        foregroundDecoration: selected
            ? const BoxDecoration(
                borderRadius: AppRadius.brSm,
                border: Border.fromBorderSide(
                    BorderSide(color: AppColors.brandAction, width: 1.5)),
              )
            : null,
        // 좌우 3 — 글자에 1px 씩 더 준다. 칸이 45px 뿐이라 여기서 깎는 2px 이
        // 한 글자 차이가 된다.
        //
        // 아래 2 는 **글자가 타일 밑면에 붙지 않게** 하는 것이다. 0 이던 동안은
        // 마지막 줄의 내림획이 둥근 모서리에 닿아 '살짝 잘린' 것처럼 보였다.
        padding: const EdgeInsets.fromLTRB(3, 3, 3, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 날짜 숫자 — 오늘은 연녹 알약으로 구분한다 (선택 강조와 겹쳐도 읽힌다)
            //
            // ⚠️ 폭을 고정하면 두 자리 날짜가 알약 안에서 줄바꿈되어 둘째 자리가
            // 잘려 나간다(23일 → '2'만 보임). 글자 수만큼 늘어나게 두고,
            // 줄바꿈 자체를 막는다.
            //
            // ⚠️ **숫자 스타일에 `height: 1.1` 을 반드시 남겨 둘 것.**
            // `AppTextStyles` 의 기본 줄 높이가 1.5 라 `mono(12)` 의 줄 상자가
            // 18px 이다 — 이 16px 칸에 넣으면 글자 아래가 잘린다
            // (2026-10-14 사용자 지적: '날짜 하단이 살짝씩 잘려있어').
            //
            // ⚠️ **오늘과 다른 날의 숫자는 같은 상자에 담아야 한다.**
            // 전에는 오늘만 `Container(horizontal: 5)`, 나머지는
            // `Padding(left: 2)` 로 서로 다른 상자였다 — 숫자의 왼쪽 시작점이
            // 3px 어긋나서 한 줄에 오늘이 끼면 그 칸만 숫자가 안쪽으로
            // 밀려, 왼쪽 정렬된 다른 날짜 사이에서 **가운데 정렬처럼 보였다**
            // (2026-10-15 사용자 지적). 상자는 하나로 두고 **바탕만** 켠다.
            SizedBox(
              height: 16,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  alignment: Alignment.center,
                  decoration: isToday
                      ? const BoxDecoration(
                          color: AppColors.brandTint,
                          borderRadius: AppRadius.brPill,
                        )
                      : null,
                  child: Text('$day',
                      maxLines: 1,
                      softWrap: false,
                      style: AppTextStyles.mono(
                              12,
                              isToday || selected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isToday
                                  ? AppColors.brandTintInk
                                  : numColor)
                          .copyWith(height: 1.1)),
                ),
              ),
            ),
            // 본문 — 남는 공간만큼만, 넘치면 잘린다
            Expanded(
              child: content == null
                  ? const SizedBox.shrink()
                  : ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topLeft,
                        maxHeight: double.infinity,
                        child: content,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 타일 안에 한 줄로 들어가는 항목 (색 점 + 라벨)
class CalendarCellLine extends StatelessWidget {
  final Color dotColor;
  final String label;
  final bool muted;

  /// 거식처럼 '있었지만 안 먹은' 항목 — 점을 속 빈 동그라미로 그린다
  final bool hollow;

  const CalendarCellLine({
    super.key,
    required this.dotColor,
    required this.label,
    this.muted = false,
    this.hollow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.only(right: 2.5),
            decoration: BoxDecoration(
              color: hollow ? Colors.transparent : dotColor,
              shape: BoxShape.circle,
              border: hollow ? Border.all(color: dotColor, width: 1.2) : null,
            ),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                // 9pt — 한 칸(약 45px)에 **다섯 글자**가 들어가는 크기다. 12pt
                // 에서는 세 글자도 못 채우고 … 로 잘려서, 칸만 보고는 무슨
                // 기록인지 알 수 없었다. 점(4px)과 자간(-0.2)도 같이 조여
                // 글자에 줄 폭을 넘긴다.
                //
                // `height` 를 1.2 로 박아 두는 이유는 줄 높이를 **계산 가능하게**
                // 만드는 것이다 — `_tileH` 가 몇 줄을 담는지가 여기서 정해진다.
                fontSize: 9,
                letterSpacing: -0.2,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: muted ? AppColors.ink3 : AppColors.ink2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// '+2' 같은 더보기 표시
class CalendarCellMore extends StatelessWidget {
  final int count;
  const CalendarCellMore(this.count, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 6),
        // ⛔ **`AppTextStyles.mono` 를 쓰지 말 것.** 그 함수는 12pt 미만을
        //   12pt 로 올려버린다(`size < 12 ? 12 : size`) — `mono(10, …)` 이라고
        //   적어 둔 동안 실제로는 12pt 로 그려져, 본문 줄(10pt)보다 큰 이 한
        //   줄이 타일 높이를 넘겨 **날짜 칸 아래가 잘려 보였다**.
        //   숫자 두 자를 세로로 맞출 일이 없으니 tabular 도 필요 없다.
        child: Text('+$count',
            style: const TextStyle(
                fontSize: 9,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: AppColors.ink3)),
      );
}
