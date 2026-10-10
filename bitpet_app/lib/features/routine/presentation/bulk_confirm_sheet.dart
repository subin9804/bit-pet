// 루틴 '모두 완료' 시트 — 배정된 개체를 한 번에 완료 처리.
// 홈 루틴 행의 '모두 완료' 알약에서 `showAppSheet` 로 열린다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_input_styles.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_sheet.dart';
import '../../../core/widgets/toast_message.dart';
import '../../record/presentation/widgets/feed_items_editor.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';
import 'widgets/confirm_accordion.dart';
import '../../record/providers/record_invalidation.dart';
import '../../../core/widgets/app_network_image.dart';

class BulkConfirmSheet extends ConsumerStatefulWidget {
  final TodayRoutine routine;
  const BulkConfirmSheet({super.key, required this.routine});

  @override
  ConsumerState<BulkConfirmSheet> createState() => _BulkConfirmSheetState();
}

class _BulkConfirmSheetState extends ConsumerState<BulkConfirmSheet> {
  List<FeedFormData> _feedItems = const [];
  String _memo = '';
  bool _petsOpen = false;
  bool _feedOpen = false;
  bool _memoOpen = false;
  bool _saving = false;

  // WEIGHT 루틴 — 개체별 체중 입력 (petId → controller)
  final Map<int, TextEditingController> _weightCtrls = {};

  bool get _isFeed => widget.routine.routineType == RoutineType.FEEDING;
  bool get _isWeight => widget.routine.routineType == RoutineType.WEIGHT;

  TextEditingController _weightCtrlFor(int petId) =>
      _weightCtrls.putIfAbsent(petId, () => TextEditingController());

  double? _weightGFor(int petId) =>
      double.tryParse(_weightCtrlFor(petId).text.trim());

  @override
  void dispose() {
    for (final c in _weightCtrls.values) c.dispose();
    super.dispose();
  }

  Color get _accent => switch (widget.routine.routineType) {
        RoutineType.FEEDING  => AppColors.petPeach,
        RoutineType.CLEANING => AppColors.petSky,
        RoutineType.WEIGHT   => AppColors.petSage,
        RoutineType.CUSTOM   => AppColors.petLilac,
      };

