// 루틴 미루기 바텀시트
// ⚠️ 미루기는 '루틴 단위' 동작이다 — 연결된 모든 개체의 다음 예정일이 함께 밀린다.
//    그래서 실행 전에 개체 수·이름을 먼저 고지한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';

/// 미루기 시트를 띄운다. 미뤘으면 true 를 돌려준다.
Future<bool> showRoutinePostponeSheet(
    BuildContext context, TodayRoutine routine) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => RoutinePostponeSheet(routine: routine),
  );
  return result ?? false;
}

class RoutinePostponeSheet extends ConsumerStatefulWidget {
  final TodayRoutine routine;
  const RoutinePostponeSheet({super.key, required this.routine});

  @override
  ConsumerState<RoutinePostponeSheet> createState() =>
      _RoutinePostponeSheetState();
}

class _RoutinePostponeSheetState extends ConsumerState<RoutinePostponeSheet> {
  late DateTime _selected;
  bool _saving = false;

  static const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  DateTime get _today {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// 현재 예정일 (보통 오늘). 서버가 안 주면 오늘로 본다.
  DateTime get _due {
    final d = widget.routine.nextDueAt;
    if (d == null) return _today;
    final only = DateTime(d.year, d.month, d.day);
    return only.isBefore(_today) ? _today : only;
  }

  int get _cycle =>
      widget.routine.cycleDays > 0 ? widget.routine.cycleDays : 1;

  /// 프리셋 — 사용자가 고르는 건 결국 '다음 알림 날짜' 하나다.
  List<_Preset> get _presets {
    final tomorrow = _today.add(const Duration(days: 1));
    final keepRhythm = _due.add(Duration(days: _cycle));   // 이번만 건너뛰기
    final rebase = _today.add(Duration(days: _cycle));     // 오늘 기준 재조정
    final list = <_Preset>[
      _Preset(tomorrow, '내일로 미루기', '하루만 미뤄요'),
    ];
    if (keepRhythm.isAfter(_today) && keepRhythm != tomorrow) {
      list.add(_Preset(keepRhythm, '이번만 건너뛰기', '원래 주기(${_cycle}일)는 그대로'));
    }
    if (rebase != keepRhythm && rebase != tomorrow) {
      list.add(_Preset(rebase, '오늘 기준으로 다시', '오늘부터 ${_cycle}일 후'));
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _selected = _presets.first.date;
  }

  String _label(DateTime d) =>
      '${d.month}/${d.day} (${_weekdays[d.weekday - 1]})';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: _today.add(const Duration(days: 1)),
      lastDate: _today.add(const Duration(days: 365)),
      helpText: '다음 알림 날짜',
    );
    if (picked != null) {
      setState(() => _selected = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(routineRepositoryProvider)
          .postponeRoutine(widget.routine.id, _selected);
      // 미룬 루틴은 오늘 목록에서 빠진다
      ref.read(todayRoutinesProvider.notifier).removeRoutine(widget.routine.id);
      ref.invalidate(routineTodayStatusProvider(widget.routine.id));
      ref.read(routineListProvider.notifier).load();
      if (mounted) Navigator.of(context).pop(true);
      if (mounted) showToast(context, '${_label(_selected)}로 미뤘어요');
    } catch (e) {
      if (mounted) showToast(context, '미루기 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pets = widget.routine.petStatuses;
    final petNames = pets.map((p) => p.petName).where((n) => n.isNotEmpty).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, MediaQuery.of(context).padding.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              width: 40,
              height: 4,
              color: AppColors.border,
            ),
          ),
          Text('루틴 미루기',
              style: AppTextStyles.label.copyWith(color: AppColors.textDisabled)),
          const SizedBox(height: 4),
          Text(widget.routine.title, style: AppTextStyles.title),
          const SizedBox(height: 12),

          // ── 고지: 루틴 단위라 연결된 개체 전부가 함께 밀린다 ───────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: AppColors.bg2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '이 루틴에 연결된 ${pets.length}마리 모두 미뤄져요',
                        style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
                if (petNames.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    petNames.length > 6
                        ? '${petNames.take(6).join(', ')} 외 ${petNames.length - 6}마리'
                        : petNames.join(', '),
                    style: AppTextStyles.caption,
                  ),
                ],
                const SizedBox(height: 6),
                Text('개체별로 따로 미룰 수는 없어요. 한 마리만 건너뛴다면 그 개체를 미완료로 기록해 주세요.',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textDisabled)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text('다음 알림을 언제로 할까요?', style: AppTextStyles.bodyBold),
          const SizedBox(height: 8),
          ..._presets.map((p) => _OptionTile(
                selected: _isSame(_selected, p.date),
                title: p.title,
                subtitle: '${p.hint} · 다음 알림 ${_label(p.date)}',
                onTap: () => setState(() => _selected = p.date),
              )),
          _OptionTile(
            selected: !_presets.any((p) => _isSame(_selected, p.date)),
            title: '날짜 직접 고르기',
            subtitle: !_presets.any((p) => _isSame(_selected, p.date))
                ? '다음 알림 ${_label(_selected)}'
                : '원하는 날짜로 미뤄요',
            onTap: _pickDate,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              SizedBox(
                width: 80,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: const Text('취소'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
                  child: _saving
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : Text('${_label(_selected)}로 미루기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static bool _isSame(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _Preset {
  final DateTime date;
  final String title;
  final String hint;
  const _Preset(this.date, this.title, this.hint);
}

class _OptionTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OptionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.bg2 : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: selected ? AppColors.primary : AppColors.textDisabled,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyBold),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
