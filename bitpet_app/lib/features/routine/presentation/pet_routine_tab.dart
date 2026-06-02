// SCR-08: 개체 상세 - 루틴 탭 (PALE 디자인 적용)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pale_palette.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart'; // SkeletonBox
import '../../../core/widgets/toast_message.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';

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
                  item: item,
                  paletteKey: widget.paletteKey,
                  onCollapse: () => setState(() => _expandedId = null),
                  onToggleAlarm: (val) => _handleToggle(r.id, val, item),
                );
              }
              return _RoutineCardCompact(
                item: item,
                paletteKey: widget.paletteKey,
                onExpand: () => setState(() => _expandedId = r.id),
              );
            }),
            const SizedBox(height: 4),
            // 새 루틴 추가 버튼
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 0),
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: 루틴 생성 화면으로 이동 (02d)
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('새 루틴 추가'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(
                      color: AppColors.paleLine, width: 1.5,
                      style: BorderStyle.solid),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  foregroundColor: AppColors.paleInk2,
                  textStyle: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleToggle(
      int routineId, bool val, RoutineWithSubscription item) async {
    // 알람 토글 — 추후 API 연동
    try {
      final repo = ref.read(routineRepositoryProvider);
      await repo.updateRoutine(routineId, {'alarmEnabled': val});
      ref.invalidate(routinesForPetProvider(widget.petId));
    } catch (e) {
      if (mounted) showToast(context, '오류: $e');
    }
  }
}

// ── 컴팩트 카드 ───────────────────────────────────────────
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
    final pale = PalePalette.pale(paletteKey);
    final r    = item.routine;
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
            // 아이콘 박스
            Container(
              width: 34, height: 34,
              decoration: BoxDecoration(
                color: pale,
                borderRadius: BorderRadius.circular(10),
              ),
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
                      Text(
                        _cycleLabel,
                        style: AppTextStyles.mono(10, FontWeight.w600,
                            color: AppColors.paleInk3),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasAlarm
                        ? '→ ${r.nextDueAt != null ? _fmtNext(r.nextDueAt!) : r.alarmTime!}'
                        : '알람 꺼짐',
                    style: AppTextStyles.mono(
                      11, FontWeight.w700,
                      color: hasAlarm ? AppColors.primary : AppColors.paleInk3,
                    ),
                  ),
                ],
              ),
            ),
            const Text('+',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700,
                    color: AppColors.paleInk3,
                    fontFamily: 'JetBrainsMono')),
          ],
        ),
      ),
    );
  }

  String _fmtNext(DateTime dt) {
    final now  = DateTime.now();
    final diff = dt.difference(now).inDays;
    if (diff == 0) return '오늘 ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    if (diff == 1) return '내일 ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    return '${dt.month}.${dt.day}';
  }
}

// ── 확장 카드 ──────────────────────────────────────────────
class _RoutineCardExpanded extends ConsumerWidget {
  final RoutineWithSubscription item;
  final PetPaletteKey paletteKey;
  final VoidCallback onCollapse;
  final ValueChanged<bool> onToggleAlarm;

