// 04b · 개체 프로필 — 루틴 탭 (handoff 기준 재작성)
// 상단 "루틴 추가" 버튼 → AddPetToRoutinesSheet
// 오늘/예정 섹션 분리 · 카드 탭 → 미니 캘린더 토글 · 오늘 완료 + 해제
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pale_palette.dart';
import '../../../core/widgets/app_chip.dart';
import '../../../core/widgets/confirm_modal.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';

// ── 타입별 색·아이콘 ──────────────────────────────────────────────

Color _rtypeBg(RoutineType t) => switch (t) {
      RoutineType.FEEDING  => AppColors.petPeach,
      RoutineType.CLEANING => AppColors.petSky,
      RoutineType.WEIGHT   => AppColors.petSage,
      RoutineType.CUSTOM   => AppColors.petLilac,
    };

IconData _rtypeIcon(RoutineType t) => switch (t) {
      RoutineType.FEEDING  => Icons.restaurant_outlined,
      RoutineType.CLEANING => Icons.cleaning_services_outlined,
      RoutineType.WEIGHT   => Icons.monitor_weight_outlined,
      RoutineType.CUSTOM   => Icons.star_outline,
    };

String _cycleLabel(Routine r) {
  if (r.cycleDays == 1) return '매일';
  if (r.cycleDays == 7) return '매주';
  if (r.cycleDays == 30) return '월 1회';
  return '${r.cycleDays}일마다';
}

bool _isToday(Routine r) {
  if (r.nextDueAt == null) return false;
  final n = DateTime.now();
  final d = r.nextDueAt!;
  return d.year == n.year && d.month == n.month && d.day == n.day;
}

// ════════════════════════════════════════════════════════════════

class PetRoutineTab extends ConsumerStatefulWidget {
  final int petId;
  final PetPaletteKey paletteKey;

  const PetRoutineTab({
    super.key,
    required this.petId,
    required this.paletteKey,
  });

  @override
  ConsumerState<PetRoutineTab> createState() => _PetRoutineTabState();
}

class _PetRoutineTabState extends ConsumerState<PetRoutineTab> {

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (_) => _AddPetToRoutinesSheet(
        petId: widget.petId,
        onClose: () => Navigator.pop(context),
        onAdded: () {
          Navigator.pop(context);
          ref.invalidate(routinesForPetProvider(widget.petId));
        },
      ),
    );
  }

  void _removeRoutine(int routineId) async {
    try {
      await ref.read(routineRepositoryProvider)
          .unsubscribePet(routineId, widget.petId);
      ref.invalidate(routinesForPetProvider(widget.petId));
    } catch (e) {
      if (mounted) showToast(context, '오류: $e');
    }
  }

  Future<int?> _completeToday(int routineId) async {
    try {
      final log = await ref.read(routineRepositoryProvider).completeIndividual(
        routineId,
        RoutineCompleteIndividualRequest(
          petId: widget.petId,
          status: RoutineLogStatus.COMPLETED,
          executedAt: DateTime.now(),
        ),
      );
      if (mounted) showToast(context, '완료로 기록했습니다.', type: ToastType.success);
      return log?.id;
    } catch (e) {
      if (mounted) showToast(context, '오류: $e', type: ToastType.error);
      return null;
    }
  }

  Future<void> _undoToday(int logId) async {
    try {
      await ref.read(routineRepositoryProvider).deleteLog(logId);
      if (mounted) showToast(context, '완료 기록을 삭제했어요.', type: ToastType.success);
    } catch (e) {
      if (mounted) showToast(context, '오류: $e', type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routinesForPetProvider(widget.petId));
    final pale    = PalePalette.pale(widget.paletteKey);
    final paleInk = PalePalette.ink(widget.paletteKey);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 루틴 추가 버튼 ────────────────────────────────────
        GestureDetector(
          onTap: _openAddSheet,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.zero,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add, color: AppColors.paleBg, size: 18),
                SizedBox(width: 6),
                Text('루틴 추가',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                      color: AppColors.paleBg,
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── 루틴 목록 ─────────────────────────────────────────
        routinesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => EmptyState(message: e.toString()),
          data: (routines) {
            if (routines.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: EmptyState(
                  message: '연결된 루틴이 없어요',
                  subMessage: '"루틴 추가"로 이미 만들어진 루틴에 이 개체를 추가하세요',
                  icon: Icons.schedule_outlined,
                ),
              );
            }

            final todays   = routines.where((r) => _isToday(r.routine)).toList();
            final upcoming = routines.where((r) => !_isToday(r.routine)).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todays.isNotEmpty) ...[
                  _SectionHeader(label: '오늘', count: todays.length, accent: paleInk),
                  const SizedBox(height: 10),
                  ...todays.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RoutineCard(
                      item: item,
                      petId: widget.petId,
                      pale: pale,
                      paleInk: paleInk,
                      isToday: true,
                      onComplete: () => _completeToday(item.routine.id),
                      onUndo: (logId) => _undoToday(logId),
                      onRemove: () => _removeRoutine(item.routine.id),
                    ),
                  )),
                  const SizedBox(height: 10),
                ],
                if (upcoming.isNotEmpty) ...[
                  _SectionHeader(label: '예정 루틴', count: upcoming.length),
                  const SizedBox(height: 10),
                  ...upcoming.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RoutineCard(
                      item: item,
                      petId: widget.petId,
                      pale: pale,
                      paleInk: paleInk,
                      isToday: false,
                      onComplete: () async => null,
                      onUndo: (_) async {},
                      onRemove: () => _removeRoutine(item.routine.id),
                    ),
                  )),
                ],
              ],
            );
          },
        ),

      ],
    );
  }
}

