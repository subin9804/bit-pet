// 홈 대시보드 — 모던 미니멀 (Toss/당근 스타일)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notification/providers/notification_provider.dart';
import '../../pet/providers/pet_provider.dart';
import '../../record/providers/record_provider.dart';
import '../../record/data/record_repository.dart';
import '../../record/data/models/record_models.dart';
import '../../record/data/food_catalog.dart';
import '../../routine/data/models/routine_models.dart';
import '../../routine/providers/routine_provider.dart';
import '../../routine/presentation/bulk_confirm_sheet.dart';
import '../../routine/presentation/per_pet_confirm_sheet.dart';

// ignore_for_file: prefer_const_constructors_in_immutables


class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab>
    with WidgetsBindingObserver {
  final _pageController = PageController(viewportFraction: 0.88);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  // 백그라운드에서 복귀 시 날짜가 바뀌었으면 오늘 루틴 재로드
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(todayRoutinesProvider.notifier).reloadIfStale();
    }
  }


  @override
  Widget build(BuildContext context) {
    final authAsync    = ref.watch(authStateProvider);
    final userName     = authAsync.valueOrNull?.name ?? '사용자';

    final todayAsync   = ref.watch(todayRoutinesProvider);
    final recentAsync  = ref.watch(recentRecordsProvider);
    final unread       = ref.watch(unreadNotificationCountProvider);

    final allRoutines  = todayAsync.valueOrNull ?? [];
    final remaining    = allRoutines.where((r) => !r.isAllCompleted).length;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        children: [
          // ── 헤더 (고정) ────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: _Header(
              userName: userName,
              remainingCount: remaining,
              hasUnread: unread > 0,
              onBellTap: () => context.push('/notifications'),
            ),
          ),

          // ── 본문 (스크롤) ────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                ref.invalidate(todayRoutinesProvider);
                ref.invalidate(recentRecordsProvider);
                ref.read(petListProvider.notifier).load();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 110),
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // ── TODAY 섹션 ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: Row(
                        children: [
                          Text('TODAY',
                              style: AppTextStyles.mono(11, FontWeight.w700,
                                  color: AppColors.textDisabled)),
                          const Spacer(),
                          todayAsync.whenOrNull(data: (r) => Text(
                            '${r.length - remaining} / ${r.length}',
                            style: AppTextStyles.mono(11, FontWeight.w700,
                                color: AppColors.textDisabled),
                          )) ?? const SizedBox.shrink(),
                        ],
                      ),
                    ),
                    _TodayDeck(
                      todayAsync: todayAsync,
                      currentPage: _currentPage,
                      pageController: _pageController,
                      onPageChanged: (i) => setState(() => _currentPage = i),
                    ),

                    const SizedBox(height: 32),

                    // ── 기록 캘린더 섹션 ─────────────────────────
                    _SectionHeader(title: '기록 캘린더'),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: _HomeCalendar(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 헤더 ──────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  final String userName;
  final int remainingCount;
  final bool hasUnread;
  final VoidCallback onBellTap;

  const _Header({
    required this.userName,
    required this.remainingCount,
    required this.hasUnread,
    required this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'bit-pet',
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDisabled,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.7,
                      height: 1.2,
                    ),
                    children: [
                      TextSpan(text: '안녕, $userName님\n'),
                      TextSpan(
                        text: '오늘의 루틴 $remainingCount개',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 알림 버튼 — 직각 컨테이너
          GestureDetector(
            onTap: onBellTap,
            child: Stack(
              children: [
                Container(
                  width: 36, height: 36,
                  color: AppColors.bg2,
                  child: const Icon(Icons.notifications_none_outlined,
                      size: 18, color: AppColors.textPrimary),
                ),
                if (hasUnread)
                  Positioned(
                    right: 7, top: 7,
                    child: Container(
                      width: 7, height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE05C3A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── TODAY 덱 ──────────────────────────────────────────────────
class _TodayDeck extends StatelessWidget {
  final AsyncValue<List<TodayRoutine>> todayAsync;
  final int currentPage;
  final PageController pageController;
  final ValueChanged<int> onPageChanged;

  const _TodayDeck({
    required this.todayAsync,
    required this.currentPage,
    required this.pageController,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return todayAsync.when(
      loading: () => const SizedBox(
        height: 200,
        child: Center(
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.primary)),
      ),
      error: (_, __) => const SizedBox(
        height: 200,
        child: Center(child: Text('루틴을 불러올 수 없어요')),
      ),
      data: (allRoutines) {
        final routines = [...allRoutines]..sort((a, b) {
          if (a.isAllCompleted == b.isAllCompleted) return 0;
          return a.isAllCompleted ? 1 : -1;
        });
        if (routines.isEmpty) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(28),
            color: AppColors.bg2,
            child: const Center(
              child: Text('오늘 예정된 루틴이 없어요',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500)),
            ),
          );
        }

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: pageController,
                onPageChanged: onPageChanged,
                itemCount: routines.length,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(
                      left: i == 0 ? 20 : 0,
                      right: 10),
                  child: _TodayRoutineCard(
                    routine: routines[i],
                    index: i,
                    total: routines.length,
                  ),
                ),
              ),
            ),
            if (routines.length > 1)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(routines.length, (i) {
                    final active = i == currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 5,
                      height: 4,
                      color: active ? AppColors.primary : AppColors.divider,
                    );
                  }),
                ),
              )
            else
              const SizedBox(height: 6),
          ],
        );
      },
    );
  }
}

