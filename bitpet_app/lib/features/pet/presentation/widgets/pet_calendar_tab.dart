import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pale_palette.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../record/data/models/record_models.dart';
import '../../../record/providers/record_provider.dart';

// 캘린더 탭에서 표시하는 카테고리 (급여·체중·청소·메모)
const _calendarCats = ['FEEDING', 'WEIGHT', 'CLEANING', 'MEMO'];

const _catLabel = {
  'FEEDING': '급여',
  'WEIGHT': '체중',
  'CLEANING': '청소',
  'MEMO': '메모',
};

const _catIcon = {
  'FEEDING': Icons.restaurant_outlined,
  'WEIGHT': Icons.monitor_weight_outlined,
  'CLEANING': Icons.cleaning_services_outlined,
  'MEMO': Icons.note_alt_outlined,
};

/// 개체 상세 — 캘린더 탭.
/// 월별 캘린더에 급여/체중/메모 기록을 카테고리 아이콘으로 표시하고,
/// 날짜 탭 시 캘린더 아래에 해당 날짜의 기록 목록을 보여준다.
class PetCalendarTab extends ConsumerStatefulWidget {
  final int petId;

  const PetCalendarTab({super.key, required this.petId});

  @override
  ConsumerState<PetCalendarTab> createState() => _PetCalendarTabState();
}

