// Screen 02b: 내 개체 관리 - 루틴 탭 (v3.2)
// - 타입 필터칩, 드롭다운 아코디언
// - 루틴 헤더: 아이콘, 제목, 주기, 알람, 토글
// - 루틴 바디: 설정, 오늘의 진행, 캘린더
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';
import 'routine_today_check_sheet.dart';

class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  RoutineType? _filterType;

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routineListProvider);

    return Column(
      children: [
        // 타입 필터칩
        SizedBox(
          height: 50,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            children: [
              _TypeChip(
                label: '전체',
                count: routinesAsync.valueOrNull?.length ?? 0,
                selected: _filterType == null,
                onTap: () => setState(() => _filterType = null),
              ),
              const SizedBox(width: 8),
              ...RoutineType.values.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _TypeChip(
                    label: _typeName(t),
                    count: routinesAsync.valueOrNull
                            ?.where((r) => r.routineType == t)
                            .length ?? 0,
                    selected: _filterType == t,
                    onTap: () => setState(() => _filterType = t),
                  ),
                ),
              ),
            ],
          ),
        ),
        // 루틴 목록
        Expanded(
          child: routinesAsync.when(
            loading: () => const SkeletonCardList(),
            error: (e, _) => EmptyState(message: e.toString()),
            data: (all) {
              final routines = _filterType == null
                  ? all
                  : all
                      .where((r) => r.routineType == _filterType)
                      .toList();
              if (routines.isEmpty) {
                return const EmptyState(
                  message: '등록된 루틴이 없어요',
                  subMessage: '급여·청소·체중 측정 주기를 설정해보세요',
                  icon: Icons.schedule,
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: routines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) =>
                    _RoutineAccordion(routine: routines[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  String _typeName(RoutineType t) => switch (t) {
        RoutineType.FEEDING => '피딩',
        RoutineType.CLEANING => '청소',
        RoutineType.WEIGHT => '체중',
        RoutineType.CUSTOM => '사용자',
      };
}

// ── 타입 필터칩 ───────────────────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          '$label ${count > 0 ? count : ""}',
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight:
                selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ── 루틴 아코디언 ─────────────────────────────────────────────────────────────

class _RoutineAccordion extends ConsumerStatefulWidget {
  final Routine routine;
  const _RoutineAccordion({required this.routine});

  @override
  ConsumerState<_RoutineAccordion> createState() =>
      _RoutineAccordionState();
}

class _RoutineAccordionState extends ConsumerState<_RoutineAccordion> {
  bool _expanded = false;

  IconData get _icon => switch (widget.routine.routineType) {
        RoutineType.FEEDING => Icons.restaurant_outlined,
        RoutineType.CLEANING => Icons.cleaning_services_outlined,
        RoutineType.WEIGHT => Icons.monitor_weight_outlined,
        RoutineType.CUSTOM => Icons.star_outline,
      };

  Color get _iconBg => switch (widget.routine.routineType) {
        RoutineType.FEEDING => AppColors.petColorPeach,
        RoutineType.CLEANING => AppColors.petColorSky,
        RoutineType.WEIGHT => AppColors.petColorLavender,
        RoutineType.CUSTOM => AppColors.petColorButter,
      };

  String get _cycleLabel {
    final d = widget.routine.cycleDays;
    if (d == 1) return '매일';
    if (d == 7) return '매주';
    return '${d}일 주기';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.routine;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // 헤더
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _iconBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(_icon, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r.title, style: AppTextStyles.bodyBold),
                        Text(
                          '$_cycleLabel · ${r.alarmTime ?? "시간 미설정"} · ${r.petCount}마리',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  // 다음 알람
                  if (r.nextDueAt != null)
                    Text(
                      _formatNextAlarm(r.nextDueAt!),
                      style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary),
                    ),
                  const SizedBox(width: 8),
                  // 알람 토글
                  _AlarmToggle(routine: r),
                  const SizedBox(width: 4),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.textDisabled,
                  ),
                ],
              ),
            ),
          ),
          // 바디 (펼쳤을 때)
          if (_expanded) ...[
            const Divider(height: 1),
            _RoutineBody(routine: r),
          ],
        ],
      ),
    );
  }

  String _formatNextAlarm(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now).inDays;
    if (diff == 0) return '오늘';
    if (diff == 1) return '내일';
    if (diff < 0) return 'D+${-diff}';
    return 'D-$diff';
  }
}