// ── TODAY 루틴 카드 ───────────────────────────────────────────
class _TodayRoutineCard extends StatelessWidget {
  final TodayRoutine routine;
  final int index;
  final int total;

  const _TodayRoutineCard({
    required this.routine,
    required this.index,
    required this.total,
  });

  Color get _bg => switch (routine.routineType) {
        RoutineType.FEEDING  => AppColors.petPeach,
        RoutineType.CLEANING => AppColors.petSky,
        RoutineType.WEIGHT   => AppColors.petSage,
        RoutineType.CUSTOM   => AppColors.petLilac,
      };

  IconData get _icon => switch (routine.routineType) {
        RoutineType.FEEDING  => Icons.restaurant_outlined,
        RoutineType.CLEANING => Icons.cleaning_services_outlined,
        RoutineType.WEIGHT   => Icons.monitor_weight_outlined,
        RoutineType.CUSTOM   => Icons.star_outline,
      };

  String get _typeLabel => switch (routine.routineType) {
        RoutineType.FEEDING  => 'FEEDING',
        RoutineType.CLEANING => 'CLEANING',
        RoutineType.WEIGHT   => 'WEIGHT',
        RoutineType.CUSTOM   => 'CUSTOM',
      };

  void _openBulk(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => BulkConfirmSheet(routine: routine),
    );
  }

  void _openPerPet(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (_) => PerPetConfirmSheet(routine: routine),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allDone   = routine.isAllCompleted;
    final done      = routine.completedPetCount;
    final totalPets = routine.totalPetCount;

    return Opacity(
      opacity: allDone ? 0.60 : 1.0,
      child: Container(
        color: _bg,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시각 + 인덱스
            Row(
              children: [
                Text(
                  routine.alarmTime ?? '--:--',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: AppColors.textSecondary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  color: Colors.white.withValues(alpha: 0.55),
                  child: Text(
                    '${(index + 1).toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
                    style: AppTextStyles.mono(10, FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 아이콘 + 제목 + 마리수
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  color: Colors.white.withValues(alpha: 0.55),
                  child: Icon(_icon, size: 20, color: AppColors.textPrimary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_typeLabel,
                          style: AppTextStyles.mono(9, FontWeight.w700,
                              color: AppColors.textSecondary)),
                      const SizedBox(height: 1),
                      Text(
                        routine.title,
                        style: TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary, letterSpacing: -0.4,
                          decoration: allDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          decorationColor: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  color: Colors.white.withValues(alpha: 0.6),
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 11, color: AppColors.textPrimary),
                      const SizedBox(width: 3),
                      Text('$totalPets마리',
                          style: AppTextStyles.mono(10, FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // 진행도
            Row(
              children: [
                const Spacer(),
                Text('$done / $totalPets 완료',
                    style: AppTextStyles.mono(11, FontWeight.w700,
                        color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: 12),

            // 액션 버튼 2개 — border-radius 0
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: allDone ? null : () => _openBulk(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: allDone ? Colors.transparent : AppColors.primary,
                        border: allDone
                            ? Border.all(color: AppColors.textSecondary, width: 1)
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!allDone) ...[
                            const Icon(Icons.check,
                                size: 13, color: Colors.white),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            allDone ? '완료됨' : '일괄 완료',
                            style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700,
                              color: allDone
                                  ? AppColors.textSecondary
                                  : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openPerPet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      color: Colors.white.withValues(alpha: 0.65),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.view_list_outlined,
                              size: 13, color: AppColors.textPrimary),
                          const SizedBox(width: 5),
                          Text('개별 완료',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}

// ── 섹션 헤더 ─────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;
  final VoidCallback? onTap;

  const _SectionHeader({
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.3)),
          if (trailing != null)
            GestureDetector(
              onTap: onTap,
              child: Text(trailing!,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textDisabled)),
            ),
        ],
      ),
    );
  }
}

// ── 홈 기록 캘린더 ──────────────────────────────────────────────
class _HomeCalendar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_HomeCalendar> createState() => _HomeCalendarState();
}

class _HomeCalendarState extends ConsumerState<_HomeCalendar> {
  late DateTime _month;
  String? _selDate;
  final Map<String, AsyncValue<List<RecentRecord>>> _dayCache = {};

  static const _weekKo = ['일', '월', '화', '수', '목', '금', '토'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    final todayStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _selDate = todayStr;
    _dayCache[todayStr] = const AsyncLoading();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(recordRepositoryProvider).getRecordsByDate(todayStr).then((records) {
        if (mounted) setState(() => _dayCache[todayStr] = AsyncData(records));
      }).catchError((e, s) {
        if (mounted) setState(() => _dayCache[todayStr] = AsyncError(e, s));
      });
    });
  }

  String get _yearMonth =>
      '${_month.year}-${_month.month.toString().padLeft(2, '0')}';

  void _prev() => setState(() {
        _month = DateTime(_month.year, _month.month - 1);
        _selDate = null;
      });

  void _next() {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) {
      setState(() {
        _month = next;
        _selDate = null;
      });
    }
  }

  Future<void> _pickYearMonth() async {
    final now = DateTime.now();
    final result = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _YearMonthPicker(current: _month, maxDate: DateTime(now.year, now.month)),
    );
    if (result != null) {
      setState(() {
        _month = result;
        _selDate = null;
      });
    }
  }

  void _selectDate(String date) {
    if (_selDate == date) {
      setState(() => _selDate = null);
      return;
    }
    setState(() => _selDate = date);
    if (!_dayCache.containsKey(date)) {
      setState(() => _dayCache[date] = const AsyncLoading());
      ref.read(recordRepositoryProvider).getRecordsByDate(date).then((records) {
        if (mounted) setState(() => _dayCache[date] = AsyncData(records));
      }).catchError((e, s) {
        if (mounted) setState(() => _dayCache[date] = AsyncError(e, s));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final calAsync = ref.watch(homeCalendarProvider(_yearMonth));
    final dayAsync = _selDate != null ? _dayCache[_selDate!] : null;
    final now = DateTime.now();
    final isCurrentMonth =
        _month.year == now.year && _month.month == now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 캘린더 컨테이너 — 테두리 없이 구분선으로만
        Container(
          decoration: const BoxDecoration(
            color: AppColors.card,
            border: Border(
              top: BorderSide(color: AppColors.divider),
              bottom: BorderSide(color: AppColors.divider),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Column(
            children: [
              // 월 네비게이션
              Row(children: [
                GestureDetector(
                  onTap: _prev,
                  child: const Icon(Icons.chevron_left,
                      size: 20, color: AppColors.textSecondary),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today_outlined,
                    size: 15, color: AppColors.textPrimary),
                const SizedBox(width: 7),
                GestureDetector(
                  onTap: _pickYearMonth,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${_month.year}년 ${_month.month}월',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.expand_more, size: 16, color: AppColors.textDisabled),
                    ],
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: isCurrentMonth ? null : _next,
                  child: Icon(Icons.chevron_right,
                      size: 20,
                      color: isCurrentMonth
                          ? AppColors.divider
                          : AppColors.textSecondary),
                ),
              ]),
              const SizedBox(height: 10),
              // 요일 헤더
              Row(
                children: _weekKo
                    .map((d) => Expanded(
                          child: Center(
                            child: Text(d,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: d == '일'
                                      ? AppColors.error.withValues(alpha: 0.5)
                                      : AppColors.textDisabled,
                                )),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 6),
              _CalendarGrid(
                month: _month,
                days: calAsync.valueOrNull ?? const [],
                today: now,
                selDate: _selDate,
                onSelect: _selectDate,
              ),
            ],
          ),
        ),

        // 선택일 기록
        if (_selDate != null) ...[
          const SizedBox(height: 12),
          _DayRecordSection(
            dateStr: _selDate!,
            weekKo: _weekKo,
            recordsAsync: dayAsync ?? const AsyncLoading(),
          ),
        ],
      ],
    );
  }
}

// ── 날짜별 기록 섹션 ────────────────────────────────────────────
class _DayRecordSection extends StatelessWidget {
  final String dateStr;
  final List<String> weekKo;
  final AsyncValue<List<RecentRecord>> recordsAsync;

  const _DayRecordSection({
    required this.dateStr,
    required this.weekKo,
    required this.recordsAsync,
  });

  static const _catOrder = ['FEEDING', 'WEIGHT', 'CLEANING', 'MEMO', 'MATING', 'LAYING'];
  static const _catLabel = {
    'FEEDING': '피딩', 'WEIGHT': '몸무게', 'CLEANING': '청소',
    'MEMO': '메모', 'MATING': '메이팅', 'LAYING': '산란',
  };
  static const _catIcon = {
    'FEEDING': Icons.restaurant_outlined,
    'WEIGHT': Icons.monitor_weight_outlined,
    'CLEANING': Icons.cleaning_services_outlined,
    'MEMO': Icons.sticky_note_2_outlined,
    'MATING': Icons.favorite_outline,
    'LAYING': Icons.egg_outlined,
  };

  static Color _petColor(String? code) {
    if (code == null || code.isEmpty) return AppColors.petSage;
    try { return Color(int.parse(code.replaceFirst('#', '0xFF'))); }
    catch (_) { return AppColors.petSage; }
  }

  void _openDetail(BuildContext ctx, String type, List<RecentRecord> recs) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _CategoryDetailSheet(
        type: type,
        label: _catLabel[type] ?? type,
        records: recs,
        petColor: _petColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.parse(dateStr);
    final header = '${dt.month}.${dt.day} (${weekKo[dt.weekday % 7]})';
    final totalCount = recordsAsync.valueOrNull?.length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(header,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary, letterSpacing: -0.2)),
              if (recordsAsync.hasValue)
                Text('$totalCount건',
                    style: AppTextStyles.mono(12, FontWeight.w700,
                        color: AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        recordsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 1.5)),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (records) {
            if (records.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                margin: const EdgeInsets.symmetric(horizontal: 20),
                color: AppColors.bg2,
                child: const Center(
                  child: Text('이 날의 기록이 없어요',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                          color: AppColors.textDisabled)),
                ),
              );
            }

            final grouped = <String, List<RecentRecord>>{};
            for (final r in records) {
              grouped.putIfAbsent(r.recordType, () => []).add(r);
            }
            final categories = _catOrder.where((c) => grouped.containsKey(c)).toList();

            // 리스트 아이템 + 구분선 구조
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.card,
                border: Border(
                  top: BorderSide(color: AppColors.divider),
                  bottom: BorderSide(color: AppColors.divider),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                children: categories.map((type) {
                  final recs = grouped[type]!;
                  return _CategoryRow(
                    type: type,
                    icon: _catIcon[type] ?? Icons.circle_outlined,
                    label: _catLabel[type] ?? type,
                    records: recs,
                    petColor: _petColor,
                    onTap: () => _openDetail(context, type, recs),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

// ── 카테고리 행 ──────────────────────────────────────────────
class _CategoryRow extends StatelessWidget {
  final String type;
  final IconData icon;
  final String label;
  final List<RecentRecord> records;
  final Color Function(String?) petColor;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.type,
    required this.icon,
    required this.label,
    required this.records,
    required this.petColor,
    required this.onTap,
  });

  static Color _catBg(String t) => switch (t) {
    'FEEDING'  => AppColors.catFeed,
    'WEIGHT'   => AppColors.catWeight,
    'CLEANING' => AppColors.catClean,
    'MEMO'     => AppColors.catMemo,
    'MATING'   => AppColors.catMating,
    'LAYING'   => AppColors.catLaying,
    _ => AppColors.bg2,
  };

  static Color _catIconInk(String t) => switch (t) {
    'FEEDING'  => AppColors.catFeedInk,
    'WEIGHT'   => AppColors.catWeightInk,
    'CLEANING' => AppColors.catCleanInk,
    'MEMO'     => AppColors.catMemoInk,
    'MATING'   => AppColors.catMatingInk,
    'LAYING'   => AppColors.catLayingInk,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final names = records.map((r) => (name: r.petName, color: r.colorCode)).toList();
    const showMax = 2;
    final overflow = names.length > showMax ? names.length - showMax : 0;
    final visible = names.take(showMax).toList();
    final chipBg = _catBg(type);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          // 카테고리 아이콘 — 직각 컨테이너
          Container(
            width: 28, height: 28,
            color: chipBg,
            child: Icon(icon, size: 13, color: _catIconInk(type)),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 44,
            child: Text(label,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
          ),
          const Spacer(),
          // 개체 칩들 — 직각
          ...visible.map((n) => Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              color: chipBg,
              child: Text(n.name,
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: _catIconInk(type)),
                  overflow: TextOverflow.ellipsis),
            ),
          )),
          if (overflow > 0) Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              color: AppColors.bg2,
              child: Text('+$overflow',
                  style: AppTextStyles.mono(11, FontWeight.w700,
                      color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 14, color: AppColors.textDisabled),
        ]),
      ),
    );
  }
}

// ── 카테고리 상세 바텀시트 ─────────────────────────────────────
// 바텀시트는 border-radius 유지
class _CategoryDetailSheet extends StatelessWidget {
  final String type;
  final String label;
  final List<RecentRecord> records;
  final Color Function(String?) petColor;

  const _CategoryDetailSheet({
    required this.type,
    required this.label,
    required this.records,
    required this.petColor,
  });

  static String _translateFeedingSummary(String raw) {
    if (raw.isEmpty) return raw;
    final parts = raw.split(' ');
    parts[0] = FoodType.labelForCode(parts[0]);
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, List<RecentRecord>> petGroups = {};
    for (final r in records) {
      final key = r.petId?.toString() ?? r.petName;
      petGroups.putIfAbsent(key, () => []).add(r);
    }
    final petKeys = petGroups.keys.toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: AppColors.divider,
            ),
          ),
          Text(label,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary, letterSpacing: -0.3)),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.55,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: petKeys.length,
              itemBuilder: (_, i) {
                final key      = petKeys[i];
                final petRecs  = petGroups[key]!;
                final first    = petRecs.first;
                final petId    = int.tryParse(key);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 8, height: 8,
                        margin: const EdgeInsets.only(top: 5),
                        decoration: BoxDecoration(
                            color: petColor(first.colorCode), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: petId == null ? null : () {
                                Navigator.of(context).pop();
                                context.push('/pets/$petId');
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(first.petName,
                                      style: const TextStyle(
                                          fontSize: 13, fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary)),
                                  if (petId != null) ...[
                                    const SizedBox(width: 2),
                                    const Icon(Icons.chevron_right,
                                        size: 14, color: AppColors.textDisabled),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            ...petRecs.map((r) {
                              final hasMemo = r.memo != null && r.memo!.isNotEmpty;
                              final rawSummary = r.recordType == 'FEEDING'
                                  ? _translateFeedingSummary(r.summary)
                                  : r.summary;
                              final display = [
                                if (rawSummary.isNotEmpty) rawSummary,
                                if (hasMemo) r.memo!,
                              ].join('  ·  ');
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Text(
                                  display,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final DateTime month;
  final List<CalendarDay> days;
  final DateTime today;
  final String? selDate;
  final ValueChanged<String> onSelect;

  const _CalendarGrid({
    required this.month,
    required this.days,
    required this.today,
    required this.selDate,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final recordMap = {for (final d in days) d.date: d.categories};

    final firstDay = DateTime(month.year, month.month, 1);
    final startOffset = firstDay.weekday % 7;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final ym = '${month.year}-${month.month.toString().padLeft(2, '0')}';

    final cells = <Widget>[
      for (int i = 0; i < startOffset; i++) const SizedBox(),
      for (int d = 1; d <= daysInMonth; d++)
        _DayCell(
          day: d,
          dateStr: '$ym-${d.toString().padLeft(2, '0')}',
          categories: recordMap[
                  '$ym-${d.toString().padLeft(2, '0')}'] ??
              const [],
          isToday: d == today.day &&
              month.year == today.year &&
              month.month == today.month,
          isSelected: selDate ==
              '$ym-${d.toString().padLeft(2, '0')}',
          onTap: onSelect,
        ),
    ];

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.88,
      mainAxisSpacing: 2,
      children: cells,
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final String dateStr;
  final List<String> categories;
  final bool isToday;
  final bool isSelected;
  final ValueChanged<String> onTap;

  const _DayCell({
    required this.day,
    required this.dateStr,
    required this.categories,
    required this.isToday,
    required this.isSelected,
    required this.onTap,
  });

  static Color _catColor(String cat) => switch (cat) {
        'FEEDING'  => AppColors.catFeedInk,
        'WEIGHT'   => AppColors.catWeightInk,
        'CLEANING' => AppColors.catCleanInk,
        'MEMO'     => AppColors.catMemoInk,
        'MATING'   => AppColors.catMatingInk,
        'LAYING'   => AppColors.catLayingInk,
        _ => AppColors.textDisabled,
      };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(dateStr),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            color: isSelected
                ? AppColors.primary
                : isToday
                    ? AppColors.bg2
                    : Colors.transparent,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          if (categories.isNotEmpty)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: categories.take(3).map((c) => Container(
                    width: 4,
                    height: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _catColor(c),
                      shape: BoxShape.circle,
                    ),
                  )).toList(),
            )
          else
            const SizedBox(height: 6),
        ],
      ),
    );
  }
}

// ── 년/월 피커 바텀시트 (바텀시트 — border-radius 유지) ──────────
class _YearMonthPicker extends StatefulWidget {
  final DateTime current;
  final DateTime maxDate;

  const _YearMonthPicker({required this.current, required this.maxDate});

  @override
  State<_YearMonthPicker> createState() => _YearMonthPickerState();
}

class _YearMonthPickerState extends State<_YearMonthPicker> {
  late int _year;
  late int _month;

  static const _monthNames = [
    '1월','2월','3월','4월','5월','6월',
    '7월','8월','9월','10월','11월','12월',
  ];

  @override
  void initState() {
    super.initState();
    _year = widget.current.year;
    _month = widget.current.month;
  }

  bool _isDisabled(int m) =>
      _year > widget.maxDate.year ||
      (_year == widget.maxDate.year && m > widget.maxDate.month);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(22, 0, 22, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              color: AppColors.divider,
            ),
          ),
          // 연도 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _year--),
                child: const Icon(Icons.chevron_left, size: 24, color: AppColors.textSecondary),
              ),
              const SizedBox(width: 28),
              Text('$_year년',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(width: 28),
              GestureDetector(
                onTap: _year < widget.maxDate.year ? () => setState(() => _year++) : null,
                child: Icon(Icons.chevron_right,
                    size: 24,
                    color: _year < widget.maxDate.year ? AppColors.textSecondary : AppColors.divider),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 월 그리드 (4x3) — 직각 버튼
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.0,
            children: List.generate(12, (i) {
              final m = i + 1;
              final disabled = _isDisabled(m);
              final selected = m == _month && _year == widget.current.year;
              return GestureDetector(
                onTap: disabled ? null : () => Navigator.of(context).pop(DateTime(_year, m)),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : AppColors.bg2,
                    border: Border.all(
                      color: selected ? AppColors.primary : AppColors.border,
                    ),
                  ),
                  child: Text(
                    _monthNames[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: disabled
                          ? AppColors.textDisabled
                          : selected
                              ? Colors.white
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
