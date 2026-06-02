// SCR-08: 개체 상세 — 루틴 탭 (handoff 04b v2 반영)
// ⭐ 변경 사항: 14일 타임라인 삭제 / 최근 기록 더보기(3건씩) / 퀵액션 2단
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pale_palette.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';

// ── RoutineTab ────────────────────────────────────────────────
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
  int? _expandedId;

  @override
  Widget build(BuildContext context) {
    final routinesAsync = ref.watch(routinesForPetProvider(widget.petId));

    return routinesAsync.when(
      loading: () => Column(
        children: List.generate(3, (i) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SkeletonBox(width: double.infinity, height: 64, borderRadius: 14),
        )),
      ),
      error: (e, _) => EmptyState(message: e.toString()),
      data: (routines) {
        if (routines.isEmpty) {
          return const EmptyState(
            message: '연결된 루틴이 없어요',
            subMessage: '루틴 관리에서 루틴을 만들고 개체를 연결하세요',
            icon: Icons.schedule_outlined,
          );
        }
        return Column(
          children: [
            ...routines.map((item) {
              final r = item.routine;
              if (_expandedId == r.id) {
                return _RoutineCardExpanded(
                  key: ValueKey('exp_${r.id}'),
                  item: item,
                  paletteKey: widget.paletteKey,
                  onCollapse: () => setState(() => _expandedId = null),
                  onToggleAlarm: (val) => _handleToggle(r.id, val),
                  onComplete: () => _handleComplete(r.id),
                  onSkip: () => _handleSkip(r.id),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _RoutineCardCompact(
                  item: item,
                  paletteKey: widget.paletteKey,
                  onExpand: () => setState(() => _expandedId = r.id),
                ),
              );
            }),
            const SizedBox(height: 4),
            // 새 루틴 추가 점선 버튼
            GestureDetector(
              onTap: () {
                // TODO: 루틴 생성 화면(02d)으로 이동
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: AppColors.paleLine, width: 1.5,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 18, color: AppColors.paleInk2),
                    const SizedBox(width: 6),
                    Text('새 루틴 추가',
                        style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.paleInk2)),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleToggle(int routineId, bool val) async {
    try {
      await ref.read(routineRepositoryProvider)
          .updateRoutine(routineId, {'alarmEnabled': val});
      ref.invalidate(routinesForPetProvider(widget.petId));
    } catch (e) {
      if (mounted) showToast(context, '오류: $e');
    }
  }

  Future<void> _handleComplete(int routineId) async {
    try {
      // completeBatch: 이 루틴에 연결된 모든 개체를 오늘 완료로 기록
      await ref.read(routineRepositoryProvider).completeBatch(
        routineId,
        RoutineCompleteBatchRequest(executedAt: DateTime.now()),
      );
      if (mounted) {
        showToast(context, '완료로 기록했습니다.', type: ToastType.success);
        ref.invalidate(routinesForPetProvider(widget.petId));
        ref.invalidate(routineLogsProvider(routineId));
        setState(() => _expandedId = null);
      }
    } catch (e) {
      if (mounted) showToast(context, '오류: $e', type: ToastType.error);
    }
  }

  Future<void> _handleSkip(int routineId) async {
    try {
      // completeIndividual: 이 개체만 REFUSED(건너뛰기) 처리
      await ref.read(routineRepositoryProvider).completeIndividual(
        routineId,
        RoutineCompleteIndividualRequest(
          petId: widget.petId,
          status: RoutineLogStatus.REFUSED,
          executedAt: DateTime.now(),
        ),
      );
      if (mounted) {
        showToast(context, '건너뛰었습니다.', type: ToastType.info);
        ref.invalidate(routinesForPetProvider(widget.petId));
        ref.invalidate(routineLogsProvider(routineId));
        setState(() => _expandedId = null);
      }
    } catch (e) {
      if (mounted) showToast(context, '오류: $e', type: ToastType.error);
    }
  }
}

// ── 컴팩트 카드 (접힌 상태) ────────────────────────────────────
class _RoutineCardCompact extends StatelessWidget {
  final RoutineWithSubscription item;
  final PetPaletteKey paletteKey;
  final VoidCallback onExpand;

  const _RoutineCardCompact({
    required this.item,
    required this.paletteKey,
    required this.onExpand,
  });

  IconData get _icon => switch (item.routine.routineType) {
        RoutineType.FEEDING  => Icons.restaurant_outlined,
        RoutineType.CLEANING => Icons.cleaning_services_outlined,
        RoutineType.WEIGHT   => Icons.monitor_weight_outlined,
        RoutineType.CUSTOM   => Icons.task_alt_outlined,
      };

  String get _cycleLabel {
    final d = item.routine.cycleDays;
    if (d == 1) return '매일';
    if (d % 7 == 0) return '${d ~/ 7}주 1회';
    return '$d일에 1회';
  }

  @override
  Widget build(BuildContext context) {
    final pale    = PalePalette.pale(paletteKey);
    final r       = item.routine;
    final hasAlarm = r.isAlarmEnabled && r.alarmTime != null;

    return GestureDetector(
      onTap: onExpand,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.paleLine),
          borderRadius: BorderRadius.circular(14),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                  color: pale, borderRadius: BorderRadius.circular(10)),
              child: Icon(_icon, size: 18, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(r.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      const SizedBox(width: 8),
                      Text(_cycleLabel,
                          style: AppTextStyles.mono(10, FontWeight.w600,
                              color: AppColors.paleInk3)),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasAlarm
                        ? '→ ${r.nextDueAt != null ? _fmtNext(r.nextDueAt!) : r.alarmTime!}'
                        : '알람 꺼짐',
                    style: AppTextStyles.mono(
                        11, FontWeight.w700,
                        color: hasAlarm ? AppColors.primary : AppColors.paleInk3),
                  ),
                ],
              ),
            ),
            Text('+',
                style: AppTextStyles.mono(16, FontWeight.w700,
                    color: AppColors.paleInk3)),
          ],
        ),
      ),
    );
  }

  String _fmtNext(DateTime dt) {
    final diff = dt.difference(DateTime.now()).inDays;
    if (diff == 0) return '오늘 ${_hm(dt)}';
    if (diff == 1) return '내일 ${_hm(dt)}';
    return '${dt.month}.${dt.day}';
  }

  String _hm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