class _PetCalendarTabState extends ConsumerState<PetCalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  String get _ymStr =>
      '${_focusedDay.year}-${_focusedDay.month.toString().padLeft(2, '0')}';

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static final _firstDay = DateTime(2020, 1, 1);
  static final _lastDay = DateTime.now().add(const Duration(days: 365));

  void _navMonth(int delta) {
    final next = DateTime(_focusedDay.year, _focusedDay.month + delta);
    if (next.isBefore(_firstDay) || next.isAfter(_lastDay)) return;
    setState(() => _focusedDay = next);
  }

  @override
  Widget build(BuildContext context) {
    final calendarAsync = ref.watch(
        petCalendarProvider(PetYearMonth(widget.petId, _ymStr)));
    final dayAsync = ref.watch(petDayTimelineProvider(
        PetDateParam(widget.petId, _dateKey(_selectedDay))));

    // 날짜(YYYY-MM-DD) → 해당 날짜의 기록 카테고리 (급여/체중/메모만)
    final events = <String, List<String>>{};
    for (final day in calendarAsync.valueOrNull ?? const []) {
      final cats =
          day.categories.where(_calendarCats.contains).toList();
      if (cats.isNotEmpty) events[day.date] = cats;
    }

    const weekKo = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 캘린더 카드 ─────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            border: Border.all(color: AppColors.paleLine),
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            children: [
              // ── 월 이동 헤더 ──
              Row(
                children: [
                  AppNavButton(onTap: () => _navMonth(-1)),
                  const Spacer(),
                  Text(
                    '${_focusedDay.year}.${_focusedDay.month.toString().padLeft(2, '0')}',
                    style: AppTextStyles.mono(15, FontWeight.w700),
                  ),
                  const Spacer(),
                  AppNavButton(forward: true, onTap: () => _navMonth(1)),
                ],
              ),
              const SizedBox(height: 10),

              // ── 캘린더 ──
              TableCalendar<String>(
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: _focusedDay,
                headerVisible: false,
                daysOfWeekHeight: 26,
                rowHeight: 48,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                eventLoader: (day) => events[_dateKey(day)] ?? const [],
                onDaySelected: (selected, focused) {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                },
                onPageChanged: (focused) =>
                    setState(() => _focusedDay = focused),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  isTodayHighlighted: true,
                  // 직각 디자인 — 원형 하이라이트 제거
                  todayDecoration: BoxDecoration(
                    color: AppColors.paleBgAlt,
                    shape: BoxShape.rectangle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.rectangle,
                  ),
                  defaultDecoration: BoxDecoration(shape: BoxShape.rectangle),
                  weekendDecoration: BoxDecoration(shape: BoxShape.rectangle),
                  todayTextStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary),
                  selectedTextStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                  defaultTextStyle:
                      TextStyle(fontSize: 13, color: AppColors.primary),
                  weekendTextStyle:
                      TextStyle(fontSize: 13, color: AppColors.paleInk2),
                  markersAlignment: Alignment.bottomCenter,
                ),
                calendarBuilders: CalendarBuilders(
                  // 요일 헤더 — 한글
                  dowBuilder: (context, day) => Center(
                    child: Text(
                      weekKo[day.weekday % 7],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: day.weekday == DateTime.sunday
                            ? AppColors.error
                            : AppColors.paleInk3,
                      ),
                    ),
                  ),
                  // 마커 — 카테고리별 미니 아이콘
                  markerBuilder: (context, day, cats) {
                    if (cats.isEmpty) return null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: cats
                            .take(3)
                            .map((c) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 1),
                                  child: Icon(
                                    _catIcon[c] ?? Icons.circle,
                                    size: 11,
                                    color: PalePalette.catInk(c),
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),

              // ── 범례 ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _calendarCats
                    .map((c) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(_catIcon[c],
                                  size: 12, color: PalePalette.catInk(c)),
                              const SizedBox(width: 4),
                              Text(_catLabel[c]!,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.paleInk2)),
                            ],
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // ── 선택일 기록 헤더 ─────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            RichText(
              text: TextSpan(
                style: AppTextStyles.paleSectionTitle,
                children: [
                  TextSpan(
                      text: '${_selectedDay.month}.${_selectedDay.day} '),
                  TextSpan(
                    text: '(${weekKo[_selectedDay.weekday % 7]})',
                    style: const TextStyle(
                        color: AppColors.paleInk2,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            dayAsync.whenOrNull(
                    data: (items) => Text(
                        '${items.where((r) => _calendarCats.contains(r.category)).length}건',
                        style: AppTextStyles.mono(12, FontWeight.w700,
                            color: AppColors.paleInk2))) ??
                const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 4),

        // ── 선택일 기록 목록 ─────────────────────────────────
        _buildDayList(dayAsync),
      ],
    );
  }

  /// 선택 날짜의 급여/체중/메모 기록 목록 (캘린더 아래 인라인)
  Widget _buildDayList(AsyncValue<List<TimelineItem>> dayAsync) {
    return dayAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(
          child: Text('기록을 불러올 수 없어요',
              style: TextStyle(fontSize: 13, color: AppColors.paleInk3)),
        ),
      ),
      data: (items) {
        final filtered =
            items.where((r) => _calendarCats.contains(r.category)).toList();
        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Center(
              child: Text('이 날의 기록이 없어요',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.paleInk3)),
            ),
          );
        }
        return Column(
          children: filtered.asMap().entries.map((e) {
            final i = e.key;
            return Container(
              decoration: BoxDecoration(
                border: i < filtered.length - 1
                    ? const Border(
                        bottom: BorderSide(color: AppColors.paleLineSoft))
                    : null,
              ),
              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 2),
              child: _DayRecordRow(item: e.value),
            );
          }).toList(),
        );
      },
    );
  }
}

/// 기록 행 — 개체 상세 기록 탭의 타임라인 행과 동일한 스타일
class _DayRecordRow extends StatelessWidget {
  final TimelineItem item;

  const _DayRecordRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final cat = item.category;
    final at = item.recordedAt;
    final time =
        '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: PalePalette.catPale(cat),
            borderRadius: BorderRadius.zero,
          ),
          child: Icon(_catIcon[cat] ?? Icons.circle_outlined,
              size: 15, color: PalePalette.catInk(cat)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_catLabel[cat] ?? cat,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.paleInk2)),
              Text(item.summary,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(time, style: AppTextStyles.mono(11, FontWeight.w600)),
      ],
    );
  }
}
