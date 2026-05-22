// Screen 02c: TODAY'S CHECK 바텀시트
// 루틴에 연결된 개체 목록 + 개별 완료 처리
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/toast_message.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';
import '../../record/presentation/feeding_record_sheet.dart';

class RoutineTodayCheckSheet extends ConsumerStatefulWidget {
  final TodayRoutine routine;

  const RoutineTodayCheckSheet({super.key, required this.routine});

  @override
  ConsumerState<RoutineTodayCheckSheet> createState() =>
      _RoutineTodayCheckSheetState();
}

class _RoutineTodayCheckSheetState
    extends ConsumerState<RoutineTodayCheckSheet> {
  late List<TodayPetStatus> _statuses;
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _statuses = List.from(widget.routine.petStatuses);
  }

  int get _completedCount => _statuses.where((s) => s.isCompleted).length;

  List<TodayPetStatus> get _filtered {
    if (_query.isEmpty) return _statuses;
    return _statuses
        .where((s) =>
            s.petName.toLowerCase().contains(_query.toLowerCase()) ||
            s.speciesName.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  void _toggleAll(bool complete) {
    setState(() {
      _statuses = _statuses
          .map((s) => TodayPetStatus(
                petId: s.petId,
                petName: s.petName,
                speciesName: s.speciesName,
                colorCode: s.colorCode,
                imageUrl: s.imageUrl,
                isCompleted: complete,
                logId: s.logId,
              ))
          .toList();
    });
  }

  void _togglePet(int petId) {
    if (widget.routine.routineType == RoutineType.FEEDING) {
      // FEEDING → 피딩 기록 바텀시트로 이동
      final pet = _statuses.firstWhere((s) => s.petId == petId);
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FeedingRecordSheet(
          routine: widget.routine,
          initialPetId: petId,
          fromHome: false,
        ),
      ).then((_) {
        // 바텀시트 닫힌 후 상태 새로고침
        setState(() {
          final idx = _statuses.indexWhere((s) => s.petId == petId);
          if (idx >= 0) {
            _statuses[idx] = TodayPetStatus(
              petId: pet.petId,
              petName: pet.petName,
              speciesName: pet.speciesName,
              colorCode: pet.colorCode,
              imageUrl: pet.imageUrl,
              isCompleted: true,
              logId: pet.logId,
            );
          }
        });
      });
      return;
    }
    // 피딩 외: 직접 토글
    setState(() {
      final idx = _statuses.indexWhere((s) => s.petId == petId);
      if (idx >= 0) {
        final s = _statuses[idx];
        _statuses[idx] = TodayPetStatus(
          petId: s.petId,
          petName: s.petName,
          speciesName: s.speciesName,
          colorCode: s.colorCode,
          imageUrl: s.imageUrl,
          isCompleted: !s.isCompleted,
          logId: s.logId,
        );
      }
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      // 완료된 개체들만 서버에 저장
      final repo = ref.read(routineRepositoryProvider);
      final toComplete =
          _statuses.where((s) => s.isCompleted && s.logId == null).toList();
      for (final s in toComplete) {
        await repo.completeIndividual(
          widget.routine.id,
          RoutineCompleteIndividualRequest(
            petId: s.petId,
            status: RoutineLogStatus.COMPLETED,
          ),
        );
      }
      // 로컬 상태 업데이트
      for (final s in _statuses) {
        ref
            .read(todayRoutinesProvider.notifier)
            .updatePetStatus(widget.routine.id, s.petId, s.isCompleted);
      }
      ref.invalidate(routineTodayStatusProvider(widget.routine.id));
      if (mounted) Navigator.of(context).pop();
      if (mounted) showToast(context, '저장됐어요');
    } catch (e) {
      if (mounted) showToast(context, '저장 실패: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  IconData get _typeIcon => switch (widget.routine.routineType) {
        RoutineType.FEEDING => Icons.restaurant_outlined,
        RoutineType.CLEANING => Icons.cleaning_services_outlined,
        RoutineType.WEIGHT => Icons.monitor_weight_outlined,
        RoutineType.CUSTOM => Icons.star_outline,
      };

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    final dateLabel =
        '${now.month}.${now.day} (${weekdays[now.weekday - 1]})';

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // 핸들
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "TODAY'S CHECK",
                    style: AppTextStyles.label
                        .copyWith(color: AppColors.textDisabled),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(_typeIcon, size: 20, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(widget.routine.title,
                          style: AppTextStyles.title),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.petColorPeach,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_completedCount / ${_statuses.length}',
                          style: AppTextStyles.caption.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$dateLabel · 완료 처리한 개체는 오늘 자 기록으로 저장돼요',
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: 8),
                  // 진행 바
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _statuses.isEmpty
                          ? 0
                          : _completedCount / _statuses.length,
                      backgroundColor: AppColors.bg2,
                      color: AppColors.primary,
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // 검색창
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: '이름 또는 종 검색...',
                  prefixIcon: Icon(Icons.search, size: 18),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 전체 카운트 + 전체완료/전체해제
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    '${_statuses.length}마리 · 완료 $_completedCount',
                    style: AppTextStyles.caption,
                  ),
                  const Spacer(),
                  _SmallBtn(
                    icon: Icons.check,
                    label: '전체완료',
                    onTap: () => _toggleAll(true),
                  ),
                  const SizedBox(width: 8),
                  _SmallBtn(
                    icon: Icons.close,
                    label: '전체해제',
                    onTap: () => _toggleAll(false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // 개체 그리드
            Expanded(
              child: GridView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: _filtered.length,
                itemBuilder: (_, i) {
                  final s = _filtered[i];
                  return _PetCheckCard(
                    status: s,
                    onTap: () => _togglePet(s.petId),
                  );
                },
              ),
            ),
            // 하단 버튼
            Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
                color: AppColors.surface,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: _saving
                          ? const CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2)
                          : Text('저장  완료 $_completedCount'),
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

// ── 개체 체크 카드 ────────────────────────────────────────────────────────────

class _PetCheckCard extends StatelessWidget {
  final TodayPetStatus status;
  final VoidCallback onTap;

  const _PetCheckCard({required this.status, required this.onTap});

  Color get _bg {
    if (status.colorCode == null) return AppColors.petColorMint;
    try {
      return Color(int.parse(status.colorCode!.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.petColorMint;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: status.isCompleted
              ? _bg.withOpacity(0.5)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status.isCompleted
                ? AppColors.secondary.withOpacity(0.5)
                : AppColors.border,
            width: status.isCompleted ? 1.5 : 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: status.imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(status.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Icon(Icons.pets,
                                        size: 24,
                                        color: AppColors.primary
                                            .withOpacity(0.4))),
                          )
                        : Icon(Icons.pets,
                            size: 24,
                            color: AppColors.primary.withOpacity(0.4)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    status.petName,
                    style: AppTextStyles.bodyBold
                        .copyWith(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    status.speciesName,
                    style: AppTextStyles.caption.copyWith(fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.isCompleted ? '완료' : '미완료',
                    style: AppTextStyles.caption.copyWith(
                      color: status.isCompleted
                          ? AppColors.primary
                          : AppColors.textDisabled,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            if (status.isCompleted)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check,
                      size: 11, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── 작은 버튼 ─────────────────────────────────────────────────────────────────

class _SmallBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SmallBtn({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.textSecondary),
            const SizedBox(width: 3),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
