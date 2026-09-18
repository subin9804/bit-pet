// 02b · 루틴 관리 (RoutineManageBodyC 스타일)
// 검색창 + 종류 필터칩 + 루틴 카드 (타입아이콘·이름·주기·알람·액션행)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/app_toggle.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/pet_avatar.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';
import '../../pet/data/models/pet_models.dart';
import '../../pet/providers/pet_provider.dart';
import 'routine_form_screen.dart';
import '../../../core/theme/app_dimens.dart';

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


String _rtypeLabel(RoutineType t) => switch (t) {
      RoutineType.FEEDING  => '급여',
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
  (RoutineType.FEEDING,  '급여'),
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

  // 루틴 on/off 토글 로컬 상태 (낙관적 업데이트) — active 필드 제어, 홈 카드 노출 조건과 직결
  final Map<int, bool> _activeOverrides = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _routineOn(Routine r) => _activeOverrides[r.id] ?? r.isActive;

  Future<void> _toggleActive(Routine r) async {
    final next = !_routineOn(r);
    setState(() => _activeOverrides[r.id] = next);
    try {
      await ref.read(routineRepositoryProvider).updateRoutine(r.id, {
        'routineType': r.routineType.name,
        'title': r.title,
        'cycleDays': r.cycleDays,
        'alarmTime': r.alarmTime,
        'alarmEnabled': r.isAlarmEnabled,
        'active': next,
        if (r.memo != null) 'memo': r.memo,
      });
      ref.read(routineListProvider.notifier).load();
    } catch (_) {
      setState(() => _activeOverrides.remove(r.id));
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
        Container(
          decoration: const BoxDecoration(
            color: AppColors.bg2,
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: '루틴 이름 검색…',
              hintStyle: const TextStyle(
                  color: AppColors.textDisabled, fontSize: 13),
              prefixIcon: const Icon(Icons.search,
                  size: 20, color: AppColors.textSecondary),
              suffixIcon: _query.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                      child: const Icon(Icons.close,
                          size: 16, color: AppColors.textDisabled),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 4, vertical: 12),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.textPrimary),
              ),
            ),
          ),
        ),

        // ── 종류 필터칩 ─────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: SizedBox(
            height: AppChip.barHeight,
            child: routinesAsync.whenOrNull(data: (all) {
              return ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                children: _kFilters.map((f) {
                  final (type, label) = f;
                  final count = type == null
                      ? all.length
                      : all.where((r) => r.routineType == type).length;
                  return AppChip(
                    label: label,
                    count: count,
                    selected: _filterType == type,
                    margin: const EdgeInsets.only(right: 8),
                    onTap: () => setState(() => _filterType = type),
                  );
                }).toList(),
              );
            }),
          ),
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

              return ListView.builder(
                padding: const EdgeInsets.only(top: 12, bottom: 110),
                itemCount: visible.length,
                itemBuilder: (_, i) => _RoutineCard(
                  routine: visible[i],
                  routineOn: _routineOn(visible[i]),
                  onToggle: () => _toggleActive(visible[i]),
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
  final bool routineOn;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _RoutineCard({
    required this.routine,
    required this.routineOn,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r   = routine;
    final bg  = _rtypeBg(r.routineType);
    final ink = _rtypeInk(r.routineType);

    // 카드 한 장 = 루틴 하나. 예전엔 바닥선으로만 나눈 리스트 아이템이었는데,
    // 한 장 안에 정보 행 + 액션 행 4개가 들어 있어서 어디까지가 한 루틴인지가
    // 선 하나로는 안 읽혔다. 라운드와 옅은 그림자가 그 경계를 대신한다.
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      clipBehavior: Clip.antiAlias, // 액션 행이 카드 아래 모서리를 넘지 않게
      decoration: AppDecor.cardRaised,
      child: Column(
        children: [
          // ── 루틴 정보 행 ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      color: bg, borderRadius: AppRadius.brMd),
                  child: RecordTypeIcon(r.routineType.name,
                      size: 18, color: ink),
                ),
                const SizedBox(width: 12),
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
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 제목이 Flexible 이라 먼저 줄어들지만, 다 줄어든 뒤엔
                          // 배지 차례다. '365일마다' 처럼 긴 주기가 큰 글자와
                          // 겹치면 배지가 줄을 넘긴다.
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: const BoxDecoration(
                                  color: AppColors.bg2,
                                  borderRadius: AppRadius.brSm),
                              child: Text(
                                _cycleLabel(r),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_outlined,
                            size: 16,
                            color: routineOn
                                ? AppColors.textSecondary
                                : AppColors.textDisabled,
                          ),
                          const SizedBox(width: 4),
                          // Expanded 가 없으면 '시간 미설정 · 다음 D-14' 같은 긴
                          // 조합에서 가로로 넘친다. 제목과 달리 이 줄은 줄일 수
                          // 있는 정보라 말줄임이 맞다.
                          Expanded(
                            child: Text(
                              '${r.alarmTime ?? '시간 미설정'} · 다음 ${_nextLabel(r)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: routineOn
                                    ? AppColors.textSecondary
                                    : AppColors.textDisabled,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppToggle(value: routineOn, onToggle: onToggle),
              ],
            ),
          ),

          // ── 액션 행 ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bg2,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                _CardAction(
                  icon: Icons.person_outline,
                  label: '개체',
                  onTap: () => _openPetPickerSheet(context),
                ),
                Container(width: 1, height: 38, color: AppColors.divider),
                _CardAction(
                  icon: Icons.calendar_today_outlined,
                  label: '캘린더',
                  onTap: () => _openCalendarSheet(context),
                ),
                Container(width: 1, height: 38, color: AppColors.divider),
                _CardAction(
                  icon: Icons.edit_outlined,
                  label: '수정',
                  onTap: () => _openEditScreen(context),
                ),
                Container(width: 1, height: 38, color: AppColors.divider),
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
    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due   = DateTime(r.nextDueAt!.year, r.nextDueAt!.month, r.nextDueAt!.day);
    final diff  = due.difference(today).inDays;
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: c),
              const SizedBox(width: 4),
              // 넷이 한 줄을 나눠 쓰는 자리라, 시스템 글자 크기를 키운 기기에서
              // 라벨이 칸을 넘긴다. 아이콘은 남기고 글자만 줄인다.
              Flexible(
                child: Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c,
                    )),
              ),
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
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(color: AppColors.paleLine,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // 헤더
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CALENDAR',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.paleInk2, letterSpacing: 0.4)),
                const SizedBox(height: 4),
                Text('${widget.routine.title} · 수행 캘린더',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700,
                        color: AppColors.primary, letterSpacing: -0.4)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 스크롤 영역 — Flexible로 남은 공간 채우되 내용 적으면 줄어듦
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: logsAsync.when(
                loading: () => const Center(
                    child: Padding(padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator())),
                error: (e, _) => Text('$e'),
                data: (logs) {
                  // 로컬 날짜 기준 완료 petIds 집계
                  final completedByDay = <int, Set<int>>{};
                  for (final l in logs) {
                    final local = l.executedAt.toLocal();
                    if (local.year == _month.year &&
                        local.month == _month.month &&
                        l.status == RoutineLogStatus.COMPLETED) {
                      completedByDay.putIfAbsent(local.day, () => {}).add(l.petId);
                    }
                  }

                  final totalPets = widget.routine.petIds.length;

                  // 주기 기반 예정일 계산 (nextDueAt을 앵커로 역/순방향)
                  final nextDue = widget.routine.nextDueAt;
                  final anchorDate = nextDue != null
                      ? DateTime(nextDue.toLocal().year,
                                 nextDue.toLocal().month,
                                 nextDue.toLocal().day)
                      : null;
                  final cycleDays = widget.routine.cycleDays;
                  final today = DateTime(now.year, now.month, now.day);

                  // 시작일 하한 — 시작일 이전은 예정 표시하지 않음
                  final start = widget.routine.startDate?.toLocal();
                  final startDay = start != null
                      ? DateTime(start.year, start.month, start.day)
                      : null;

                  bool isScheduled(int d) {
                    if (anchorDate == null || cycleDays <= 0) return false;
                    final cell = DateTime(_month.year, _month.month, d);
                    if (cell.isAfter(today)) return false;
                    if (startDay != null && cell.isBefore(startDay)) return false;
                    final diff = anchorDate.difference(cell).inDays.abs();
                    return diff % cycleDays == 0;
                  }

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
                          child: AppIcon(AppIcons.chevronRight, size: 20,
                              color: isCurMonth ? AppColors.paleLine : AppColors.paleInk2),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      // 요일 헤더
                      Row(
                        children: _wk.map((w) => Expanded(
                          child: Text(w, textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 11,
                                  fontWeight: FontWeight.w700, color: AppColors.paleInk3)),
                        )).toList(),
                      ),
                      const SizedBox(height: 8),
                      // 날짜 그리드
                      GridView.count(
                        crossAxisCount: 7,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 4, crossAxisSpacing: 4,
                        children: [
                          ...List.filled(firstWd, const SizedBox.shrink()),
                          ...List.generate(daysInMonth, (i) {
                            final d         = i + 1;
                            final sel       = _selDay == d;
                            final isToday   = isCurMonth && d == now.day;
                            final scheduled = isScheduled(d);
                            final doneCount = completedByDay[d]?.length ?? 0;
                            final allDone   = scheduled && totalPets > 0 && doneCount >= totalPets;
                            final missed    = scheduled && !allDone;

                            Color? bgColor;
                            BoxBorder? border;
                            Color textColor = AppColors.primary;

                            if (sel) {
                              bgColor   = AppColors.paleInk2;
                              textColor = AppColors.paleBg;
                            } else if (allDone) {
                              bgColor   = ink;
                              textColor = AppColors.paleBg;
                            } else if (missed) {
                              bgColor = Colors.transparent;
                              border  = Border.all(color: ink, width: 1.5);
                            } else if (isToday) {
                              bgColor = AppColors.paleBgAlt;
                            }

                            return GestureDetector(
                              onTap: () => setState(() => _selDay = sel ? null : d),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: AppRadius.brMd,
                                  color: bgColor,
                                  border: border,
                                ),
                                child: Center(
                                  child: Text('$d',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12, fontWeight: FontWeight.w700,
                                        color: textColor,
                                      )),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // 범례
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _Leg(color: ink, label: '전체 완료'),
                        const SizedBox(width: 16),
                        _Leg(color: ink, label: '예정/부분완료', outlined: true),
                      ]),

                      // ── 선택일 개체 리스트 ──
                      if (_selDay != null) ...[
                        const SizedBox(height: 32),
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
            const SizedBox(height: 16),

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
      const SizedBox(width: 8),
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
    // 개체 지정색은 걷어냈다 — 저장된 hex 를 그대로 칠하던 자리다.
    // 자세한 이유는 core/theme/pale_palette.dart 주석 참고.
    return AppColors.paleBgAlt;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: done ? AppColors.primary.withValues(alpha: 0.08) : AppColors.paleBgAlt,
        borderRadius: AppRadius.brPill,
        border: Border.all(
          color: done ? AppColors.primary.withValues(alpha: 0.25) : AppColors.paleLine,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18, height: 18,
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(color: _bg, shape: BoxShape.circle),
            child: pet.profileImageUrl != null
                ? Image.network(pet.profileImageUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink())
                : null,
          ),
          const SizedBox(width: 8),
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
  final bool outlined;
  const _Leg({required this.color, required this.label, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: outlined ? Colors.transparent : color,
          border: outlined ? Border.all(color: color, width: 1.5) : null,
        ),
      ),
      const SizedBox(width: 4),
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
    // 개체 지정색은 걷어냈다 — 저장된 hex 를 그대로 칠하던 자리다.
    // 자세한 이유는 core/theme/pale_palette.dart 주석 참고.
    return AppColors.paleBgAlt;
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
              margin: const EdgeInsets.only(top: 8, bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.paleLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // ── 헤더 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: AppRadius.brPill,
                  ),
                  child: RecordTypeIcon(widget.routine.routineType.name,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 8),
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
                      horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: AppRadius.brPill,
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
          const SizedBox(height: 16),
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
                      const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                          borderRadius: AppRadius.brMd,
                          color: on ? bg : AppColors.bg2,
                          border: Border.all(
                            color: on ? ink : AppColors.border,
                            width: on ? 1.5 : 1,
                          ),
                        ),
                        padding:
                            const EdgeInsets.fromLTRB(8, 12, 8, 8),
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                PetAvatar(
                                  imageUrl: p.profileImageUrl,
                                  size: 46,
                                  background: on
                                      ? Colors.white.withValues(alpha: 0.55)
                                      : petColor,
                                  iconColor: ink,
                                  subcategory: p.speciesSubcategory,
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
                                          size: 12,
                                          color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              p.speciesName,
                              style: const TextStyle(
                                fontSize: 9.5,
                                color: AppColors.textDisabled,
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
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.brMd,
                      color: AppColors.bg2,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text('취소',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
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
                          const EdgeInsets.symmetric(vertical: 16),
                      color: _saving
                          ? AppColors.textDisabled
                          : AppColors.primary,
                      child: _saving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
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
                                      color: Colors.white,
                                    )),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  color: Colors.white.withValues(alpha: 0.18),
                                  child: Text(
                                    '${_selectedIds.length}마리',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
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
