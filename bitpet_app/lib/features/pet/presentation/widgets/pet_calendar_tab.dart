import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/pale_palette.dart';
import '../../../../core/widgets/app_buttons.dart';
import '../../../record/data/models/record_models.dart';
import '../../../record/providers/record_provider.dart';
import '../../../record/record_detail_path.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/species/breeding_terms.dart';
import '../../data/anniversary.dart';
import '../../providers/pet_provider.dart';
import 'anniversary_view.dart';

// 캘린더 탭에서 표시하는 카테고리.
// 서버 `RecordCategory` 전체(급여·체중·청소·메모·메이팅·산란)와 같은 집합이다 —
// 여기서 빠진 카테고리는 마커도 목록도 건수도 전부 조용히 사라진다.
// 실제로 쓰는 건 성별을 반영한 `_PetCalendarTabState._calendarCats` 쪽이다.
const _calendarCatsAll = [
  'FEEDING', 'WEIGHT', 'CLEANING', 'MEMO', 'MATING', 'LAYING',
];

// 기념일 마커용 가짜 카테고리 키 — 서버 집계에는 없는 값이다.
// `_calendarCatsAll` 에 넣지 않으므로 아래 기록 목록·건수 계산에는 섞이지 않는다.
const _annivHatch = 'ANNIV_HATCH';
const _annivAdopt = 'ANNIV_ADOPT';

String _annivCatOf(AnniversaryKind k) =>
    k == AnniversaryKind.hatching ? _annivHatch : _annivAdopt;

AnniversaryKind? _annivKindOf(String cat) => switch (cat) {
      _annivHatch => AnniversaryKind.hatching,
      _annivAdopt => AnniversaryKind.adoption,
      _ => null,
    };

final _legendStyle =
    AppTextStyles.label.copyWith(letterSpacing: 0, color: AppColors.ink2);

const _catLabel = {
  'FEEDING': '급여',
  'WEIGHT': '체중',
  'CLEANING': '청소',
  'MEMO': '메모',
  'MATING': '메이팅',
  // ⚠️ 포유류는 '출산'이다 — 직접 쓰지 말고 [_catLabelOf] 를 거칠 것.
  'LAYING': '산란',
};

/// 범례·날짜별 목록의 카테고리 이름. LAYING 만 종에 따라 '산란'/'출산'으로 갈린다.
String _catLabelOf(String cat, String? speciesCategory) => cat == 'LAYING'
    ? BreedingTerms.of(speciesCategory).laying
    : (_catLabel[cat] ?? cat);


/// 개체 상세 — 캘린더 탭.
/// 월별 캘린더에 기록을 카테고리 아이콘으로 표시하고,
/// 날짜 탭 시 캘린더 아래에 해당 날짜의 기록 목록을 보여준다.
class PetCalendarTab extends ConsumerStatefulWidget {
  final int petId;
  /// 산란을 표시할지 판정하는 데만 쓴다 ([canLayEggs]).
  final String gender;
  /// R=파충류 / A=양서류 / M=포유류 — 산란/출산 라벨을 고른다.
  final String? speciesCategory;

  const PetCalendarTab({
    super.key,
    required this.petId,
    required this.gender,
    this.speciesCategory,
  });

  @override
  ConsumerState<PetCalendarTab> createState() => _PetCalendarTabState();
}

