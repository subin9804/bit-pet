import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loader.dart';
import '../../pet/providers/pet_provider.dart';
import '../providers/routine_provider.dart';
import '../data/models/routine_models.dart';

class RoutineScreen extends ConsumerWidget {
  const RoutineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPetId = ref.watch(selectedPetIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('루틴 · 일정')),
      body: selectedPetId == null
          ? const EmptyState(
              message: '개체를 먼저 선택해주세요',
              icon: Icons.pets,
            )
          : _RoutineList(petId: selectedPetId),
    );
  }
}

class _RoutineList extends ConsumerWidget {
  final int petId;
  const _RoutineList({required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routineListProvider(petId));

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

class _RoutineCard extends StatelessWidget {
  final Routine routine;
  const _RoutineCard({required this.routine});

  IconData get _typeIcon => switch (routine.routineType) {
        'FEEDING' => Icons.restaurant_outlined,
        'CLEANING' => Icons.cleaning_services_outlined,
        'WEIGHT' => Icons.monitor_weight_outlined,
        _ => Icons.task_alt_outlined,
      };

  Color get _typeColor => switch (routine.routineType) {
        'FEEDING' => AppColors.secondary,
        'CLEANING' => AppColors.info,
        'WEIGHT' => AppColors.primary,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    final dDay = routine.dDayFromNow;
    final dDayLabel = dDay == null
        ? ''
        : dDay < 0
            ? 'D+${-dDay}'
            : dDay == 0
                ? 'D-Day'
                : 'D-$dDay';
    final dDayColor = dDay != null && dDay <= 0 ? AppColors.error : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(_typeIcon, color: _typeColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(routine.title, style: AppTextStyles.bodyBold),
                Text('${routine.cycleDays}일 주기',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          if (dDay != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: dDayColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: dDayColor.withOpacity(0.4)),
              ),
              child: Text(dDayLabel,
                  style: AppTextStyles.label.copyWith(color: dDayColor)),
            ),
          if (routine.isAlarmEnabled)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.notifications_outlined,
                  size: 16, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