// ── 섹션 헤더 ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color? accent;

  const _SectionHeader({required this.label, required this.count, this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (accent != null) ...[
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
        ],
        Text(label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent != null ? AppColors.primary : AppColors.paleInk2,
              letterSpacing: -0.2,
            )),
        const SizedBox(width: 6),
        Text('$count',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.paleInk3,
            )),
      ],
    );
  }
}

// ── 루틴 카드 ─────────────────────────────────────────────────────

class _RoutineCard extends ConsumerStatefulWidget {
  final RoutineWithSubscription item;
  final int petId;
  final Color pale;
  final Color paleInk;
  final bool isToday;
  final Future<int?> Function() onComplete;
  final Future<void> Function(int logId) onUndo;
  final VoidCallback onRemove;

  const _RoutineCard({
    required this.item,
    required this.petId,
    required this.pale,
    required this.paleInk,
    required this.isToday,
    required this.onComplete,
    required this.onUndo,
    required this.onRemove,
  });

  @override
  ConsumerState<_RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends ConsumerState<_RoutineCard> {
  bool _calOpen = false;
  late bool _done;
  int? _logId;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _done = widget.item.todayCompleted;
    _logId = widget.item.todayLogId;
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.item.routine;
    final hasAlarm = r.isAlarmEnabled && r.alarmTime != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(
          color: widget.isToday ? widget.paleInk : AppColors.paleLine,
          width: widget.isToday ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.zero,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ── 카드 본문 (탭 → 캘린더 토글) ─────────────────────
          GestureDetector(
            onTap: () => setState(() => _calOpen = !_calOpen),
            child: Container(
              color: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
              child: Row(
                children: [
                  // 타입 아이콘 (개체 파스텔 색 배경)
                  Container(
                    width: 38, height: 38,
                    decoration: BoxDecoration(
                      color: widget.pale,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Icon(_rtypeIcon(r.routineType),
                        size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(r.title,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.paleBgAlt,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(_cycleLabel(r),
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.paleInk2,
                                  )),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              size: 13,
                              color: hasAlarm
                                  ? AppColors.paleInk2
                                  : AppColors.paleInk3,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _nextLabel(r),
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: hasAlarm
                                    ? AppColors.primary
                                    : AppColors.paleInk3,
                              ),
                            ),
                            if (!hasAlarm) ...[
                              const SizedBox(width: 5),
                              const Text('· 알람 꺼짐',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.paleInk3,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  // 오늘 배지
                  if (widget.isToday && !_done)
                    Container(
                      margin: const EdgeInsets.only(left: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: widget.paleInk,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Text('오늘',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.paleBg,
                          )),
                    ),
                  // 셰브론
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 150),
                    turns: _calOpen ? 0.5 : 0,
                    child: const Icon(Icons.keyboard_arrow_down,
                        size: 18, color: AppColors.paleInk3),
                  ),
                ],
              ),
            ),
          ),

          // ── 미니 캘린더 (펼쳤을 때) ──────────────────────────
          if (_calOpen)
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.paleLineSoft)),
              ),
              child: _MiniRoutineCalendar(
                routineId: r.id,
                petId: widget.petId,
                cycleDays: r.cycleDays,
                nextDueAt: r.nextDueAt,
                startDate: r.startDate,
                accentColor: widget.paleInk,
              ),
            ),

          // ── 액션 행 ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                // 오늘 완료 버튼 (오늘 루틴만 활성)
                Expanded(
                  child: widget.isToday
                      ? GestureDetector(
                          onTap: _toggling ? null : () async {
                            setState(() => _toggling = true);
                            try {
                              if (_done && _logId != null) {
                                await widget.onUndo(_logId!);
                                if (mounted) setState(() { _done = false; _logId = null; });
                              } else if (!_done) {
                                final logId = await widget.onComplete();
                                if (mounted) setState(() { _done = true; _logId = logId; });
                              }
                            } finally {
                              if (mounted) setState(() => _toggling = false);
                            }
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: _done ? widget.pale : AppColors.primary,
                              border: _done
                                  ? Border.all(color: widget.paleInk)
                                  : null,
                              borderRadius: BorderRadius.zero,
                            ),
                            child: _toggling
                                ? SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: _done ? AppColors.primary : AppColors.paleBg,
                                    ))
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _done ? Icons.check_circle_outline : Icons.check,
                                  size: 14,
                                  color: _done ? AppColors.primary : AppColors.paleBg,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _done ? '오늘 완료됨' : '오늘 완료',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _done
                                        ? AppColors.primary
                                        : AppColors.paleBg,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.paleBgAlt,
                            border: Border.all(color: AppColors.paleLine),
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.check,
                                  size: 14, color: AppColors.paleInk3),
                              SizedBox(width: 6),
                              Text('오늘 완료',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.paleInk3,
                                  )),
                            ],
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                // 해제(휴지통) 버튼
                GestureDetector(
                  onTap: () async {
                    final r = widget.item.routine;
                    final ok = await ConfirmModal.show(
                      context,
                      title: '루틴 해제',
                      message: '\'${r.title}\' 루틴에서 이 개체를 해제할까요?\n기존에 기록된 데이터는 삭제되지 않아요.',
                      confirmLabel: '해제',
                      cancelLabel: '취소',
                    );
                    if (ok == true) widget.onRemove();
                  },
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      border: Border.all(color: AppColors.paleLine),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: const Icon(Icons.link_off,
                        size: 18, color: AppColors.paleInk3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _nextLabel(Routine r) {
    if (r.alarmTime == null) return '알람 미설정';
    final hm = r.alarmTime!;

    final now   = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // nextDueAt → lastExecutedAt+cycle → today+cycle 순으로 추정
    DateTime? nextDue = r.nextDueAt;
    if (nextDue == null && r.lastExecutedAt != null) {
      nextDue = r.lastExecutedAt!.add(Duration(days: r.cycleDays));
    }
    if (nextDue == null) {
      nextDue = today.add(Duration(days: r.cycleDays));
    }

    final dueDay = DateTime(nextDue.year, nextDue.month, nextDue.day);
    final diff   = dueDay.difference(today).inDays;

    if (diff <= 0) return '오늘 $hm';
    if (diff == 1) return '내일 $hm';
    return '${nextDue.month}/${nextDue.day} $hm';
  }
}

// ── 미니 루틴 캘린더 ─────────────────────────────────────────────

class _MiniRoutineCalendar extends ConsumerStatefulWidget {
  final int routineId;
  final int petId;
  final int cycleDays;
  final DateTime? nextDueAt;
  final DateTime? startDate;
  final Color accentColor;

  const _MiniRoutineCalendar({
    required this.routineId,
    required this.petId,
    required this.cycleDays,
    this.nextDueAt,
    this.startDate,
    required this.accentColor,
  });

  @override
  ConsumerState<_MiniRoutineCalendar> createState() =>
      _MiniRoutineCalendarState();
}

class _MiniRoutineCalendarState
    extends ConsumerState<_MiniRoutineCalendar> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  void _prev() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));
  void _next() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1));

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(routineLogsProvider(widget.routineId));

    return logsAsync.when(
      loading: () => const Center(
          child: SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(strokeWidth: 2))),
      error: (_, __) => const SizedBox.shrink(),
      data: (logs) {
        // 이 개체의 완료 기록만 day 집합
        final completedDays = <int>{};
        for (final l in logs) {
          if (l.petId == widget.petId &&
              l.executedAt.year == _month.year &&
              l.executedAt.month == _month.month &&
              l.status == RoutineLogStatus.COMPLETED) {
            completedDays.add(l.executedAt.day);
          }
        }

        final now    = DateTime.now();
        final today  = DateTime(now.year, now.month, now.day);
        final anchor = widget.nextDueAt != null
            ? DateTime(widget.nextDueAt!.toLocal().year,
                       widget.nextDueAt!.toLocal().month,
                       widget.nextDueAt!.toLocal().day)
            : null;
        final cycle  = widget.cycleDays;
        final start  = widget.startDate?.toLocal();
        final startDay = start != null
            ? DateTime(start.year, start.month, start.day)
            : null;

        bool isScheduled(int d) {
          if (anchor == null || cycle <= 0) return false;
          final cell = DateTime(_month.year, _month.month, d);
          if (cell.isAfter(today)) return false;
          if (startDay != null && cell.isBefore(startDay)) return false;
          return anchor.difference(cell).inDays.abs() % cycle == 0;
        }

        final firstWd = DateTime(_month.year, _month.month, 1).weekday % 7;
        final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
        final cells = <int?>[
          ...List.filled(firstWd, null),
          ...List.generate(daysInMonth, (i) => i + 1),
        ];

        return Column(
          children: [
            // 월 이동
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _prev,
                  child: const Icon(Icons.chevron_left,
                      size: 16, color: AppColors.paleInk3),
                ),
                Text(
                  '${_month.year}.${_month.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.paleInk2,
                  ),
                ),
                GestureDetector(
                  onTap: _next,
                  child: const Icon(Icons.chevron_right,
                      size: 16, color: AppColors.paleInk3),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // 요일 헤더
            Row(
              children: ['일', '월', '화', '수', '목', '금', '토'].map((w) {
                return Expanded(
                  child: Text(w,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: AppColors.paleInk3,
                      )),
                );
              }).toList(),
            ),
            const SizedBox(height: 2),
            // 날짜 그리드
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1.3,
              children: cells.map((d) {
                if (d == null) return const SizedBox.shrink();
                final scheduled = isScheduled(d);
                final done   = scheduled && completedDays.contains(d);
                final missed = scheduled && !done;
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.zero,
                    border: (done || missed)
                        ? Border.all(color: widget.accentColor, width: 1.5)
                        : null,
                    color: done ? widget.accentColor : Colors.transparent,
                  ),
                  child: Center(
                    child: Text('$d',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: done ? AppColors.paleBg : AppColors.paleInk3,
                        )),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 7),
            // 범례
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Legend(color: widget.accentColor, filled: true,  label: '완료'),
                const SizedBox(width: 12),
                _Legend(color: widget.accentColor, filled: false, label: '미완료'),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final bool filled;
  final String label;
  const _Legend({required this.color, required this.filled, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 11, height: 11,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.zero,
            color: filled ? color : Colors.transparent,
            border: filled ? null : Border.all(color: color, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600,
                color: AppColors.paleInk2)),
      ],
    );
  }
}

