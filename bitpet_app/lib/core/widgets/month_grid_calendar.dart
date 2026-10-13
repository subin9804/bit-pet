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

/// 타일 한 칸 높이. 12px 라벨 두 줄 + 날짜가 들어가는 최소치다.
const double _tileH = 62;
const double _gap = 4;

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
        padding: const EdgeInsets.fromLTRB(3, 3, 3, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 날짜 숫자 — 오늘은 연녹 알약으로 구분한다 (선택 강조와 겹쳐도 읽힌다)
            //
            // ⚠️ 폭을 고정하면 두 자리 날짜가 알약 안에서 줄바꿈되어 둘째 자리가
            // 잘려 나간다(23일 → '2'만 보임). 글자 수만큼 늘어나게 두고,
            // 줄바꿈 자체를 막는다.
            SizedBox(
              height: 16,
              child: Align(
                alignment: Alignment.centerLeft,
                child: isToday
                    ? Container(
                        height: 16,
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.brandTint,
                          borderRadius: AppRadius.brPill,
                        ),
                        child: Text('$day',
                            maxLines: 1,
                            softWrap: false,
                            style: AppTextStyles.mono(12, FontWeight.w700,
                                color: AppColors.brandTintInk)),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text('$day',
                            style: AppTextStyles.mono(
                                12,
                                selected
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: numColor)),
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
      padding: const EdgeInsets.only(bottom: 1.5),
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
                // 10pt — 한 칸(약 45px)에 **네 글자**가 들어가는 크기다. 12pt
                // 에서는 세 글자도 못 채우고 … 로 잘려서, 칸만 보고는 무슨
                // 기록인지 알 수 없었다. 점(4px)과 자간(-0.2)도 같이 조여
                // 글자에 줄 폭을 넘긴다.
                fontSize: 10,
                letterSpacing: -0.2,
                height: 1.25,
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
        // 본문 줄과 같은 눈높이로 — 줄은 10pt 로 내렸는데 이게 12pt 로 남으면
        // 더보기 표시가 기록 이름보다 커진다.
        padding: const EdgeInsets.only(left: 6),
        child: Text('+$count',
            style:
                AppTextStyles.mono(10, FontWeight.w700, color: AppColors.ink3)),
      );
}