class _PetCalendarTabState extends ConsumerState<PetCalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  /// 이 개체에게 뜰 수 있는 카테고리. 수컷이면 산란이 빠진다.
  /// 마커·범례·건수·날짜별 목록이 **전부 이 하나**를 본다 — 한 군데서만 빼면
  /// 목록엔 없는데 건수만 1 늘어나는 식으로 어긋난다.
  List<String> get _calendarCats => canLayEggs(widget.gender)
      ? _calendarCatsAll
      : _calendarCatsAll.where((c) => c != 'LAYING').toList();

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

    // 날짜(YYYY-MM-DD) → 해당 날짜의 기록 카테고리
    final events = <String, List<String>>{};
    for (final day in calendarAsync.valueOrNull ?? const []) {
      final cats =
          day.categories.where(_calendarCats.contains).toList();
      if (cats.isNotEmpty) events[day.date] = cats;
    }

    // 기념일은 서버 집계에 없다 — 개체 응답의 해칭일·입양일에서 직접 만든다.
    // 마커는 기록과 같은 줄에 찍히므로 가짜 카테고리 키로 얹는다.
    final anniversaries = petAnniversariesInMonth(
        ref.watch(petDetailProvider(widget.petId)).valueOrNull, _focusedDay);
    for (final entry in anniversaries.entries) {
      // 같은 날 여러 마리여도 종류당 하나만 — 셀 안에 아이콘이 줄줄이 서면 읽히지 않는다
      final kinds = entry.value.map((a) => a.kind).toSet();
      final marks = kinds.map(_annivCatOf).toList()..sort();
      events.putIfAbsent(entry.key, () => []).insertAll(0, marks);
    }
    final selectedAnnivs =
        anniversaries[_dateKey(_selectedDay)] ?? const <Anniversary>[];

    const weekKo = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 캘린더 카드 ─────────────────────────────────────
        Container(
          decoration: AppDecor.cardRaised,
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.sm),

              // ── 캘린더 ──
              TableCalendar<String>(
                firstDay: _firstDay,
                lastDay: _lastDay,
                focusedDay: _focusedDay,
                headerVisible: false,
                daysOfWeekHeight: 26,
                rowHeight: 48,
                // ⚠️ 기본값(all)은 세로 드래그를 주/월 전환용으로 잡아먹어서
                // 캘린더 위에서 화면 스크롤이 안 됐다. 월 넘기기(가로)만 남긴다.
                availableGestures: AvailableGestures.horizontalSwipe,
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
                // ⚠️ 고른 날짜가 `AppColors.primary` **사각형**으로 칠해져
                // 있었다 — 이 토큰은 초록이 아니라 먹색(#121A15)이라, 날짜 한
                // 칸이 검은 네모로 박혀 "지워진 날"처럼 보였다. 홈 캘린더에서
                // 같은 지적을 받아 이미 고친 자리와 **같은 결함**이다.
                //
                // 칸 꾸밈은 전부 아래 `calendarBuilders` 가 그린다 — 홈의
                // `_DayCell` 과 같은 28px 원이어야 해서, 칸 전체를 채우는
                // `calendarStyle` 의 decoration 으로는 만들 수 없다.
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  isTodayHighlighted: true,
                  markersAlignment: Alignment.bottomCenter,
                ),
                calendarBuilders: CalendarBuilders(
                  // 요일 헤더 — 한글
                  dowBuilder: (context, day) => Center(
                    child: Text(
                      weekKo[day.weekday % 7],
                      style: AppTextStyles.label.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                        color: day.weekday == DateTime.sunday
                            ? AppColors.error
                            : AppColors.ink3,
                      ),
                    ),
                  ),
                  defaultBuilder: (context, day, _) => _dayCell(day),
                  todayBuilder: (context, day, _) =>
                      _dayCell(day, today: true),
                  selectedBuilder: (context, day, _) =>
                      _dayCell(day, selected: true),
                  // 마커 — 카테고리별 미니 아이콘
                  markerBuilder: (context, day, cats) {
                    if (cats.isEmpty) return null;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: cats.take(3).map((c) {
                          final kind = _annivKindOf(c);
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 1),
                            child: kind != null
                                ? AnniversaryMark(kind: kind)
                                : RecordTypeIcon(
                                    c,
                                    size: AppIconSize.badge,
                                    color: PalePalette.catInk(c),
                                    fallback: Icons.circle,
                                  ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // ── 범례 ──
              // 기념일 두 종류가 붙어 한 줄에 6칸이 되므로 넘치면 줄바꿈시킨다
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 6,
                children: [
                  for (final c in _calendarCats)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RecordTypeIcon(c,
                            size: AppIconSize.badge,
                            color: PalePalette.catInk(c)),
                        const SizedBox(width: AppSpacing.xs),
                        Text(_catLabelOf(c, widget.speciesCategory), style: _legendStyle),
                      ],
                    ),
                  for (final kind in AnniversaryKind.values)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnniversaryMark(kind: kind, size: AppIconSize.badge),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          kind == AnniversaryKind.hatching
                              ? BreedingTerms.of(widget.speciesCategory).hatchDate
                              : '입양일',
                          style: _legendStyle,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.cardGap),

        // ── 선택일 섹션 ──────────────────────────────────────
        // ⚠️ 헤더와 기록 목록이 **카드 없이 바탕에 그대로** 놓여 있었다.
        // 바탕은 연회색이고 내용은 흰 카드 안에 담는다는 이 앱의 규칙에서
        // 이 자리만 벗어나 있어, 위 캘린더 카드가 끝나면 화면이 허전하게
        // 풀렸다. 홈의 선택일 섹션과 같이 흰 카드 한 장으로 묶는다.
        Container(
          width: double.infinity,
          decoration: AppDecor.cardRaised,
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 선택일 기록 헤더 ──
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
                              color: AppColors.ink2,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  dayAsync.whenOrNull(
                          data: (items) => Text(
                              '${items.where((r) => _calendarCats.contains(r.category)).length}건',
                              style: AppTextStyles.mono(12, FontWeight.w700,
                                  color: AppColors.ink2))) ??
                      const SizedBox.shrink(),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),

              // ── 선택일 기록 목록 ──
              // 기념일은 기록보다 위에 — 그 날의 성격을 먼저 알려준다
              for (final a in selectedAnnivs)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md),
                  child: AnniversaryRow(anniversary: a),
                ),
              if (selectedAnnivs.isNotEmpty)
                const Divider(height: 1, color: AppColors.line),

              _buildDayList(dayAsync, selectedAnnivs.isNotEmpty),
            ],
          ),
        ),
      ],
    );
  }

  /// 날짜 한 칸. 홈 캘린더의 `_DayCell` 과 **같은 모양**이다 —
  /// 고른 날은 브랜드색 28px 원 + 흰 글씨, 오늘은 옅은 틴트 원.
  ///
  /// 칸 높이(48)를 다 쓰지 않고 위쪽에 원을 붙이는 이유는 아래 공간이
  /// 기록 마커 자리이기 때문이다 — 원이 칸을 채우면 마커를 깔고 앉는다.
  Widget _dayCell(DateTime day, {bool selected = false, bool today = false}) {
    final weekend = day.weekday == DateTime.sunday ||
        day.weekday == DateTime.saturday;
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(top: 2),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.brandAction
              : today
                  ? AppColors.brandTint
                  : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${day.day}',
          style: AppTextStyles.caption.copyWith(
            fontWeight: selected || today ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? AppColors.bg
                : today
                    ? AppColors.brandTintInk
                    : weekend
                        ? AppColors.ink2
                        : AppColors.ink,
          ),
        ),
      ),
    );
  }

  /// 선택 날짜의 기록 목록 (캘린더 아래 인라인)
  ///
  /// [hasAnniversary] 면 기록이 없어도 빈 안내를 띄우지 않는다 —
  /// 바로 위에 기념일 줄이 있는데 '기록이 없어요'가 따라붙으면 모순으로 읽힌다.
  Widget _buildDayList(
      AsyncValue<List<TimelineItem>> dayAsync, bool hasAnniversary) {
    return dayAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Text('기록을 불러올 수 없어요',
              style: AppTextStyles.caption.copyWith(color: AppColors.ink3)),
        ),
      ),
      data: (items) {
        final filtered =
            items.where((r) => _calendarCats.contains(r.category)).toList();
        if (filtered.isEmpty) {
          if (hasAnniversary) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(
              child: Text('이 날의 기록이 없어요',
                  style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink3)),
            ),
          );
        }
        return Column(
          children: filtered.asMap().entries.map((e) {
            final i = e.key;
            // 행을 누르면 그 종류의 기록 상세로 간다 (급여 → 급여 상세)
            final path = recordDetailPath(widget.petId, e.value.category);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: path == null ? null : () => context.push(path),
              child: Container(
                decoration: BoxDecoration(
                  border: i < filtered.length - 1
                      ? const Border(bottom: BorderSide(color: AppColors.line))
                      : null,
                ),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: _DayRecordRow(
                    item: e.value,
                    speciesCategory: widget.speciesCategory,
                    showChevron: path != null),
              ),
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

  final String? speciesCategory;

  /// 상세 화면으로 갈 수 있는 행 — 오른쪽 화살표로 누를 수 있음을 알린다
  final bool showChevron;

  const _DayRecordRow(
      {required this.item, this.speciesCategory, this.showChevron = false});

  @override
  Widget build(BuildContext context) {
    final cat = item.category;

    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: PalePalette.catPale(cat),
            borderRadius: AppRadius.brMd,
          ),
          child: RecordTypeIcon(cat,
              size: AppIconSize.sm,
              color: PalePalette.catInk(cat),
              fallback: Icons.circle_outlined),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_catLabelOf(cat, speciesCategory),
                  style: AppTextStyles.label.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                      color: AppColors.ink2)),
              Text(item.displayText,
                  style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600, color: AppColors.ink),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        // ⚠️ 오른쪽에 기록 시각(11pt)을 적고 있었다. 저장은 계속 하지만
        // **화면에는 보여주지 않는다** (2026-10-15 사용자 결정) — 이 행은
        // 이미 '그날' 기록 묶음 안이라 시각까지 적을 자리가 아니다.
        if (showChevron)
          const Icon(Icons.chevron_right_rounded,
              size: AppIconSize.md, color: AppColors.ink3),
      ],
    );
  }
}
