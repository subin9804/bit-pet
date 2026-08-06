// 화면을 꽉 채우는 월간 그리드 캘린더.
//
// 기존 캘린더는 30px 원형 셀 + "선택한 날의 기록 목록"이 아래에 붙는 구조였다.
// 이 위젯은 **셀 안에서 바로 내용을 읽는** 구조라 아래 목록이 필요 없다.
// 대신 날짜를 누르면 호출부가 바텀시트로 그 날의 상세를 띄운다.
//
// 셀 내용은 화면마다 다르므로 [cellBuilder] 로 위임한다. 남는 세로 공간을
// 6주 행이 균등하게 나눠 갖기 때문에, 내용이 길면 잘린다 (ClipRect + ellipsis).

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'app_buttons.dart';

const _weekKo = ['일', '월', '화', '수', '목', '금', '토'];

/// DateTime → 'YYYY-MM-DD'
String isoDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 오늘 날짜 'YYYY-MM-DD'
String todayIso() => isoDate(DateTime.now());

class MonthGridCalendar extends StatelessWidget {
  /// 표시 중인 달 (일(day)은 무시)
  final DateTime month;

  /// 강조할 날짜 'YYYY-MM-DD'. null이면 강조 없음.
  final String? selectedDate;

  /// 월 이동 헤더 아래에 붙는 요약 ('12회 급여' 등)
  final String monthSummary;

  /// 선택 셀 배경에 쓰는 강조색
  final Color accent;

  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<String> onDayTap;

  /// 셀 본문. 기록이 없으면 null 을 돌려준다.
  final Widget? Function(String date) cellBuilder;

  const MonthGridCalendar({
    super.key,
    required this.month,
    required this.selectedDate,
    required this.monthSummary,
    required this.accent,
    required this.onMonthChanged,
    required this.onDayTap,
    required this.cellBuilder,
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
      children: [
        // ── 월 이동 ──────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
          child: Row(
            children: [
              AppNavButton(
                onTap: () =>
                    onMonthChanged(DateTime(month.year, month.month - 1)),
              ),
              const Spacer(),
              Column(children: [
                Text('${month.year}.${month.month.toString().padLeft(2, '0')}',
                    style: AppTextStyles.mono(15, FontWeight.w700)),
                Text(monthSummary, style: AppTextStyles.monoXxs),
              ]),
              const Spacer(),
              AppNavButton(
                forward: true,
                onTap: () =>
                    onMonthChanged(DateTime(month.year, month.month + 1)),
              ),
            ],
          ),
        ),

        // ── 요일 헤더 ────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            color: AppColors.paleBgAlt,
            border: Border(
              top: BorderSide(color: AppColors.paleLine),
              bottom: BorderSide(color: AppColors.paleLine),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: List.generate(7, (i) {
              return Expanded(
                child: Text(
                  _weekKo[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: i == 0
                        ? AppColors.petCoralInk
                        : i == 6
                            ? AppColors.petSkyInk
                            : AppColors.paleInk3,
                  ),
                ),
              );
            }),
          ),
        ),

        // ── 날짜 그리드 (남은 세로 공간을 균등 분할) ──────────
        Expanded(
          child: Column(
            children: List.generate(rowCount, (r) {
              return Expanded(
                child: Row(
                  children: List.generate(7, (c) {
                    final day = cells[r * 7 + c];
                    if (day == null) return const Expanded(child: _EmptyCell());
                    final ds = '$ym-${day.toString().padLeft(2, '0')}';
                    return Expanded(
                      child: _DayCell(
                        day: day,
                        weekday: c,
                        selected: ds == selectedDate,
                        isToday: ds == today,
                        accent: accent,
                        content: cellBuilder(ds),
                        onTap: () => onDayTap(ds),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _EmptyCell extends StatelessWidget {
  const _EmptyCell();

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.paleBgAlt,
          border: Border(
            right: BorderSide(color: AppColors.paleLineSoft),
            bottom: BorderSide(color: AppColors.paleLineSoft),
          ),
        ),
      );
}

class _DayCell extends StatelessWidget {
  final int day;
  final int weekday; // 0=일 … 6=토
  final bool selected;
  final bool isToday;
  final Color accent;
  final Widget? content;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.weekday,
    required this.selected,
    required this.isToday,
    required this.accent,
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

    return GestureDetector(
      // 빈 날짜도 눌러서 기록을 추가할 수 있어야 한다
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? accent : AppColors.card,
          border: Border(
            right: const BorderSide(color: AppColors.paleLineSoft),
            bottom: const BorderSide(color: AppColors.paleLineSoft),
            top: selected
                ? const BorderSide(color: AppColors.primary, width: 1.5)
                : BorderSide.none,
            left: selected
                ? const BorderSide(color: AppColors.primary, width: 1.5)
                : BorderSide.none,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(3, 3, 3, 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 날짜 숫자 — 오늘은 채운 원으로 구분한다 (선택 강조와 겹쳐도 읽힌다)
            SizedBox(
              height: 18,
              child: Align(
                alignment: Alignment.centerLeft,
                child: isToday
                    ? Container(
                        width: 18,
                        height: 18,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Text('$day',
                            style: AppTextStyles.mono(11, FontWeight.w700,
                                color: AppColors.paleBg)),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text('$day',
                            style: AppTextStyles.mono(12, FontWeight.w600,
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

/// 셀 안에 한 줄로 들어가는 항목 (색 점 + 라벨)
class CalendarCellLine extends StatelessWidget {
  final Color dotColor;
  final String label;
  final bool muted;

  const CalendarCellLine({
    super.key,
    required this.dotColor,
    required this.label,
    this.muted = false,
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
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                height: 1.2,
                fontWeight: FontWeight.w600,
                color: muted ? AppColors.paleInk3 : AppColors.paleInk2,
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
        padding: const EdgeInsets.only(left: 7),
        child: Text('+$count',
            style: AppTextStyles.mono(8, FontWeight.w700,
                color: AppColors.paleInk3)),
      );
}
