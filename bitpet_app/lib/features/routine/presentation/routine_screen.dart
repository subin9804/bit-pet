// SCR-08A: 내 개체 관리 - 루틴 세그먼트 (v3.1 재설계)
// 유저 소유 루틴 관리. 루틴은 pet_id 단위가 아닌 user 단위.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../providers/routine_provider.dart';
import '../data/models/routine_models.dart';
import 'routine_complete_modal.dart';

class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('루틴 관리')),
      body: _RoutineList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateRoutineSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateRoutineSheet(BuildContext context) {
    // TODO: 루틴 추가 바텀시트 — UI 디자인 확정 후 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('루틴 추가 (UI 디자인 확정 후 구현 예정)')),
    );
  }
}

class _RoutineList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routineListProvider);

    return routinesAsync.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => EmptyState(message: e.toString()),
      data: (routines) {
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
          itemBuilder: (_, i) => _RoutineCard(routine: routines[i]),
        );
      },
    );
  }
}

class _RoutineCard extends StatefulWidget {
  final Routine routine;
  const _RoutineCard({required this.routine});

  @override
  State<_RoutineCard> createState() => _RoutineCardState();
}

class _RoutineCardState extends State<_RoutineCard> {
  bool _expanded = false;

  IconData get _typeIcon => switch (widget.routine.routineType) {
        RoutineType.FEEDING  => Icons.restaurant_outlined,
        RoutineType.CLEANING => Icons.cleaning_services_outlined,
        RoutineType.WEIGHT   => Icons.monitor_weight_outlined,
        RoutineType.CUSTOM   => Icons.task_alt_outlined,
      };

  Color get _typeColor => switch (widget.routine.routineType) {
        RoutineType.FEEDING  => AppColors.secondary,
        RoutineType.CLEANING => AppColors.info,
        RoutineType.WEIGHT   => AppColors.primary,
        RoutineType.CUSTOM   => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final dDay = widget.routine.dDayFromNow;
    final dDayLabel = dDay == null
        ? ''
        : dDay < 0
            ? 'D+${-dDay}'
            : dDay == 0
                ? 'D-Day'
                : 'D-$dDay';
    final dDayColor = dDay != null && dDay <= 0 ? AppColors.error : AppColors.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // 접힌 상태 (기본)
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(_typeIcon, color: _typeColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.routine.title, style: AppTextStyles.bodyBold),
                        Text(
                          '${widget.routine.cycleDays}일 주기 · ${widget.routine.petCount}마리',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  ),
                  if (dDay != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: dDayColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(dDayLabel,
                          style: AppTextStyles.label.copyWith(color: dDayColor)),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          // 펼친 상태 (드롭다운)
          if (_expanded) _ExpandedSection(routine: widget.routine),
        ],
      ),
    );
  }
}

class _ExpandedSection extends StatelessWidget {
  final Routine routine;
  const _ExpandedSection({required this.routine});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 루틴 설정 정보
              Text('주기: ${routine.cycleDays}일', style: AppTextStyles.caption),
              if (routine.alarmTime != null)
                Text('알람: ${routine.alarmTime} (${routine.isAlarmEnabled ? "켜짐" : "꺼짐"})',
                    style: AppTextStyles.caption),
              const SizedBox(height: 12),
              // 완료 처리 버튼
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _openCompleteModal(context),
                  child: const Text('완료 처리'),
                ),
              ),
              // TODO: 개체별 체크박스, 주단위 스트릭 뷰 — UI 디자인 확정 후 구현
              const SizedBox(height: 8),
              Text('개체별 체크 · 스트릭 뷰는 UI 디자인 확정 후 구현 예정',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }

  void _openCompleteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => RoutineCompleteModal(routine: routine),
    );
  }
}