  const _RoutineCardExpanded({
    required this.item,
    required this.paletteKey,
    required this.onCollapse,
    required this.onToggleAlarm,
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
  Widget build(BuildContext context, WidgetRef ref) {
    final pale    = PalePalette.pale(paletteKey);
    final paleInk = PalePalette.ink(paletteKey);
    final r = item.routine;

    // 최근 14일 타임라인 — routineLogsProvider로 실 데이터 연결
    final logsAsync = ref.watch(routineLogsProvider(r.id));
    final today     = DateTime.now();
    final cutoff    = today.subtract(const Duration(days: 14));

    // 로그에서 14일 타임라인 배열 생성 (인덱스 0=14일전 ... 13=오늘)
    final timeline = logsAsync.whenOrNull(data: (logs) {
      final arr = List.filled(14, 0);
      for (final log in logs) {
        if (log.status == RoutineLogStatus.COMPLETED &&
            log.executedAt.isAfter(cutoff)) {
          final idx = log.executedAt.difference(cutoff).inDays;
          if (idx >= 0 && idx < 14) arr[idx] = 1;
        }
      }
      return arr;
    }) ?? List.generate(14, (i) => i % 3 == 2 ? 1 : 0); // 로딩 중 임시 표시

    final doneCount = timeline.where((v) => v == 1).length;

    // 최근 기록 (최대 3건)
    final recentLogs = logsAsync.whenOrNull(data: (logs) {
      final sorted = [...logs]
        ..sort((a, b) => b.executedAt.compareTo(a.executedAt));
      return sorted.take(3).toList();
    }) ?? [];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.primary, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 밴드 (pale 배경) ──
          Container(
            decoration: BoxDecoration(
              color: pale,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14.5)),
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    // 아이콘 박스
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_icon, size: 22, color: AppColors.primary),
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
                                      fontSize: 16, fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                      letterSpacing: -0.3)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(_cycleLabel,
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
                                      fontSize: 12, color: AppColors.primary)),
                            ),
                        ],
                      ),
                    ),
                    // 접기 버튼
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
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
                            ? _fmtDate(r.nextDueAt!)
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
          ),

          // ── 14일 타임라인 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('최근 14일',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.paleInk2, letterSpacing: 0.3)),
                    Text(
                      '$doneCount/${timeline.length}회 수행',
                      style: AppTextStyles.mono(11, FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: timeline.map((v) => Expanded(
                    child: Container(
                      height: 16,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: v == 1 ? paleInk : AppColors.paleLineSoft,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('14일 전', style: AppTextStyles.monoXxs),
                    Text('오늘',   style: AppTextStyles.monoXxs),
                  ],
                ),
              ],
            ),
          ),

          // ── 최근 기록 (실제 로그) ──
          if (recentLogs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('최근 기록',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.paleInk2, letterSpacing: 0.3)),
                  const SizedBox(height: 6),
                  ...recentLogs.asMap().entries.map((e) {
                    final i   = e.key;
                    final log = e.value;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: i < recentLogs.length - 1
                            ? const Border(bottom: BorderSide(
                                color: AppColors.paleLineSoft))
                            : null,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 14, height: 14,
                            decoration: BoxDecoration(
                              color: PalePalette.ink(paletteKey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            alignment: Alignment.center,
                            child: const Text('✓',
                                style: TextStyle(
                                    fontSize: 9, fontWeight: FontWeight.w700,
                                    color: AppColors.card)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              log.memo ?? '완료',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.primary),
                            ),
                          ),
                          Text(
                            _fmtExact(log.executedAt),
                            style: AppTextStyles.monoXs,
                            textAlign: TextAlign.right,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

          // ── 퀵 액션 3분할 ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: _QuickBtn(
                    label: '지금 완료',
                    primary: true,
                    onTap: () {
                      // TODO: completeBatch API
                    },
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _QuickBtn(
                    label: '건너뛰기',
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _QuickBtn(
                    label: '편집',
                    onTap: () {
                      // TODO: 루틴 편집 화면
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime dt) {
    final diff = dt.difference(DateTime.now()).inDays;
    if (diff == 0) return '오늘 ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    if (diff == 1) return '내일 ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
    return '${dt.month}.${dt.day}';
  }

  String _fmtExact(DateTime dt) =>
      '${dt.month.toString().padLeft(2,'0')}.${dt.day.toString().padLeft(2,'0')}\n${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
}

// Toggle 스위치
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
            color: AppColors.card,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final bool primary;
  final VoidCallback onTap;

  const _QuickBtn({required this.label, this.primary = false, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? AppColors.primary : AppColors.card,
          border: primary
              ? null
              : Border.all(color: AppColors.paleLine),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: primary ? FontWeight.w700 : FontWeight.w600,
            color: primary ? AppColors.paleBg : AppColors.primary,
          ),
        ),
      ),
    );
  }
}