// ── AddPetToRoutinesSheet 오버레이 ────────────────────────────────

class _AddPetToRoutinesSheet extends ConsumerStatefulWidget {
  final int petId;
  final VoidCallback onClose;
  final VoidCallback onAdded;

  const _AddPetToRoutinesSheet({
    required this.petId,
    required this.onClose,
    required this.onAdded,
  });

  @override
  ConsumerState<_AddPetToRoutinesSheet> createState() =>
      _AddPetToRoutinesSheetState();
}

class _AddPetToRoutinesSheetState
    extends ConsumerState<_AddPetToRoutinesSheet> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  RoutineType? _filter;
  final Set<int> _picked = {};
  bool _saving = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _isJoined(Routine r, List<RoutineWithSubscription> joined) =>
      joined.any((j) => j.routine.id == r.id && j.subscribed);

  Future<void> _apply(List<Routine> all) async {
    if (_picked.isEmpty) return;
    setState(() => _saving = true);
    try {
      for (final id in _picked) {
        await ref.read(routineRepositoryProvider)
            .subscribePet(id, widget.petId);
      }
      if (mounted) widget.onAdded();
    } catch (e) {
      if (mounted) showToast(context, '오류: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allAsync    = ref.watch(routineListProvider);
    final joinedAsync = ref.watch(routinesForPetProvider(widget.petId));

    final allRoutines    = allAsync.valueOrNull    ?? <Routine>[];
    final joinedRoutines = joinedAsync.valueOrNull ?? <RoutineWithSubscription>[];

    final q = _query.toLowerCase();
    final visible = allRoutines.where((r) {
      final matchType  = _filter == null || r.routineType == _filter;
      final matchQuery = q.isEmpty ||
          r.title.toLowerCase().contains(q);
      return matchType && matchQuery;
    }).toList();
    final notJoined = visible.where((r) => !_isJoined(r, joinedRoutines)).toList();
    final joinedList = visible.where((r) => _isJoined(r, joinedRoutines)).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
              decoration: const BoxDecoration(
                color: AppColors.paleBg,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 핸들
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.fromLTRB(0, 10, 0, 0),
                      decoration: BoxDecoration(
                        color: AppColors.paleLine,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                  // 헤더
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ADD TO ROUTINE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.paleInk2,
                              letterSpacing: 0.4,
                            )),
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text('루틴에 추가',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: -0.4,
                                )),
                            const Spacer(),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                context.push('/routines/new');
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 7),
                                decoration: BoxDecoration(
                                  color: AppColors.card,
                                  border: Border.all(color: AppColors.paleLine),
                                  borderRadius: BorderRadius.zero,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.add, size: 14,
                                        color: AppColors.primary),
                                    SizedBox(width: 4),
                                    Text('새 루틴',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text(
                            '이미 만들어진 루틴에 이 개체를 추가합니다.',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.paleInk2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // 검색창
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        border: Border.all(color: AppColors.paleLine),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.primary),
                        decoration: const InputDecoration(
                          hintText: '루틴 이름 검색…',
                          hintStyle: TextStyle(
                              color: AppColors.paleInk3, fontSize: 13),
                          prefixIcon: Icon(Icons.search,
                              size: 18, color: AppColors.paleInk2),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // 종류 필터칩
                  SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      children: [
                        AppChip(
                          label: '전체',
                          count: allRoutines.length,
                          selected: _filter == null,
                          margin: const EdgeInsets.only(right: 6),
                          onTap: () => setState(() => _filter = null),
                        ),
                        ...RoutineType.values.map((t) {
                          final cnt =
                              allRoutines.where((r) => r.routineType == t).length;
                          final label = switch (t) {
                            RoutineType.FEEDING  => '급여',
                            RoutineType.CLEANING => '청소',
                            RoutineType.WEIGHT   => '체중',
                            RoutineType.CUSTOM   => '사용자',
                          };
                          return AppChip(
                            label: label,
                            count: cnt,
                            selected: _filter == t,
                            margin: const EdgeInsets.only(right: 6),
                            onTap: () =>
                                setState(() => _filter = _filter == t ? null : t),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 루틴 리스트
                  Expanded(
                    child: ListView.builder(
                      controller: ctrl,
                      padding: const EdgeInsets.fromLTRB(22, 10, 22, 10),
                      itemCount: notJoined.length + (joinedList.isNotEmpty ? 1 + joinedList.length : 0),
                      itemBuilder: (_, i) {
                        // 구분선 + 섹션 헤더
                        if (joinedList.isNotEmpty && i == notJoined.length) {
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
                            child: Row(
                              children: [
                                const Expanded(child: Divider(color: AppColors.paleLineSoft, height: 1)),
                                const SizedBox(width: 10),
                                Text('추가된 루틴 · ${joinedList.length}개',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                        color: AppColors.paleInk3)),
                                const SizedBox(width: 10),
                                const Expanded(child: Divider(color: AppColors.paleLineSoft, height: 1)),
                              ],
                            ),
                          );
                        }
                        final r = i < notJoined.length
                            ? notJoined[i]
                            : joinedList[i - notJoined.length - 1];
                        final joined = _isJoined(r, joinedRoutines);
                        final on = _picked.contains(r.id);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GestureDetector(
                            onTap: joined ? null : () => setState(() {
                              if (on) _picked.remove(r.id);
                              else _picked.add(r.id);
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                              decoration: BoxDecoration(
                                color: on ? AppColors.petPeach : AppColors.card,
                                border: Border.all(
                                  color: on ? AppColors.petPeachInk : AppColors.paleLine,
                                  width: on ? 1.5 : 1,
                                ),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Opacity(
                                opacity: joined ? 0.55 : 1.0,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40, height: 40,
                                      decoration: BoxDecoration(
                                        color: on
                                            ? Colors.white.withValues(alpha: 0.55)
                                            : _rtypeBg(r.routineType),
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Icon(_rtypeIcon(r.routineType),
                                          size: 20, color: AppColors.primary),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(r.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: AppColors.primary,
                                              )),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${_cycleLabel(r)} · ${r.alarmTime ?? "시간 미설정"} · ${r.petCount}마리',
                                            style: const TextStyle(
                                              fontFamily: 'monospace',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.paleInk2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (joined)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 9, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.paleBgAlt,
                                          border: Border.all(
                                              color: AppColors.paleLine),
                                          borderRadius:
                                              BorderRadius.zero,
                                        ),
                                        child: const Text('추가됨',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.paleInk2,
                                            )),
                                      )
                                    else
                                      AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 120),
                                        width: 22, height: 22,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.zero,
                                          color: on
                                              ? AppColors.petPeachInk
                                              : AppColors.paleBg,
                                          border: Border.all(
                                            color: on
                                                ? AppColors.petPeachInk
                                                : AppColors.paleLine,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: on
                                            ? const Icon(Icons.check,
                                                size: 13,
                                                color: AppColors.paleBg)
                                            : null,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // 푸터
                  Container(
                    padding: EdgeInsets.fromLTRB(
                        22, 12, 22,
                        MediaQuery.of(context).padding.bottom + 16),
                    decoration: const BoxDecoration(
                      color: AppColors.paleBg,
                      border: Border(
                          top: BorderSide(color: AppColors.paleLineSoft)),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              border: Border.all(color: AppColors.paleLine),
                              borderRadius: BorderRadius.zero,
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
                            onTap: _picked.isEmpty || _saving
                                ? null
                                : () => _apply(allRoutines),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _picked.isNotEmpty
                                    ? AppColors.primary
                                    : AppColors.paleLineSoft,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 18, height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.paleBg))
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('루틴에 추가',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                              color: _picked.isNotEmpty
                                                  ? AppColors.paleBg
                                                  : AppColors.paleInk3,
                                            )),
                                        if (_picked.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.18),
                                              borderRadius:
                                                  BorderRadius.zero,
                                            ),
                                            child: Text('${_picked.length}',
                                                style: const TextStyle(
                                                  fontFamily: 'monospace',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.paleBg,
                                                )),
                                          ),
                                        ],
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
      ),
    );
  }
}