// ── 알람 토글 스위치 ──────────────────────────────────────────────────────────

class _AlarmToggle extends ConsumerStatefulWidget {
  final Routine routine;
  const _AlarmToggle({required this.routine});

  @override
  ConsumerState<_AlarmToggle> createState() => _AlarmToggleState();
}

class _AlarmToggleState extends ConsumerState<_AlarmToggle> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const SizedBox(
            width: 36,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2))
        : Transform.scale(
            scale: 0.8,
            child: Switch(
              value: widget.routine.isAlarmEnabled,
              activeColor: AppColors.primary,
              onChanged: (v) => _toggle(v),
            ),
          );
  }

  Future<void> _toggle(bool value) async {
    setState(() => _loading = true);
    try {
      await ref.read(routineRepositoryProvider).updateRoutine(
            widget.routine.id,
            {'alarmEnabled': value},
          );
      ref.read(routineListProvider.notifier).load();
    } catch (e) {
      if (mounted) showToast(context, '오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

// ── 루틴 바디 ─────────────────────────────────────────────────────────────────

class _RoutineBody extends ConsumerWidget {
  final Routine routine;
  const _RoutineBody({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(routineTodayStatusProvider(routine.id));
    final logsAsync = ref.watch(routineLogsProvider(routine.id));

    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① 루틴 설정
          _SectionHeader(label: '루틴 설정'),
          const SizedBox(height: 8),
          Row(
            children: [
              _InfoCell(
                  title: '주기',
                  value: routine.cycleDays == 1 ? '매일' : '${routine.cycleDays}일'),
              _InfoCell(
                  title: '당일 시작',
                  value: routine.alarmTime ?? '-'),
            ],
          ),
          if (routine.lastExecutedAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '마지막 수행  ${_formatDt(routine.lastExecutedAt!)}',
                style: AppTextStyles.caption,
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: 루틴 수정 바텀시트
                  },
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    textStyle: AppTextStyles.caption,
                  ),
                  child: const Text('수정'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _confirmDelete(context, ref),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    textStyle: AppTextStyles.caption,
                  ),
                  child: const Text('삭제'),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          // ② 오늘의 진행
          _SectionHeader(label: '오늘의 진행'),
          const SizedBox(height: 8),
          todayAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) =>
                Text('상태 조회 실패', style: AppTextStyles.caption),
            data: (today) {
              if (today == null) {
                return Text('오늘 예정된 루틴이 아닙니다',
                    style: AppTextStyles.caption);
              }
              final pct = today.totalPetCount == 0
                  ? 0.0
                  : today.completedPetCount / today.totalPetCount;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '${today.completedPetCount} / ${today.totalPetCount} 완료',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: pct,
                      backgroundColor: AppColors.bg2,
                      color: AppColors.primary,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 개체 아바타 칩
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: today.petStatuses.map((s) {
                      return _PetStatusChip(status: s);
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  // 개체별 체크 처리 버튼
                  if (!today.isAllCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _openCheckSheet(context, today),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          textStyle: AppTextStyles.bodyBold
                              .copyWith(fontSize: 13),
                        ),
                        child: Text(
                          '✓ 개체별 체크 처리  '
                          '${today.totalPetCount - today.completedPetCount}마리 남음',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          const Divider(height: 24),

          // ③ 캘린더
          _SectionHeader(label: '캘린더'),
          const SizedBox(height: 8),
          logsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const SizedBox(),
            data: (logs) => _MiniCalendar(logs: logs),
          ),
        ],
      ),
    );
  }

  void _openCheckSheet(BuildContext context, TodayRoutine today) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoutineTodayCheckSheet(routine: today),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: Text('\"${routine.title}\" 루틴을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('삭제',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref
            .read(routineRepositoryProvider)
            .deleteRoutine(routine.id);
        ref.read(routineListProvider.notifier).load();
      } catch (e) {
        if (context.mounted) showToast(context, '삭제 실패: $e');
      }
    }
  }

  String _formatDt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return '오늘 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 1) return '어제 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    return '${diff.inDays}일 전';
  }
}