  Future<void> _confirm() async {
    final pending = widget.routine.petStatuses.where((s) => !s.isCompleted).toList();
    if (pending.isEmpty) { Navigator.of(context).pop(); return; }
    // 체중 루틴은 개체별 실측값 필수 (서버도 거부함)
    if (_isWeight) {
      final missing =
          pending.where((p) => _weightGFor(p.petId) == null).toList();
      if (missing.isNotEmpty) {
        showToast(context, '${missing.first.petName}의 몸무게를 입력해 주세요',
            type: ToastType.warning);
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(routineRepositoryProvider);
      final memo = _memo.trim().isEmpty ? null : _memo.trim();

      for (final pet in pending) {
        await repo.completeIndividual(
          widget.routine.id,
          RoutineCompleteIndividualRequest(
            petId:     pet.petId,
            status:    RoutineLogStatus.COMPLETED,
            feedItems: _isFeed ? _feedItems : const [],
            weightG:   _isWeight ? _weightGFor(pet.petId) : null,
            memo:      memo,
          ),
        );
        ref.read(todayRoutinesProvider.notifier).updatePetStatus(widget.routine.id, pet.petId, true);
        invalidatePetRecords(ref, pet.petId);
      }
      ref.invalidate(routineTodayStatusProvider(widget.routine.id));
      if (mounted) {
        Navigator.of(context).pop();
        showToast(context, '${pending.length}마리 완료 처리됐어요', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) showToast(context, '저장 실패: $e', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final routine = widget.routine;
    final pets    = routine.petStatuses;
    final done    = pets.where((s) => s.isCompleted).length;
    final pending = pets.length - done;

    // 각진 센터 다이얼로그였다 — 자체 딤, 타입색 밴드 헤더, 그리고 주 버튼 옆
    // '취소'. 앱의 다른 시트와 껍데기가 달라 이 모달만 테마 밖에 있었다.
    // 7슬롯 시트로 옮기면 모서리·핸들·스크림·키보드 회피가 전부 공통이 된다.
    //
    // ⛔ eyebrow 의 `BULK COMPLETE · 09:00` 은 지웠다. 루틴은 그 날 했냐 안 했냐가
    //    전부고, 알람 시각을 완료 화면에 띄우면 늦게 누른 것처럼 읽힌다.
    return AppSheet(
      title: '모두 완료',
      subtitle: pending > 0
          ? '${routine.title} · 남은 $pending마리를 한 번에'
          : routine.title,
      primaryLabel: pending > 0 ? '$pending마리 완료' : '이미 다 끝났어요',
      onPrimary: pending > 0 ? _confirm : null,
      busy: _saving,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 대상 개체
          ConfirmAccordion(
            label: '대상 개체',
            summary: done > 0 ? '대기 $pending마리' : '${pets.length}마리',
            summaryActive: true,
            open: _petsOpen,
            onToggle: () => setState(() => _petsOpen = !_petsOpen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: pets.map((s) => _NameChip(status: s)).toList(),
                ),
                if (done > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text.rich(
                    TextSpan(
                      style: AppTextStyles.caption,
                      children: [
                        const TextSpan(text: '이미 완료된 '),
                        TextSpan(
                            text: '$done마리',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                        const TextSpan(text: '는 그대로 두고, 남은 '),
                        TextSpan(
                            text: '$pending마리',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink)),
                        const TextSpan(text: '만 완료로 바꿔요.'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 몸무게 — WEIGHT 루틴은 개체별 실측값이 필수다 (서버도 거부한다)
          if (_isWeight) ...[
            const SizedBox(height: AppSpacing.lg),
            Text('몸무게 (g) *', style: AppTextStyles.label),
            const SizedBox(height: AppSpacing.sm),
            ...pets.where((s) => !s.isCompleted).map(
              (pet) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      child: Text(pet.petName,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.sub.copyWith(
                              fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextField(
                        controller: _weightCtrlFor(pet.petId),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (_) => setState(() {}),
                        style: AppTextStyles.sub,
                        decoration: AppInputStyles.textarea(hintText: '예: 52.5')
                            .copyWith(suffixText: 'g'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // 급여 내용 (FEEDING 만)
          if (_isFeed)
            ConfirmAccordion(
              label: '급여 내용',
              optional: true,
              summary: null,
              summaryActive: false,
              open: _feedOpen,
              onToggle: () => setState(() => _feedOpen = !_feedOpen),
              child: FeedItemsEditor(
                items: _feedItems,
                bandColor: _accent,
                onChanged: (items) => setState(() => _feedItems = items),
              ),
            ),

          // 메모
          ConfirmAccordion(
            label: '메모',
            optional: true,
            summary: null,
            summaryActive: false,
            open: _memoOpen,
            onToggle: () => setState(() => _memoOpen = !_memoOpen),
            child: TextField(
              onChanged: (v) => _memo = v,
              maxLines: 2,
              style: AppTextStyles.sub,
              decoration: AppInputStyles.textarea(
                hintText: '예: 1마리 남김 · 식욕 좋음',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameChip extends StatelessWidget {
  final TodayPetStatus status;
  const _NameChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final done = status.isCompleted;
    // 예전엔 '안 끝남'이 개체별 파스텔이었다. 개체색을 걷어내면 완료/미완료가
    // 같은 회색이 되므로, 남은 것에 브랜드색을 준다 — 여기서 색이 나르는 정보는
    // '누구냐'가 아니라 '아직 할 일이 남았냐'다.
    return Opacity(
      opacity: done ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
        decoration: BoxDecoration(
          color: done ? AppColors.bgAlt : AppColors.brandTint,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: done ? AppColors.line : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22, height: 22,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6)),
              child: status.imageUrl != null
                  ? AppNetworkImage(status.imageUrl,
                      fit: BoxFit.cover,
                      memWidth: 100,
                      placeholder: AppIcon(AppIcons.petLine,
                          size: AppIconSize.sm, color: AppColors.ink))
                  : AppIcon(AppIcons.petLine,
                      size: AppIconSize.sm, color: AppColors.ink),
            ),
            const SizedBox(width: 8),
            Text(
              status.petName,
              style: AppTextStyles.label.copyWith(
                color: AppColors.ink,
                decoration: done
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: AppColors.ink3,
              ),
            ),
            if (done) ...[
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.check,
                  size: AppIconSize.sm, color: AppColors.ink3),
            ],
          ],
        ),
      ),
    );
  }
}