// ── 확장 카드 (펼친 상태) ─────────────────────────────────────
// ConsumerStatefulWidget: _shown 상태(더보기 페이지네이션) 보유
class _RoutineCardExpanded extends ConsumerStatefulWidget {
  final RoutineWithSubscription item;
  final PetPaletteKey paletteKey;
  final VoidCallback onCollapse;
  final ValueChanged<bool> onToggleAlarm;
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const _RoutineCardExpanded({
    super.key,
    required this.item,
    required this.paletteKey,
    required this.onCollapse,
    required this.onToggleAlarm,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  ConsumerState<_RoutineCardExpanded> createState() =>
      _RoutineCardExpandedState();
}

class _RoutineCardExpandedState extends ConsumerState<_RoutineCardExpanded> {
  static const _page = 3;
  int _shown = _page;

  IconData get _icon => switch (widget.item.routine.routineType) {
        RoutineType.FEEDING  => Icons.restaurant_outlined,
        RoutineType.CLEANING => Icons.cleaning_services_outlined,
        RoutineType.WEIGHT   => Icons.monitor_weight_outlined,
        RoutineType.CUSTOM   => Icons.task_alt_outlined,
      };

  String get _cycleLabel {
    final d = widget.item.routine.cycleDays;
    if (d == 1) return '매일';
    if (d % 7 == 0) return '${d ~/ 7}주 1회';
    return '$d일에 1회';
  }

  @override
  Widget build(BuildContext context) {
    final pale    = PalePalette.pale(widget.paletteKey);
    final paleInk = PalePalette.ink(widget.paletteKey);
    final r       = widget.item.routine;

    // 실제 로그 (routineLogsProvider)
    final logsAsync = ref.watch(routineLogsProvider(r.id));
    final allLogs   = logsAsync.whenOrNull(data: (logs) {
      return [...logs]..sort((a, b) => b.executedAt.compareTo(a.executedAt));
    }) ?? <RoutineLog>[];

    final visible   = allLogs.take(_shown).toList();
    final moreCount = allLogs.length - _shown;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── (A) 헤더 밴드 ────────────────────────────────
            _Header(
              r: r,
              pale: pale,
              icon: _icon,
              cycleLabel: _cycleLabel,
              paletteKey: widget.paletteKey,
              onCollapse: widget.onCollapse,
              onToggleAlarm: widget.onToggleAlarm,
            ),

            // ── (B) 최근 기록 리스트 + 더보기 ────────────────
            _RecentLogs(
              allLogs: allLogs,
              visible: visible,
              moreCount: moreCount,
              paleInk: paleInk,
              paletteKey: widget.paletteKey,
              isLoading: logsAsync is AsyncLoading,
              onMore: () => setState(() =>
                  _shown = (_shown + _page).clamp(0, allLogs.length)),
              onCollapse: () => setState(() => _shown = _page),
            ),

            // ── (C) 퀵 액션 2단 레이아웃 ────────────────────
            _QuickActions(
              onComplete: widget.onComplete,
              onSkip: widget.onSkip,
              onEdit: () {
                // 루틴 편집 화면(02d) — 범위 밖, 추후 구현
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── (A) 헤더 밴드 ──────────────────────────────────────────────
class _Header extends StatelessWidget {
  final Routine r;
  final Color pale;
  final IconData icon;
  final String cycleLabel;
  final PetPaletteKey paletteKey;
  final VoidCallback onCollapse;
  final ValueChanged<bool> onToggleAlarm;

  const _Header({
    required this.r,
    required this.pale,
    required this.icon,
    required this.cycleLabel,
    required this.paletteKey,
    required this.onCollapse,
    required this.onToggleAlarm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: pale,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        children: [
          // 아이콘 + 제목 + 접기
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 22, color: AppColors.primary),
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
                                  fontSize: 16, fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                  letterSpacing: -0.3),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(cycleLabel,
                              style: AppTextStyles.mono(10, FontWeight.w700,
                                  color: AppColors.paleInk2)),
                        ),
                      ],
                    ),
                    if (r.memo != null && r.memo!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(r.memo!,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500,
                                color: AppColors.primary)),
                      ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onCollapse,
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: const Text('−',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700,
                          color: AppColors.primary)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 알람 행
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_none_outlined,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('다음 알람',
                    style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                const SizedBox(width: 8),
                Text(
                  r.nextDueAt != null
                      ? _fmtAlarm(r.nextDueAt!)
                      : r.alarmTime ?? '-',
                  style: AppTextStyles.mono(12, FontWeight.w700),
                ),
                const Spacer(),
                _Toggle(on: r.isAlarmEnabled, onChange: onToggleAlarm),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtAlarm(DateTime dt) {
    final diff = dt.difference(DateTime.now()).inDays;
    final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return '오늘 $hm';
    if (diff == 1) return '내일 $hm';
    return '${dt.month}.${dt.day} $hm';
  }
}

// ── (B) 최근 기록 리스트 + 더보기 ─────────────────────────────
class _RecentLogs extends StatelessWidget {
  final List<RoutineLog> allLogs;
  final List<RoutineLog> visible;
  final int moreCount;
  final Color paleInk;
  final PetPaletteKey paletteKey;
  final bool isLoading;
  final VoidCallback onMore;
  final VoidCallback onCollapse;

  const _RecentLogs({
    required this.allLogs,
    required this.visible,
    required this.moreCount,
    required this.paleInk,
    required this.paletteKey,
    required this.isLoading,
    required this.onMore,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('최근 기록',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: AppColors.paleInk2, letterSpacing: 0.3)),
              Text(
                '총 ${allLogs.length}회',
                style: AppTextStyles.mono(11, FontWeight.w700,
                    color: AppColors.paleInk3),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 로딩
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                  child: SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))),
            )
          // 빈 상태
          else if (allLogs.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.paleLine, width: 1.5,
                    style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '아직 수행 기록이 없어요',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w600,
                    color: AppColors.paleInk3),
              ),
            )
          // 기록 리스트
          else
            Column(
              children: [
                ...visible.asMap().entries.map((e) {
                  final i   = e.key;
                  final log = e.value;
                  final ok  = log.status == RoutineLogStatus.COMPLETED;
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      border: i < visible.length - 1
                          ? const Border(bottom: BorderSide(
                              color: AppColors.paleLineSoft))
                          : null,
                    ),
                    child: Row(
                      children: [
                        // 16×16 상태 배지
                        Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                            color: ok ? paleInk : AppColors.paleLine,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            ok ? Icons.check : Icons.close,
                            size: 10,
                            color: ok ? AppColors.card : AppColors.paleInk2,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // note (1줄 말줄임)
                        Expanded(
                          child: Text(
                            log.memo ?? (ok ? '완료' : '건너뜀'),
                            style: const TextStyle(
                                fontSize: 12.5, fontWeight: FontWeight.w600,
                                color: AppColors.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // 날짜/시각 2줄 우측 정렬
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _fmtDate(log.executedAt),
                              style: AppTextStyles.mono(10, FontWeight.w600,
                                  color: AppColors.paleInk3),
                            ),
                            Text(
                              _fmtTime(log.executedAt),
                              style: AppTextStyles.mono(10, FontWeight.w600,
                                  color: AppColors.paleInk2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),

                // 더보기 버튼
                if (moreCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: onMore,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.paleLine),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('이전 기록 더보기',
                                style: TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700,
                                    color: AppColors.paleInk2)),
                            const SizedBox(width: 6),
                            Text('+$moreCount',
                                style: AppTextStyles.mono(10, FontWeight.w700,
                                    color: AppColors.paleInk3)),
                          ],
                        ),
                      ),
                    ),
                  ),

                // 접기 버튼 (전부 펼쳐진 상태 + 3건 초과)
                if (moreCount <= 0 && allLogs.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: onCollapse,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.paleLine),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('접기',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700,
                                color: AppColors.paleInk3)),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) =>
      '${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')} '
      '${_weekKo[dt.weekday % 7]}';

  String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  static const _weekKo = ['일', '월', '화', '수', '목', '금', '토'];
}

