// 02b · 루틴 관리 (RoutineManageBodyC 스타일)
// 검색창 + 종류 필터칩 + 루틴 카드 (타입아이콘·이름·주기·알람·액션행)
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
import '../../pet/data/models/pet_models.dart';
import '../../pet/providers/pet_provider.dart';
import 'routine_form_screen.dart';

// ── 루틴 타입 색·아이콘·라벨 ────────────────────────────────────────

Color _rtypeBg(RoutineType t) => switch (t) {
      RoutineType.FEEDING  => AppColors.petPeach,
      RoutineType.CLEANING => AppColors.petSky,
      RoutineType.WEIGHT   => AppColors.petSage,
      RoutineType.CUSTOM   => AppColors.petLilac,
    };

Color _rtypeInk(RoutineType t) => switch (t) {
      RoutineType.FEEDING  => AppColors.petPeachInk,
      RoutineType.CLEANING => AppColors.petSkyInk,
      RoutineType.WEIGHT   => AppColors.petSageInk,
      RoutineType.CUSTOM   => AppColors.petLilacInk,
    };

IconData _rtypeIcon(RoutineType t) => switch (t) {
      RoutineType.FEEDING  => Icons.restaurant_outlined,
      RoutineType.CLEANING => Icons.cleaning_services_outlined,
      RoutineType.WEIGHT   => Icons.monitor_weight_outlined,
      RoutineType.CUSTOM   => Icons.star_outline,
    };

String _rtypeLabel(RoutineType t) => switch (t) {
      RoutineType.FEEDING  => '피딩',
      RoutineType.CLEANING => '청소',
      RoutineType.WEIGHT   => '체중',
      RoutineType.CUSTOM   => '사용자 정의',
    };

String _cycleLabel(Routine r) {
  if (r.cycleDays == 1) return '매일';
  if (r.cycleDays == 7) return '매주';
  if (r.cycleDays == 30) return '월 1회';
  return '${r.cycleDays}일마다';
}

// ── 필터 정의 ────────────────────────────────────────────────────

const _kFilters = [
  (null,               '전체'),
  (RoutineType.FEEDING,  '피딩'),
  (RoutineType.CLEANING, '청소'),
  (RoutineType.WEIGHT,   '체중'),
  (RoutineType.CUSTOM,   '사용자 정의'),
];

// ════════════════════════════════════════════════════════════════

class RoutineScreen extends ConsumerStatefulWidget {
  const RoutineScreen({super.key});

  @override
  ConsumerState<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends ConsumerState<RoutineScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  RoutineType? _filterType;

  // 알람 토글 로컬 상태 (낙관적 업데이트)
  final Map<int, bool> _alarmOverrides = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _alarmOn(Routine r) => _alarmOverrides[r.id] ?? r.isAlarmEnabled;

  Future<void> _toggleAlarm(Routine r) async {
    final next = !_alarmOn(r);
    setState(() => _alarmOverrides[r.id] = next);
    try {
      await ref.read(routineRepositoryProvider).updateRoutine(r.id, {
        'routineType': r.routineType.name,
        'title': r.title,
        'cycleDays': r.cycleDays,
        'alarmTime': r.alarmTime,
        'alarmEnabled': next,
        'active': r.isActive,
        if (r.memo != null) 'memo': r.memo,
      });
      ref.read(routineListProvider.notifier).load();
    } catch (_) {
      setState(() => _alarmOverrides.remove(r.id));
    }
  }

