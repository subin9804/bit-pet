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
import 'routine_today_check_sheet.dart';

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
      await ref.read(routineRepositoryProvider).updateRoutine(
        r.id, {'alarmEnabled': next},
      );
      ref.read(routineListProvider.notifier).load();
    } catch (_) {
      setState(() => _alarmOverrides.remove(r.id));
    }
  }

  Future<void> _deleteRoutine(Routine r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('루틴 삭제'),
        content: Text('"${r.title}" 루틴을 삭제할까요?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
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
                  onTap: () => _openCheckSheet(context, ref),
                ),
                Container(width: 1, height: 40, color: AppColors.paleLineSoft),
                _CardAction(
                  icon: Icons.calendar_today_outlined,
                  label: '캘린더',
                  onTap: () => _openCalendarSheet(context, ref),
                ),
                Container(width: 1, height: 40, color: AppColors.paleLineSoft),
                _CardAction(
                  icon: Icons.edit_outlined,
                  label: '수정',
                  onTap: () => showToast(context, '루틴 수정은 준비 중이에요'),
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

  void _openCheckSheet(BuildContext context, WidgetRef ref) {
    final today = ref
        .read(routineTodayStatusProvider(routine.id))
        .valueOrNull;
    if (today == null) {
      showToast(context, '오늘 예정된 루틴이 아니에요');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RoutineTodayCheckSheet(routine: today),
    );
  }

  void _openCalendarSheet(BuildContext context, WidgetRef ref) {
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

class _CalendarSheet extends ConsumerWidget {
  final Routine routine;
  const _CalendarSheet({required this.routine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(routineLogsProvider(routine.id));

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.paleBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppColors.paleLine,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text('CALENDAR',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.paleInk2, letterSpacing: 0.4,
              )),
          const SizedBox(height: 4),
          Text('${routine.title} · 수행 캘린더',
              style: const TextStyle(
                fontSize: 19, fontWeight: FontWeight.w700,
                color: AppColors.primary, letterSpacing: -0.4,
              )),
          const SizedBox(height: 16),
          logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('$e'),
            data: (logs) => _buildCal(logs),
          ),
        ],
      ),
    );
  }

  Widget _buildCal(List<RoutineLog> logs) {
    final now = DateTime.now();
    final map = <int, bool>{};
    for (final l in logs) {
      if (l.executedAt.year == now.year && l.executedAt.month == now.month) {
        map[l.executedAt.day] = l.status == RoutineLogStatus.COMPLETED;
      }
    }
    final firstWd = DateTime(now.year, now.month, 1).weekday % 7;
    final days = DateTime(now.year, now.month + 1, 0).day;
    final cells = <int?>[
      ...List.filled(firstWd, null),
      ...List.generate(days, (i) => i + 1),
    ];
    const wk = ['일', '월', '화', '수', '목', '금', '토'];

    return Column(
      children: [
        Row(children: wk.map((w) => Expanded(
          child: Text(w, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppColors.paleInk3)),
        )).toList()),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4, crossAxisSpacing: 4,
          children: cells.map((d) {
            if (d == null) return const SizedBox.shrink();
            final has  = map.containsKey(d);
            final done = map[d] == true;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: has ? Border.all(color: AppColors.primary, width: 1.5) : null,
                color: done ? AppColors.primary : Colors.transparent,
              ),
              child: Center(
                child: Text('$d',
                    style: TextStyle(
                      fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.w700,
                      color: done ? AppColors.paleBg : AppColors.primary,
                    )),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _Leg(filled: true, label: '완료'),
          const SizedBox(width: 16),
          _Leg(filled: false, label: '미완료'),
        ]),
      ],
    );
  }
}

class _Leg extends StatelessWidget {
  final bool filled;
  final String label;
  const _Leg({required this.filled, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 12, height: 12,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(3),
          color: filled ? AppColors.primary : Colors.transparent,
          border: filled ? null : Border.all(color: AppColors.primary, width: 1.5),
        ),
      ),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(
          fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.paleInk2)),
    ]);
  }
}