// ── (C) 퀵 액션 2단 레이아웃 ─────────────────────────────────
class _QuickActions extends StatelessWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final VoidCallback onEdit;

  const _QuickActions({
    required this.onComplete,
    required this.onSkip,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        children: [
          // 1행: 풀폭 주요 버튼
          GestureDetector(
            onTap: onComplete,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check, color: AppColors.paleBg, size: 16),
                  const SizedBox(width: 7),
                  Text('오늘 완료로 기록',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700,
                          color: AppColors.paleBg)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 7),
          // 2행: 2등분 보조 버튼
          Row(
            children: [
              Expanded(
                child: _SecondaryBtn(label: '오늘은 건너뛰기', onTap: onSkip),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _SecondaryBtn(label: '루틴 편집', onTap: onEdit),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SecondaryBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SecondaryBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: AppColors.paleLine),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w600,
                color: AppColors.primary)),
      ),
    );
  }
}

// ── Toggle (38×22, on=#3A332B / off=paleLine) ─────────────────
class _Toggle extends StatelessWidget {
  final bool on;
  final ValueChanged<bool> onChange;

  const _Toggle({required this.on, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChange(!on),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38, height: 22,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: on ? AppColors.primary : AppColors.paleLine,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: on ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18, height: 18,
          decoration: const BoxDecoration(
              color: AppColors.card, shape: BoxShape.circle),
        ),
      ),
    );
  }
}