  Future<void> _deleteRoutine(Routine r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: Text('"${r.title}" 루틴을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('삭제')),
        ],
      ),
    );
    if (ok == true) {
      try {
        await ref.read(routineRepositoryProvider).deleteRoutine(r.id);
        ref.read(routineListProvider.notifier).load();
      } catch (e) {
        if (mounted) showToast(context, '삭제 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routineListProvider);

    return Column(
      children: [
        // ── 검색창 ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.paleLine),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(fontSize: 14, color: AppColors.primary),
              decoration: InputDecoration(
                hintText: '루틴 이름 검색…',
                hintStyle: const TextStyle(
                    color: AppColors.paleInk3, fontSize: 13),
                prefixIcon: const Icon(Icons.search,
                    size: 18, color: AppColors.paleInk2),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                        child: const Icon(Icons.close,
                            size: 16, color: AppColors.paleInk3),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 11),
                border: InputBorder.none,
              ),
            ),
          ),
        ),

        // ── 종류 필터칩 ─────────────────────────────────────────
        SizedBox(
          height: 46,
          child: routinesAsync.whenOrNull(data: (all) {
            return ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              children: _kFilters.map((f) {
                final (type, label) = f;
                final active = _filterType == type;
                final count = type == null
                    ? all.length
                    : all.where((r) => r.routineType == type).length;
                return GestureDetector(
                  onTap: () => setState(() => _filterType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(999),
                      border: active
                          ? null
                          : Border.all(color: AppColors.paleLine),
                    ),
                    child: Row(
                      children: [
                        Text(label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? AppColors.paleBg
                                  : AppColors.primary,
                            )),
                        const SizedBox(width: 5),
                        Text('$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                              color: active
                                  ? AppColors.paleBg.withValues(alpha: 0.6)
                                  : AppColors.paleInk3,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),
        ),

        // ── 루틴 목록 ───────────────────────────────────────────
        Expanded(
          child: routinesAsync.when(
            loading: () => const SkeletonCardList(),
            error: (e, _) => EmptyState(message: e.toString()),
            data: (all) {
              final q = _query.toLowerCase();
              final visible = all.where((r) {
                final matchType =
                    _filterType == null || r.routineType == _filterType;
                final matchQuery = q.isEmpty ||
                    r.title.toLowerCase().contains(q) ||
                    _rtypeLabel(r.routineType).contains(_query);
                return matchType && matchQuery;
              }).toList();

              if (visible.isEmpty) {
                return EmptyState(
                  message: _query.isNotEmpty ? '검색 결과가 없어요' : '등록된 루틴이 없어요',
                  subMessage: _query.isEmpty
                      ? '급여·청소·체중 측정 주기를 설정해보세요'
                      : null,
                  icon: Icons.schedule,
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 110),
                itemCount: visible.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _RoutineCard(
                  routine: visible[i],
                  alarmOn: _alarmOn(visible[i]),
                  onToggleAlarm: () => _toggleAlarm(visible[i]),
                  onDelete: () => _deleteRoutine(visible[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// 루틴 카드 (RoutineManageBodyC 스타일)
// ════════════════════════════════════════════════════════════════

class _RoutineCard extends ConsumerWidget {
  final Routine routine;
  final bool alarmOn;
  final VoidCallback onToggleAlarm;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.routine,
    required this.alarmOn,
    required this.onToggleAlarm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r   = routine;
    final bg  = _rtypeBg(r.routineType);
    final ink = _rtypeInk(r.routineType);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.paleLine),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // ── 카드 헤더 ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
            child: Row(
              children: [
                // 타입 아이콘
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(_rtypeIcon(r.routineType),
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 11),
                // 이름 + 주기칩 + 알람행
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              r.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppColors.primary,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.paleBgAlt,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _cycleLabel(r),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.paleInk2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            size: 13,
                            color: alarmOn
                                ? AppColors.paleInk2
                                : AppColors.paleInk3,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${r.alarmTime ?? '시간 미설정'} · 다음 ${_nextLabel(r)}',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: alarmOn
                                  ? AppColors.paleInk2
                                  : AppColors.paleInk3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 알람 토글
                const SizedBox(width: 8),
                _PaleToggle(on: alarmOn, onToggle: onToggleAlarm),
              ],
            ),
          ),

          // ── 액션 행 ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.paleLineSoft)),
            ),
            child: Row(
              children: [
                _CardAction(
                  icon: Icons.person_outline,
                  label: '개체',
                  onTap: () => _openPetPickerSheet(context),
                ),
                Container(width: 1, height: 40, color: AppColors.paleLineSoft),
                _CardAction(
                  icon: Icons.calendar_today_outlined,
                  label: '캘린더',
                  onTap: () => _openCalendarSheet(context),
                ),
                Container(width: 1, height: 40, color: AppColors.paleLineSoft),
                _CardAction(
                  icon: Icons.edit_outlined,
                  label: '수정',
                  onTap: () => _openEditScreen(context),
                ),
                Container(width: 1, height: 40, color: AppColors.paleLineSoft),
                _CardAction(
                  icon: Icons.delete_outline,
                  label: '삭제',
                  color: AppColors.error.withValues(alpha: 0.7),
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _nextLabel(Routine r) {
    if (r.nextDueAt == null) return '미정';
    final diff = r.nextDueAt!.difference(DateTime.now()).inDays;
    if (diff < 0) return 'D+${-diff}';
    if (diff == 0) return '오늘';
    if (diff == 1) return '내일';
    return 'D-$diff';
  }

  void _openPetPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RoutinePetPickerSheet(routine: routine),
    );
  }

  void _openEditScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoutineFormScreen(initialRoutine: routine),
        fullscreenDialog: true,
      ),
    );
  }

  void _openCalendarSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalendarSheet(routine: routine),
    );
  }
}

// ── PALE 토글 ─────────────────────────────────────────────────────

class _PaleToggle extends StatelessWidget {
  final bool on;
  final VoidCallback onToggle;

  const _PaleToggle({required this.on, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 44,
        height: 26,
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.paleLine,
          borderRadius: BorderRadius.circular(13),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 20,
            height: 20,
            decoration: const BoxDecoration(
              color: AppColors.paleBg,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

// ── 카드 액션 버튼 ────────────────────────────────────────────────

class _CardAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.paleInk2;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

// ── 캘린더 바텀시트 ───────────────────────────────────────────────

class _CalendarSheet extends ConsumerStatefulWidget {
  final Routine routine;
  const _CalendarSheet({required this.routine});

  @override
  ConsumerState<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends ConsumerState<_CalendarSheet> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  int? _selDay = DateTime.now().day;

  static const _wk = ['일', '월', '화', '수', '목', '금', '토'];

  void _prevMonth() => setState(() { _month = DateTime(_month.year, _month.month - 1); _selDay = null; });
  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) {
      setState(() { _month = next; _selDay = null; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(routineLogsProvider(widget.routine.id));
    final petsAsync = ref.watch(petListProvider);
    final ink       = _rtypeInk(widget.routine.routineType);
    final now       = DateTime.now();
    final isCurMonth = _month.year == now.year && _month.month == now.month;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.78,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.paleBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
          // 핸들
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(color: AppColors.paleLine,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CALENDAR',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.paleInk2, letterSpacing: 0.4)),
                const SizedBox(height: 3),
                Text('${widget.routine.title} · 수행 캘린더',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                        color: AppColors.primary, letterSpacing: -0.4)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.paleLineSoft),
          // 스크롤 영역 — Flexible로 남은 공간 채우되 내용 적으면 줄어듦
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
              child: logsAsync.when(
                loading: () => const Center(
                    child: Padding(padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator())),
                error: (e, _) => Text('$e'),
                data: (logs) {
                  // 로컬 날짜 기준으로 완료 petIds 집계 (UTC→local 변환)
                  final completedByDay = <int, Set<int>>{};
                  for (final l in logs) {
                    final local = l.executedAt.toLocal();
                    if (local.year == _month.year &&
                        local.month == _month.month &&
                        l.status == RoutineLogStatus.COMPLETED) {
                      completedByDay.putIfAbsent(local.day, () => {}).add(l.petId);
                    }
                  }

                  // 달력 그리드
                  final firstWd = DateTime(_month.year, _month.month, 1).weekday % 7;
                  final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 월 네비게이션
                      Row(children: [
                        GestureDetector(
                          onTap: _prevMonth,
                          child: const Icon(Icons.chevron_left,
                              size: 20, color: AppColors.paleInk2),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              '${_month.year}년 ${_month.month}월',
                              style: const TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w700, color: AppColors.primary),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: isCurMonth ? null : _nextMonth,
                          child: Icon(Icons.chevron_right, size: 20,
                              color: isCurMonth ? AppColors.paleLine : AppColors.paleInk2),
                        ),
                      ]),
                      const SizedBox(height: 10),
                      // 요일 헤더
                      Row(
                        children: _wk.map((w) => Expanded(
                          child: Text(w, textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w700, color: AppColors.paleInk3)),
                        )).toList(),
                      ),
                      const SizedBox(height: 6),
                      // 날짜 그리드
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 4, crossAxisSpacing: 4,
                        children: [
                          ...List.filled(firstWd, const SizedBox.shrink()),
                          ...List.generate(daysInMonth, (i) {
                            final d    = i + 1;
                            final done = completedByDay.containsKey(d);
                            final sel  = _selDay == d;
                            final isToday = isCurMonth && d == now.day;
                            return GestureDetector(
                              onTap: () => setState(() => _selDay = sel ? null : d),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(7),
                                  color: sel
                                      ? ink
                                      : done
                                          ? AppColors.primary
                                          : isToday
                                              ? AppColors.paleBgAlt
                                              : Colors.transparent,
                                  border: (!sel && !done && !isToday)
                                      ? null
                                      : null,
                                ),
                                child: Center(
                                  child: Text('$d',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12, fontWeight: FontWeight.w700,
                                        color: (sel || done)
                                            ? AppColors.paleBg
                                            : AppColors.primary,
                                      )),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // 범례
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _Leg(color: AppColors.primary, label: '완료'),
                        const SizedBox(width: 16),
                        _Leg(color: ink, label: '선택'),
                      ]),

                      // ── 선택일 개체 리스트 ──
                      if (_selDay != null) ...[
                        const SizedBox(height: 20),
                        const Divider(height: 1, color: AppColors.paleLineSoft),
                        const SizedBox(height: 16),
                        _PetStatusSection(
                          selDay: _selDay!,
                          month: _month,
                          completedIds: completedByDay[_selDay!] ?? {},
                          allPetIds: widget.routine.petIds,
                          petsAsync: petsAsync,
                          ink: ink,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }
}

class _PetStatusSection extends StatelessWidget {
  final int selDay;
  final DateTime month;
  final Set<int> completedIds;
  final List<int> allPetIds;
  final AsyncValue<List<Pet>> petsAsync;
  final Color ink;

  const _PetStatusSection({
    required this.selDay,
    required this.month,
    required this.completedIds,
    required this.allPetIds,
    required this.petsAsync,
    required this.ink,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = '${month.month}월 ${selDay}일';

    return petsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const SizedBox.shrink(),
      data: (allPets) {
        final petMap = {for (final p in allPets) p.id: p};
        final completedPets  = completedIds.map((id) => petMap[id]).whereType<Pet>().toList();
        final notCompletedPets = allPetIds
            .where((id) => !completedIds.contains(id))
            .map((id) => petMap[id])
            .whereType<Pet>()
            .toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dateStr,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.primary, letterSpacing: -0.3)),
            const SizedBox(height: 14),

            if (completedPets.isNotEmpty || notCompletedPets.isNotEmpty) ...[
              _StatusLabel(label: '완료', color: AppColors.primary, count: completedPets.length),
              const SizedBox(height: 8),
              completedPets.isNotEmpty
                  ? Wrap(
                      spacing: 8, runSpacing: 8,
                      children: completedPets.map((p) => _PetChip(pet: p, done: true, ink: AppColors.primary)).toList(),
                    )
                  : Text('완료한 개체가 없어요',
                      style: const TextStyle(fontSize: 12, color: AppColors.paleInk3,
                          fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              _StatusLabel(label: '미완료', color: AppColors.paleInk2, count: notCompletedPets.length),
              const SizedBox(height: 8),
              notCompletedPets.isNotEmpty
                  ? Wrap(
                      spacing: 8, runSpacing: 8,
                      children: notCompletedPets.map((p) => _PetChip(pet: p, done: false, ink: ink)).toList(),
                    )
                  : Text('미완료 개체가 없어요',
                      style: const TextStyle(fontSize: 12, color: AppColors.paleInk3,
                          fontWeight: FontWeight.w500)),
            ] else
              Text('이 날의 기록이 없어요',
                  style: const TextStyle(fontSize: 13, color: AppColors.paleInk3,
                      fontWeight: FontWeight.w500)),
          ],
        );
      },
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final String label;
  final Color color;
  final int count;
  const _StatusLabel({required this.label, required this.color, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 8, height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(width: 4),
      Text('$count마리',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: AppColors.paleInk3)),
    ]);
  }
}

class _PetChip extends StatelessWidget {
  final Pet pet;
  final bool done;
  final Color ink;
  const _PetChip({required this.pet, required this.done, required this.ink});

  Color get _bg {
    if (pet.colorCode == null) return AppColors.paleBgAlt;
    try {
      return Color(int.parse(pet.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.paleBgAlt;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: done ? AppColors.primary.withValues(alpha: 0.08) : AppColors.paleBgAlt,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: done ? AppColors.primary.withValues(alpha: 0.25) : AppColors.paleLine,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(pet.name,
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: done ? AppColors.primary : AppColors.paleInk2,
              )),
        
        ],
      ),
    );
  }
}

class _Leg extends StatelessWidget {
  final Color color;
  final String label;
  const _Leg({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: color,
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.paleInk2)),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════
// 개체 구독 관리 바텀시트
// ════════════════════════════════════════════════════════════════

class _RoutinePetPickerSheet extends ConsumerStatefulWidget {
  final Routine routine;
  const _RoutinePetPickerSheet({required this.routine});

  @override
  ConsumerState<_RoutinePetPickerSheet> createState() =>
      _RoutinePetPickerSheetState();
}

class _RoutinePetPickerSheetState
    extends ConsumerState<_RoutinePetPickerSheet> {
  late Set<int> _selectedIds;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<int>.from(widget.routine.petIds);
  }

  Color _petBg(Pet p) {
    if (p.colorCode == null) return AppColors.paleBgAlt;
    try {
      return Color(int.parse(p.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.paleBgAlt;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final current = Set<int>.from(widget.routine.petIds);
    final next = Set<int>.from(_selectedIds);
    final repo = ref.read(routineRepositoryProvider);
    try {
      for (final id in next.difference(current)) {
        await repo.subscribePet(widget.routine.id, id);
      }
      for (final id in current.difference(next)) {
        await repo.unsubscribePet(widget.routine.id, id);
      }
      ref.read(routineListProvider.notifier).load();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        showToast(context, '저장 실패: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final petsAsync = ref.watch(petListProvider);
    final bg  = _rtypeBg(widget.routine.routineType);
    final ink = _rtypeInk(widget.routine.routineType);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 핸들 ──
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.paleLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── 헤더 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_rtypeIcon(widget.routine.routineType),
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('개체 추가·제거', style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.paleInk2, letterSpacing: 0.3,
                      )),
                      Text(widget.routine.title, style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700,
                        color: AppColors.primary, letterSpacing: -0.3,
                      )),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_selectedIds.length}마리',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                      color: ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.paleLineSoft),
          // ── 개체 그리드 ──
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.48,
            ),
            child: petsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$e',
                      style: const TextStyle(color: AppColors.paleInk3)),
                ),
              ),
              data: (pets) {
                if (pets.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(
                      child: Text('등록된 개체가 없어요',
                          style: TextStyle(color: AppColors.paleInk3)),
                    ),
                  );
                }
                return GridView.builder(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.fromLTRB(22, 14, 22, 14),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.88,
                  ),
                  itemCount: pets.length,
                  itemBuilder: (_, i) {
                    final p   = pets[i];
                    final on  = _selectedIds.contains(p.id);
                    final petColor = _petBg(p);
                    return GestureDetector(
                      onTap: () => setState(() {
                        if (on) _selectedIds.remove(p.id);
                        else    _selectedIds.add(p.id);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 130),
                        decoration: BoxDecoration(
                          color: on ? bg : AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: on ? ink : AppColors.paleLine,
                            width: on ? 1.5 : 1,
                          ),
                        ),
                        padding:
                            const EdgeInsets.fromLTRB(8, 12, 8, 10),
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 46, height: 46,
                                  decoration: BoxDecoration(
                                    color: on
                                        ? AppColors.paleBg
                                            .withValues(alpha: 0.55)
                                        : petColor,
                                    borderRadius:
                                        BorderRadius.circular(13),
                                  ),
                                  child: const Center(
                                    child: Text('🦎',
                                        style:
                                            TextStyle(fontSize: 22)),
                                  ),
                                ),
                                if (on)
                                  Positioned(
                                    top: -4, right: -4,
                                    child: Container(
                                      width: 18, height: 18,
                                      decoration: BoxDecoration(
                                        color: ink,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check,
                                          size: 11,
                                          color: AppColors.paleBg),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 7),
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: AppColors.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              p.speciesName,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.paleInk3,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // ── 푸터 ──
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  top: BorderSide(color: AppColors.paleLineSoft)),
            ),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.paleLine),
                    ),
                    child: const Text('취소',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.primary,
                        )),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GestureDetector(
                    onTap: _saving ? null : _save,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      alignment: Alignment.center,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _saving
                            ? AppColors.paleLine
                            : AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.paleBg,
                              ),
                            )
                          : Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                const Text('저장',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.paleBg,
                                    )),
                                const SizedBox(width: 6),
                                Container(
                                  padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.paleBg
                                        .withValues(alpha: 0.18),
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${_selectedIds.length}마리',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.paleBg,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
