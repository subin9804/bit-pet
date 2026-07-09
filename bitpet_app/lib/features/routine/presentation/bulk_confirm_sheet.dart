// 01c · 루틴 일괄 완료 확인 — 센터 모달 다이얼로그
// TODAY 루틴 카드의 "일괄 완료" → 배정된 모든 개체를 한 번에 완료 처리.
// showDialog(barrierColor: transparent) 로 띄우며 자체 딤을 그린다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/pale_palette.dart';
import '../../../core/widgets/toast_message.dart';
import '../../record/presentation/widgets/feed_items_editor.dart';
import '../data/models/routine_models.dart';
import '../data/routine_repository.dart';
import '../providers/routine_provider.dart';
import 'widgets/confirm_accordion.dart';
import '../../record/providers/record_provider.dart';

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

  bool get _isFeed => widget.routine.routineType == RoutineType.FEEDING;

  Color get _accent => switch (widget.routine.routineType) {
        RoutineType.FEEDING  => AppColors.petPeach,
        RoutineType.CLEANING => AppColors.petSky,
        RoutineType.WEIGHT   => AppColors.petSage,
        RoutineType.CUSTOM   => AppColors.petLilac,
      };

  IconData get _icon => switch (widget.routine.routineType) {
        RoutineType.FEEDING  => Icons.restaurant_outlined,
        RoutineType.CLEANING => Icons.cleaning_services_outlined,
        RoutineType.WEIGHT   => Icons.monitor_weight_outlined,
        RoutineType.CUSTOM   => Icons.star_outline,
      };

  Future<void> _confirm() async {
    final pending = widget.routine.petStatuses.where((s) => !s.isCompleted).toList();
    if (pending.isEmpty) { Navigator.of(context).pop(); return; }
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
            memo:      memo,
          ),
        );
        ref.read(todayRoutinesProvider.notifier).updatePetStatus(widget.routine.id, pet.petId, true);
      }
      ref.invalidate(routineTodayStatusProvider(widget.routine.id));
      final ym = DateTime.now();
      ref.invalidate(homeCalendarProvider(
          '${ym.year}-${ym.month.toString().padLeft(2, '0')}'));
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
    final screenH = MediaQuery.of(context).size.height;
    final cardH   = (screenH - 112).clamp(0.0, 524.0);

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 딤 백드롭 (탭 시 닫힘)
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(color: const Color(0x801C1610)),
          ),
          // 센터 다이얼로그
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: SizedBox(
                  height: cardH,
                  child: Container(
                  color: AppColors.bg,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 헤더 밴드
                      Container(
                        color: _accent,
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                        child: Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              color: Colors.white.withValues(alpha: 0.62),
                              child: Icon(_icon, size: 24,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'BULK COMPLETE · ${routine.alarmTime ?? '--:--'}',
                                    style: AppTextStyles.mono(10, FontWeight.w700,
                                        color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    routine.title,
                                    style: const TextStyle(
                                        fontSize: 19, fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                        letterSpacing: -0.5),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 본문 (스크롤)
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 질문
                              _QuestionText(title: routine.title, accent: _accent),
                              const SizedBox(height: 16),

                              // 대상 개체 아코디언
                              ConfirmAccordion(
                                label: '대상 개체',
                                summary: done > 0
                                    ? '대기 ${pending}마리'
                                    : '${pets.length}마리',
                                summaryActive: true,
                                open: _petsOpen,
                                onToggle: () =>
                                    setState(() => _petsOpen = !_petsOpen),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: pets
                                          .map((s) => _NameChip(status: s))
                                          .toList(),
                                    ),
                                    if (done > 0) ...[
                                      const SizedBox(height: 10),
                                      Text.rich(
                                        TextSpan(
                                          style: const TextStyle(
                                              fontSize: 11.5,
                                              color: AppColors.paleInk2,
                                              height: 1.5,
                                              fontWeight: FontWeight.w500),
                                          children: [
                                            const TextSpan(text: '이미 완료된 '),
                                            TextSpan(
                                                text: '$done마리',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary)),
                                            const TextSpan(text: '는 그대로 두고, 남은 '),
                                            TextSpan(
                                                text: '$pending마리',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    color: AppColors.primary)),
                                            const TextSpan(text: '만 완료로 바꿔요.'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // 급여 내용 아코디언 (feed 타입만)
                              if (_isFeed)
                                ConfirmAccordion(
                                  label: '급여 내용',
                                  optional: true,
                                  summary: null,
                                  summaryActive: false,
                                  open: _feedOpen,
                                  onToggle: () =>
                                      setState(() => _feedOpen = !_feedOpen),
                                  child: FeedItemsEditor(
                                    items: _feedItems,
                                    bandColor: _accent,
                                    onChanged: (items) =>
                                        setState(() => _feedItems = items),
                                  ),
                                ),

                              // 메모 아코디언
                              ConfirmAccordion(
                                label: '메모',
                                optional: true,
                                summary: null,
                                summaryActive: false,
                                open: _memoOpen,
                                onToggle: () =>
                                    setState(() => _memoOpen = !_memoOpen),
                                child: TextField(
                                  onChanged: (v) => _memo = v,
                                  maxLines: 2,
                                  style: const TextStyle(
                                      fontSize: 13, color: AppColors.primary),
                                  decoration: const InputDecoration(
                                    hintText: '예: 1마리 남김 · 식욕 좋음',
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 10),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(
                                            color: AppColors.border)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(
                                            color: AppColors.border)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 푸터
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.bg,
                          border: Border(top: BorderSide(color: AppColors.divider)),
                        ),
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 22, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.bg2,
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: const Text('취소',
                                    style: TextStyle(
                                        fontSize: 15, fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: GestureDetector(
                                onTap: _saving ? null : _confirm,
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  alignment: Alignment.center,
                                  color: AppColors.primary,
                                  child: _saving
                                      ? const SizedBox(
                                          width: 20, height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check,
                                                size: 16,
                                                color: Colors.white),
                                            SizedBox(width: 8),
                                            Text('확인',
                                                style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white)),
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
                ),
              ),
            ),
          ),
        ]
      ),
    );
  }
}

// ── 질문 텍스트 ───────────────────────────────────────────────
class _QuestionText extends StatelessWidget {
  final String title;
  final Color accent;
  const _QuestionText({required this.title, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700,
            color: AppColors.primary, letterSpacing: -0.4, height: 1.45),
        children: [
          const TextSpan(text: '루틴에 포함된 모든 개체의\n'),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              color: accent,
              child: Text("'$title'",
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
          ),
          const TextSpan(text: '를 완료 처리할까요?'),
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
    final pale = PalePalette.pale(PalePalette.keyFromHex(status.colorCode));
    return Opacity(
      opacity: done ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 4, 10, 4),
        decoration: BoxDecoration(
          color: done ? AppColors.bg2 : pale,
          border: Border.all(
              color: done ? AppColors.border : Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22, height: 22,
              color: Colors.white.withValues(alpha: 0.6),
              child: Icon(Icons.pets, size: 12, color: AppColors.textPrimary),
            ),
            const SizedBox(width: 6),
            Text(
              status.petName,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                decoration: done
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
                decorationColor: AppColors.textDisabled,
              ),
            ),
            if (done) ...[
              const SizedBox(width: 4),
              const Icon(Icons.check, size: 13, color: AppColors.textDisabled),
            ],
          ],
        ),
      ),
    );
  }
}
