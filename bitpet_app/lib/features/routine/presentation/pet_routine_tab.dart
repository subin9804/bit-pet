// SCR-08: 개체 상세 - 루틴 탭 (v3.1 재설계)
// 해당 개체에 연결된 루틴 목록 + 구독/해제 UX
// 스트릭 뷰는 UI 디자인 확정 후 구현 예정
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

class PetRoutineTab extends ConsumerWidget {
  final int petId;
  const PetRoutineTab({super.key, required this.petId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routinesForPetProvider(petId));

    return routinesAsync.when(
      loading: () => const SkeletonCardList(),
      error: (e, _) => EmptyState(message: e.toString()),
      data: (routines) {
        if (routines.isEmpty) {
          return const EmptyState(
            message: '연결된 루틴이 없어요',
            subMessage: '루틴 관리에서 루틴을 만들고 개체를 연결하세요',
            icon: Icons.schedule,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: routines.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) => _PetRoutineCard(
            petId: petId,
            item: routines[i],
          ),
        );
      },
    );
  }
}

class _PetRoutineCard extends ConsumerStatefulWidget {
  final int petId;
  final RoutineWithSubscription item;

  const _PetRoutineCard({required this.petId, required this.item});

  @override
  ConsumerState<_PetRoutineCard> createState() => _PetRoutineCardState();
}

class _PetRoutineCardState extends ConsumerState<_PetRoutineCard> {
  bool _loading = false;

  IconData get _typeIcon => switch (widget.item.routine.routineType) {
        RoutineType.FEEDING => Icons.restaurant_outlined,
        RoutineType.CLEANING => Icons.cleaning_services_outlined,
        RoutineType.WEIGHT => Icons.monitor_weight_outlined,
        RoutineType.CUSTOM => Icons.task_alt_outlined,
      };

  Color get _typeColor => switch (widget.item.routine.routineType) {
        RoutineType.FEEDING => AppColors.secondary,
        RoutineType.CLEANING => AppColors.info,
        RoutineType.WEIGHT => AppColors.primary,
        RoutineType.CUSTOM => AppColors.textSecondary,
      };

  Future<void> _toggleSubscription() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final repo = ref.read(routineRepositoryProvider);
      if (widget.item.subscribed) {
        await repo.unsubscribePet(widget.item.routine.id, widget.petId);
      } else {
        await repo.subscribePet(widget.item.routine.id, widget.petId);
      }
      ref.invalidate(routinesForPetProvider(widget.petId));
    } catch (e) {
      if (mounted) showToast(context, '오류: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routine = widget.item.routine;
    final subscribed = widget.item.subscribed;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: subscribed ? AppColors.primary : AppColors.border,
          width: subscribed ? 1.5 : 1,
        ),
      ),
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
                  Text(routine.title, style: AppTextStyles.bodyBold),
                  Text(
                    '${routine.cycleDays}일 주기',
                    style: AppTextStyles.caption,
                  ),
                  // TODO: 주단위 스트릭 뷰 — UI 디자인 확정 후 구현
                  const SizedBox(height: 4),
                  Text(
                    '스트릭 뷰 (UI 디자인 확정 후 구현 예정)',
                    style: AppTextStyles.caption
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : GestureDetector(
                    onTap: _toggleSubscription,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: subscribed
                            ? AppColors.primary
                            : AppColors.card,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: subscribed
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        subscribed ? '연결됨' : '연결',
                        style: AppTextStyles.label.copyWith(
                          color: subscribed
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