// ── 개체 상태 칩 ──────────────────────────────────────────────────────────────

class _PetStatusChip extends StatelessWidget {
  final TodayPetStatus status;
  const _PetStatusChip({required this.status});

  Color get _bg {
    if (status.colorCode == null) return AppColors.petColorMint;
    try {
      return Color(int.parse(status.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.petColorMint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.isCompleted ? _bg : AppColors.bg2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.isCompleted
              ? _bg.withValues(alpha: 0.5)
              : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _bg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              status.isCompleted ? Icons.check : Icons.pets,
              size: 12,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            status.petName,
            style: AppTextStyles.caption.copyWith(
              color: status.isCompleted
                  ? AppColors.textPrimary
                  : AppColors.textDisabled,
            ),
          ),
        ],
      ),
    );
  }
}

// ── 섹션 헤더 ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 12,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label,
            style: AppTextStyles.caption
                .copyWith(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
      ],
    );
  }
}

// ── 정보 셀 ───────────────────────────────────────────────────────────────────

class _InfoCell extends StatelessWidget {
  final String title;
  final String value;
  const _InfoCell({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.caption
                  .copyWith(color: AppColors.textDisabled)),
          Text(value, style: AppTextStyles.bodyBold),
        ],
      ),
    );
  }
}

// ── 미니 캘린더 ───────────────────────────────────────────────────────────────

class _MiniCalendar extends StatefulWidget {
  final List<RoutineLog> logs;
  const _MiniCalendar({required this.logs});

  @override
  State<_MiniCalendar> createState() => _MiniCalendarState();
}

class _MiniCalendarState extends State<_MiniCalendar> {
  late DateTime _month;
  DateTime? _selected;
  List<RoutineLog> _dayLogs = [];

  @override
  void initState() {
    super.initState();
    _month = DateTime(DateTime.now().year, DateTime.now().month);
  }

  Set<String> get _logDates => widget.logs.map((l) {
        final d = l.executedAt;
        return '${d.year}-${d.month}-${d.day}';
      }).toSet();

  void _selectDay(DateTime day) {
    setState(() {
      _selected = day;
      _dayLogs = widget.logs.where((l) {
        final d = l.executedAt;
        return d.year == day.year &&
            d.month == day.month &&
            d.day == day.day;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7;
    const weekdays = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 월 네비게이션
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 18),
              onPressed: () => setState(() {
                _month = DateTime(_month.year, _month.month - 1);
                _selected = null;
              }),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
            Expanded(
              child: Text(
                '${_month.year}. ${_month.month}',
                style: AppTextStyles.bodyBold,
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 18),
              onPressed: () => setState(() {
                _month = DateTime(_month.year, _month.month + 1);
                _selected = null;
              }),
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          ],
        ),
        // 요일 헤더
        Row(
          children: weekdays.map((d) {
            return Expanded(
              child: Center(
                child: Text(d,
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textDisabled)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
        // 날짜 그리드
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (_, i) {
            if (i < firstWeekday) return const SizedBox();
            final day = i - firstWeekday + 1;
            final date = DateTime(_month.year, _month.month, day);
            final key =
                '${date.year}-${date.month}-${date.day}';
            final hasLog = _logDates.contains(key);
            final isToday = _isToday(date);
            final isSelected = _selected != null &&
                _selected!.day == day &&
                _selected!.month == _month.month;

            return GestureDetector(
              onTap: () => _selectDay(date),
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : null,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? Colors.white
                          : isToday
                              ? AppColors.primary
                              : AppColors.textPrimary,
                      fontWeight: hasLog
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        // 선택된 날짜 로그
        if (_selected != null && _dayLogs.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_selected!.month}/${_selected!.day} 완료 ${_dayLogs.where((l) => l.status == RoutineLogStatus.COMPLETED).length}마리',
                  style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  bool _isToday(DateTime d) {
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }
}
